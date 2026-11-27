import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:university_messenger/features/calls/data/call_media_adapter.dart';
import 'package:university_messenger/features/calls/domain/call_models.dart';
import 'package:university_messenger/features/calls/presentation/call_controller.dart';
import 'package:university_messenger/features/calls/presentation/call_strings.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class CallErrorBanner extends StatelessWidget {
  const CallErrorBanner({
    required this.failure,
    required this.onDismiss,
    this.onRetry,
    super.key,
  });

  final CallFailure failure;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MaterialBanner(
      leading: const Icon(Icons.error_outline_rounded),
      content: Text(callErrorLabel(l10n, failure.code)),
      actions: [
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        TextButton(onPressed: onDismiss, child: Text(l10n.dismiss)),
      ],
    );
  }
}

class CallIdentity extends StatelessWidget {
  const CallIdentity({
    required this.name,
    required this.status,
    this.video = false,
    this.large = false,
    super.key,
  });

  final String? name;
  final String status;
  final bool video;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final displayName = name?.trim().isNotEmpty == true
        ? name!
        : l10n.callUnknownCaller;
    final avatarSize = large ? 124.0 : 88.0;
    return Semantics(
      label: l10n.callIdentity(displayName, status),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              video ? Icons.videocam_rounded : Icons.person_rounded,
              size: large ? 56 : 40,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class ActiveCallBody extends StatelessWidget {
  const ActiveCallBody({
    required this.controller,
    required this.peerName,
    required this.onClose,
    super.key,
  });

  final CallController controller;
  final String? peerName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = controller.state;
    final call = state.currentCall;
    if (call == null) {
      return _FinishedCall(title: l10n.callCallUnavailable, onClose: onClose);
    }
    if (call.status == CallStatus.declined || call.status == CallStatus.ended) {
      return _FinishedCall(
        title: call.status == CallStatus.declined
            ? l10n.callDeclined
            : l10n.callCallEnded,
        onClose: onClose,
      );
    }

    final media = controller.media;
    final video = call.kind == CallKind.video;
    final active = call.status == CallStatus.active;
    final status = active
        ? _connectionLabel(context, media.connection, state.elapsed)
        : l10n.callRinging;
    final name = peerName?.trim().isNotEmpty == true
        ? peerName!
        : l10n.callUnknownCaller;

    return ColoredBox(
      color: video
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          children: [
            _CallTopBar(title: name, status: status, onClose: onClose),
            if (state.failure != null)
              CallErrorBanner(
                failure: state.failure!,
                onDismiss: controller.clearFailure,
                onRetry: active ? controller.retryMediaConnection : null,
              ),
            Expanded(
              child: video
                  ? _VideoStage(controller: controller, peerName: name)
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: CallIdentity(
                          name: name,
                          status: active ? status : l10n.callWaitingForAnswer,
                          large: true,
                        ),
                      ),
                    ),
            ),
            _CallControls(controller: controller, video: video, active: active),
          ],
        ),
      ),
    );
  }
}

class _CallTopBar extends StatelessWidget {
  const _CallTopBar({
    required this.title,
    required this.status,
    required this.onClose,
  });

  final String title;
  final String status;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            tooltip: context.l10n.close,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoStage extends StatelessWidget {
  const _VideoStage({required this.controller, required this.peerName});

  final CallController controller;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    final media = controller.media;
    return LayoutBuilder(
      builder: (context, constraints) {
        final localWidth = constraints.maxWidth < 600 ? 112.0 : 176.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            media.buildVideoView(
              local: false,
              placeholder: Center(
                child: CallIdentity(
                  name: peerName,
                  status: context.l10n.callWaitingForVideo,
                  large: constraints.maxHeight > 480,
                  video: true,
                ),
              ),
            ),
            if (media.cameraEnabled)
              PositionedDirectional(
                top: 16,
                end: 16,
                width: localWidth,
                height: localWidth * 1.35,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: media.buildVideoView(
                      local: true,
                      placeholder: const Center(
                        child: Icon(Icons.videocam_off_rounded),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.controller,
    required this.video,
    required this.active,
  });

  final CallController controller;
  final bool video;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final media = controller.media;
    final l10n = context.l10n;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              CallControlButton(
                icon: media.microphoneEnabled
                    ? Icons.mic_rounded
                    : Icons.mic_off_rounded,
                label: media.microphoneEnabled
                    ? l10n.callMicrophoneOn
                    : l10n.callMicrophoneOff,
                selected: !media.microphoneEnabled,
                enabled: active,
                onPressed: () =>
                    controller.setMicrophoneEnabled(!media.microphoneEnabled),
              ),
              CallControlButton(
                icon: media.speakerEnabled
                    ? Icons.volume_up_rounded
                    : Icons.hearing_rounded,
                label: media.speakerEnabled
                    ? l10n.callSpeakerOn
                    : l10n.callSpeakerOff,
                selected: media.speakerEnabled,
                enabled: active,
                onPressed: () =>
                    controller.setSpeakerEnabled(!media.speakerEnabled),
              ),
              if (video)
                CallControlButton(
                  icon: media.cameraEnabled
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded,
                  label: media.cameraEnabled
                      ? l10n.callCameraOn
                      : l10n.callCameraOff,
                  selected: !media.cameraEnabled,
                  enabled: active,
                  onPressed: () =>
                      controller.setCameraEnabled(!media.cameraEnabled),
                ),
              if (video && media.cameraEnabled)
                CallControlButton(
                  icon: Icons.cameraswitch_rounded,
                  label: l10n.callSwitchCamera,
                  enabled: active,
                  onPressed: controller.switchCamera,
                ),
              CallControlButton(
                icon: Icons.call_end_rounded,
                label: l10n.callEndCall,
                destructive: true,
                enabled: !controller.state.isBusy,
                onPressed: controller.endCurrent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CallControlButton extends StatelessWidget {
  const CallControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.destructive = false,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = destructive
        ? scheme.error
        : selected
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = destructive
        ? scheme.onError
        : selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      toggled: selected,
      enabled: enabled,
      label: label,
      child: Tooltip(
        message: label,
        child: IconButton(
          onPressed: enabled ? onPressed : null,
          style: IconButton.styleFrom(
            minimumSize: const Size(56, 56),
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: scheme.surfaceContainer,
          ),
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _FinishedCall extends StatelessWidget {
  const _FinishedCall({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.call_end_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onClose,
                  child: Text(context.l10n.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _connectionLabel(
  BuildContext context,
  CallMediaConnection connection,
  Duration elapsed,
) => switch (connection) {
  CallMediaConnection.connecting ||
  CallMediaConnection.disconnected => context.l10n.callConnecting,
  CallMediaConnection.reconnecting => context.l10n.callReconnecting,
  CallMediaConnection.connected => formatCallDuration(context, elapsed),
  CallMediaConnection.failed => context.l10n.callMediaConnectionError,
};

String formatCallDuration(BuildContext context, Duration duration) {
  final locale = context.l10n.localeName;
  final padded = NumberFormat('00', locale);
  final whole = NumberFormat('0', locale);
  final hours = duration.inHours;
  final minutes = padded.format(duration.inMinutes.remainder(60));
  final seconds = padded.format(duration.inSeconds.remainder(60));
  return hours > 0
      ? '${whole.format(hours)}:$minutes:$seconds'
      : '${whole.format(duration.inMinutes)}:$seconds';
}
