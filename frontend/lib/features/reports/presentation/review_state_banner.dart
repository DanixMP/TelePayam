import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/reports/data/reports_api.dart';
import 'package:university_messenger/features/reports/domain/report_models.dart';
import 'package:university_messenger/features/reports/presentation/report_ui.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class ReviewStateBanner extends ConsumerStatefulWidget {
  const ReviewStateBanner({
    required this.conversationId,
    this.onStateChanged,
    super.key,
  });

  final String conversationId;
  final ValueChanged<ConversationReviewState>? onStateChanged;

  @override
  ConsumerState<ReviewStateBanner> createState() => _ReviewStateBannerState();
}

class _ReviewStateBannerState extends ConsumerState<ReviewStateBanner> {
  ConversationReviewState? _state;
  bool _loadFailed = false;
  bool _loading = true;
  int _requestVersion = 0;
  StreamSubscription? _events;

  @override
  void initState() {
    super.initState();
    _events = ref.read(realtimeClientProvider).events.listen((event) {
      if (event.type != 'report.review_started' &&
          event.type != 'report.review_resolved') {
        return;
      }
      final data = event.data;
      if (data is Map &&
          (data['conv']?.toString() == widget.conversationId ||
              data['conversation_id']?.toString() == widget.conversationId)) {
        unawaited(_load());
      }
    });
    _load();
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReviewStateBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) _load();
  }

  Future<void> _load() async {
    final requestVersion = ++_requestVersion;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final state = await ReportsApi(
        ref.read(apiClientProvider),
      ).getReviewState(widget.conversationId);
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _state = state;
        _loading = false;
      });
      widget.onStateChanged?.call(state);
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Review status is supplemental chat context. Network failure must not
    // displace the message list or imply that a conversation is under review.
    if (_loading || _loadFailed || _state?.underReview != true) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: scheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.policy_outlined, color: scheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reportUnderReview,
                      style: TextStyle(
                        color: scheme.onTertiaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ...[
                      const SizedBox(height: 3),
                      Text(
                        l10n.reportUnderReviewBody,
                        style: TextStyle(
                          color: scheme.onTertiaryContainer,
                          height: 1.4,
                        ),
                      ),
                      if (_state?.startedAt case final startedAt?) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${l10n.reportReviewStarted}: ${reportDateTime(context, startedAt)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onTertiaryContainer),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
