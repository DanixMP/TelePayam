import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/calls/domain/call_models.dart';
import 'package:university_messenger/features/calls/presentation/call_controller.dart';
import 'package:university_messenger/features/calls/presentation/call_providers.dart';
import 'package:university_messenger/features/calls/presentation/call_widgets.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({this.onBack, this.onCallSelected, super.key});

  final VoidCallback? onBack;
  final ValueChanged<CallSession>? onCallSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(callControllerProvider);
    final state = controller.state;
    final accountId = ref.read(authControllerProvider).state.account?.id;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack ?? () => Navigator.maybePop(context),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(context.l10n.callHistory),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (state.failure != null)
              CallErrorBanner(
                failure: state.failure!,
                onDismiss: controller.clearFailure,
                onRetry: controller.refreshHistory,
              ),
            if (state.operation == CallOperation.loadingHistory)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refreshHistory,
                child: state.history.isEmpty
                    ? const _EmptyCallHistory()
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: state.history.length,
                            separatorBuilder: (_, _) => const Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: 80,
                                end: 16,
                              ),
                              child: Divider(height: 1),
                            ),
                            itemBuilder: (context, index) => _CallHistoryTile(
                              call: state.history[index],
                              accountId: accountId,
                              onTap: onCallSelected == null
                                  ? null
                                  : () => onCallSelected!(state.history[index]),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCallHistory extends StatelessWidget {
  const _EmptyCallHistory();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
        Icon(
          Icons.call_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.callNoCalls,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.callNoCallsBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  const _CallHistoryTile({
    required this.call,
    required this.accountId,
    this.onTap,
  });

  final CallSession call;
  final String? accountId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final incoming = call.isIncomingFor(accountId);
    final missed =
        incoming &&
        (call.status == CallStatus.declined || call.startedAt == null);
    final scheme = Theme.of(context).colorScheme;
    final title = call.kind == CallKind.video
        ? context.l10n.callVideoCall
        : context.l10n.callAudioCall;
    final direction = incoming
        ? Icons.call_received_rounded
        : Icons.call_made_rounded;
    final detail = _historyDetail(context, call, missed);
    return ListTile(
      minTileHeight: 72,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 6, 12, 6),
      leading: CircleAvatar(
        backgroundColor: missed
            ? scheme.errorContainer
            : scheme.primaryContainer,
        foregroundColor: missed
            ? scheme.onErrorContainer
            : scheme.onPrimaryContainer,
        child: Icon(
          call.kind == CallKind.video
              ? Icons.videocam_rounded
              : Icons.call_rounded,
        ),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          Icon(
            direction,
            size: 16,
            color: missed ? scheme.error : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      trailing: call.kind == CallKind.video
          ? const Icon(Icons.videocam_outlined)
          : const Icon(Icons.call_outlined),
      onTap: onTap,
    );
  }
}

String _historyDetail(BuildContext context, CallSession call, bool missed) {
  final l10n = context.l10n;
  final date = MaterialLocalizations.of(
    context,
  ).formatShortDate(call.createdAt.toLocal());
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(call.createdAt.toLocal()),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  final status = missed
      ? l10n.callMissed
      : call.status == CallStatus.declined
      ? l10n.callDeclined
      : call.status == CallStatus.active
      ? l10n.callConnected
      : call.status == CallStatus.ringing
      ? l10n.callRinging
      : call.startedAt != null && call.endedAt != null
      ? formatCallDuration(context, call.endedAt!.difference(call.startedAt!))
      : l10n.callCallEnded;
  return '$status · ${l10n.dateAndTime(date, time)}';
}
