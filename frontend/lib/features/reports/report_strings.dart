abstract final class ReportStrings {
  static const submitTitle = 'Report';
  static const submitBody =
      'Tell the moderation team what happened. Relevant conversation context may be reviewed while the report is open.';
  static const target = 'Report target';
  static const targetMessage = 'Message';
  static const targetUser = 'Account';
  static const targetGroup = 'Group';
  static const targetChannel = 'Channel';
  static const targetUnknown = 'Unknown target';
  static const reason = 'Reason';
  static const chooseReason = 'Choose a reason';
  static const reasonHarassment = 'Harassment or abuse';
  static const reasonSpam = 'Spam or scam';
  static const reasonHate = 'Hate or discrimination';
  static const reasonImpersonation = 'Impersonation';
  static const reasonViolence = 'Violence or threat';
  static const reasonOther = 'Other';
  static const describeReason = 'Describe the reason';
  static const reasonRequired = 'Choose or enter a reason.';
  static const reasonTooShort = 'Enter at least 2 characters.';
  static const reasonTooLong = 'Keep the reason under 80 characters.';
  static const note = 'Additional note (optional)';
  static const noteHint =
      'Add details that can help a moderator understand the report.';
  static const noteTooLong = 'Keep the note under 1,000 characters.';
  static const privacyNotice =
      'Submitting creates a report and a protected evidence snapshot. A moderator only receives conversation access after claiming the report.';
  static const submitAction = 'Submit report';
  static const submitting = 'Submitting report';
  static const submitted = 'Report submitted';
  static const submittedBody = 'You can track its outcome in My reports.';
  static const cancel = 'Cancel';
  static const close = 'Close';

  static const myReportsTitle = 'My reports';
  static const noReportsTitle = 'No reports yet';
  static const noReportsBody =
      'Reports you submit and their outcomes will appear here.';
  static const refresh = 'Refresh';
  static const retry = 'Retry';
  static const loadingReports = 'Loading reports';
  static const statusOpen = 'Open';
  static const statusAssigned = 'Under review';
  static const statusResolved = 'Resolved';
  static const statusDismissed = 'Dismissed';
  static const statusUnknown = 'Unknown';
  static const submittedOn = 'Submitted';
  static const resolvedOn = 'Resolved';
  static const outcomeDismiss = 'Dismissed';
  static const outcomeWarn = 'Warning outcome recorded';
  static const outcomeMute = 'Mute outcome recorded';
  static const outcomeRemoveContent = 'Reported content removed';
  static const outcomeBan = 'Eligible account banned';
  static const outcomeEscalate = 'Escalation outcome recorded';
  static const outcomeUnknown = 'Outcome recorded';
  static const moderatorNote = 'Moderator note';
  static const awaitingOutcome = 'No outcome has been recorded yet.';

  static const checkingReview = 'Checking review status';
  static const reviewUnavailable = 'Review status is unavailable.';
  static const underReview = 'This conversation is under moderator review.';
  static const underReviewBody =
      'A moderator has temporary, report-scoped access to relevant messages until the report is resolved.';
  static const reviewStarted = 'Review started';

  static const moderationTitle = 'Moderation reports';
  static const moderationAccessTitle = 'Moderator access required';
  static const moderationAccessBody =
      'This area is only available to moderator accounts.';
  static const noQueueTitle = 'Queue clear';
  static const noQueueBody =
      'There are no unassigned or claimed reports to review.';
  static const loadingQueue = 'Loading moderation queue';
  static const unassigned = 'Unassigned';
  static const assignedToYou = 'Assigned to you';
  static const openReport = 'Open report';
  static const reportDetails = 'Report details';
  static const reportId = 'Report ID';
  static const conversationId = 'Conversation ID';
  static const messageId = 'Message ID';
  static const reporterId = 'Reporter ID';
  static const targetId = 'Target ID';
  static const reportNote = 'Reporter note';
  static const noNote = 'No note provided.';
  static const claimReport = 'Claim report';
  static const claimingReport = 'Claiming report';
  static const claimBody =
      'Claiming creates temporary, audited access to the report\'s conversation evidence.';
  static const assignedElsewhere =
      'This report is assigned to another moderator.';
  static const evidenceTitle = 'Report evidence';
  static const evidenceAccess = 'Reviewing under report';
  static const evidenceAccessBody =
      'Access is read-only, limited to the granted message window, and audited by the server.';
  static const evidenceAfterClaim =
      'Claim this report to request its scoped evidence grant.';
  static const noConversationEvidence =
      'This report has no conversation evidence to display.';
  static const loadingEvidence = 'Loading granted evidence';
  static const evidenceExpired =
      'The report evidence grant has expired or was revoked.';
  static const noEvidenceMessages =
      'No messages are available in the granted evidence window.';
  static const deletedMessage = 'Deleted message';
  static const messageType = 'Message type';
  static const sender = 'Sender';
  static const sequence = 'Sequence';
  static const reportedMessage = 'Reported message';
  static const resolveReport = 'Resolve report';
  static const resolvingReport = 'Resolving report';
  static const resolutionNote = 'Resolution note (optional)';
  static const resolutionNoteHint = 'Add a concise audit note.';
  static const resolutionNoteTooLong =
      'Keep the resolution note under 500 characters.';
  static const dismissAction = 'Dismiss report';
  static const dismissDescription =
      'Close the report without applying an account or content action.';
  static const removeContentAction = 'Remove reported content';
  static const removeContentDescription =
      'Delete the reported message content.';
  static const banAction = 'Ban eligible account';
  static const banDescription =
      'Ban the reported student or professor account. The server rejects ineligible targets.';
  static const resolutionFinal =
      'Resolution is final and revokes the evidence grant.';
  static const reportResolved = 'Report resolved';
  static const resolvedBody =
      'The report is closed and its evidence grant has been revoked.';

  static const genericError = 'The request could not be completed. Try again.';
  static const networkError =
      'The server could not be reached. Check your connection and try again.';
  static const invalidTargetError =
      'This report target is no longer available.';
  static const messageRequiredError =
      'A reported message is required for this action.';
  static const reportNotFoundError = 'This report is no longer available.';
  static const moderatorConflictError =
      'You cannot review a report involving your own account.';
  static const alreadyAssignedError =
      'Another moderator has already claimed this report.';
  static const reportClosedError = 'This report has already been closed.';
  static const unsafeBanError =
      'This target is not eligible for an account ban.';
  static const forbiddenError =
      'You do not have permission to perform this action.';
}
