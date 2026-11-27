// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'University Messenger';

  @override
  String get appDescription =>
      'University-verified messaging, services, and academic channels.';

  @override
  String get enableAccessibility => 'Enable accessibility';

  @override
  String get welcomeTitle => 'Your university, in one conversation';

  @override
  String get welcomeBody =>
      'Message classmates and professors with a university-verified identity.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get persian => 'Persian';

  @override
  String get english => 'English';

  @override
  String get phoneTitle => 'Enter your phone number';

  @override
  String get phoneBody =>
      'We will send a six-digit code to verify this number.';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get phoneHint => '912 123 4567';

  @override
  String get sendCode => 'Send code';

  @override
  String get invalidPhone => 'Enter a valid Iranian mobile number.';

  @override
  String get termsNote =>
      'Continuing confirms that this number belongs to you.';

  @override
  String get otpTitle => 'Check your messages';

  @override
  String otpBody(String phone) {
    return 'Enter the code sent to $phone.';
  }

  @override
  String get codeLabel => 'Verification code';

  @override
  String get verify => 'Verify';

  @override
  String resendIn(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Send again in ${secondsString}s';
  }

  @override
  String get resendCode => 'Send code again';

  @override
  String developmentCode(String code) {
    return 'Development code: $code';
  }

  @override
  String get invalidCode => 'Enter the complete six-digit code.';

  @override
  String get changePhone => 'Change phone number';

  @override
  String get studentProfileTitle => 'Complete your student profile';

  @override
  String get studentProfileBody =>
      'These details are reviewed by your university before messaging is enabled.';

  @override
  String get professorProfileTitle => 'Confirm your professor profile';

  @override
  String get professorProfileBody =>
      'Your invitation assigned this account as a professor.';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Family name';

  @override
  String get nationalId => 'National ID';

  @override
  String get nationalIdHint => '10 digits';

  @override
  String get degree => 'Degree';

  @override
  String get department => 'Department';

  @override
  String get universityId => 'University ID';

  @override
  String get academicTitle => 'Academic title';

  @override
  String get next => 'Review details';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get invalidNationalId => 'Enter a valid Iranian National ID.';

  @override
  String get reviewTitle => 'Review your details';

  @override
  String get studentReviewBody =>
      'Make sure these details match your university records.';

  @override
  String get professorReviewBody =>
      'Confirm how your profile should appear to students.';

  @override
  String get edit => 'Edit';

  @override
  String get submitForReview => 'Submit for review';

  @override
  String get activateProfile => 'Activate profile';

  @override
  String get pendingTitle => 'Your profile is under review';

  @override
  String get pendingBody =>
      'Return here to check when your university has reviewed your profile.';

  @override
  String get submitted => 'Submitted';

  @override
  String get underReview => 'University review';

  @override
  String get decision => 'Messaging access';

  @override
  String get refreshStatus => 'Check status';

  @override
  String get checking => 'Checking…';

  @override
  String get lastChecked => 'Checked just now';

  @override
  String get logout => 'Sign out';

  @override
  String get rejectedTitle => 'Your submission needs changes';

  @override
  String get rejectedBody =>
      'Review your details and submit them again. Your university may contact you if more information is needed.';

  @override
  String get correctSubmission => 'Review and resubmit';

  @override
  String get correctionTitle => 'A correction was requested';

  @override
  String get correctionBody =>
      'Update the highlighted information and send your profile again.';

  @override
  String get blockedTitle => 'This account is unavailable';

  @override
  String get blockedBody =>
      'Your account has been suspended or blocked. Contact your university administrator for help.';

  @override
  String get homeTitle => 'Identity verified';

  @override
  String get homeBody =>
      'Your account is active. Chats will appear here in the next product phase.';

  @override
  String get phoneStep => 'Phone';

  @override
  String get verifyStep => 'Verify';

  @override
  String get profileStep => 'Profile';

  @override
  String get reviewStep => 'Review';

  @override
  String verificationProgress(String step, int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$step, step $currentString of $totalString';
  }

  @override
  String get statusStep => 'Access';

  @override
  String get tryAgain => 'Try again';

  @override
  String get genericError =>
      'Something went wrong. Check your connection and try again.';

  @override
  String get otpExpired => 'That code expired. Request a new one.';

  @override
  String get otpIncorrect => 'That code is not correct.';

  @override
  String get otpLocked => 'Too many attempts. Request a new code.';

  @override
  String get otpRateLimited =>
      'Too many code requests. Wait a little and try again.';

  @override
  String get profileExists =>
      'This identity is already registered. Contact your university administrator.';

  @override
  String get sessionExpired => 'Your session expired. Verify your phone again.';

  @override
  String get chats => 'Chats';

  @override
  String get searchChats => 'Search chats and messages';

  @override
  String get noChats => 'No conversations yet';

  @override
  String get noChatsBody =>
      'New conversations will appear here after they are created.';

  @override
  String get noSearchResults => 'No matching chats or messages';

  @override
  String get newMessage => 'New message';

  @override
  String get messageHint => 'Message';

  @override
  String get sendMessage => 'Send message';

  @override
  String get typing => 'typing…';

  @override
  String membersCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString members',
      one: '$countString member',
    );
    return '$_temp0';
  }

  @override
  String get channel => 'Channel';

  @override
  String get group => 'Group';

  @override
  String get directMessage => 'Direct message';

  @override
  String get messageFailed => 'Not sent · Tap to retry';

  @override
  String get messageSending => 'Sending';

  @override
  String get edited => 'edited';

  @override
  String get loadEarlier => 'Load earlier messages';

  @override
  String get selectConversation => 'Select a conversation to start messaging';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get justNow => 'now';

  @override
  String get syncError => 'Could not update chats. Showing saved messages.';

  @override
  String get retry => 'Retry';

  @override
  String get adminPanel => 'Admin panel';

  @override
  String get superAdminPanel => 'Super admin panel';

  @override
  String get studentRequests => 'Student registrations';

  @override
  String get noStudentRequests => 'No registrations awaiting review.';

  @override
  String get approveStudent => 'Approve';

  @override
  String get studentApproved =>
      'Student approved. Their account is now active.';

  @override
  String get requestAlreadyReviewed =>
      'This registration is no longer pending.';

  @override
  String get addAdmin => 'Add admin';

  @override
  String get createAdmin => 'Create admin';

  @override
  String get newAdminHint =>
      'Use an unregistered mobile number. This admin can approve students but cannot add admins.';

  @override
  String get adminCreated =>
      'Admin added. They can now sign in with their SMS code.';

  @override
  String get phoneAlreadyRegistered =>
      'This number already belongs to an account.';

  @override
  String get adminAccessRequired =>
      'An active administrator account is required.';

  @override
  String get refreshRequests => 'Refresh registrations';

  @override
  String get myProfile => 'My profile';

  @override
  String get changePhoto => 'Change profile photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get photoUpdateError =>
      'Could not update the photo. Choose a JPG, PNG or WebP image up to 25 MB and retry.';

  @override
  String get photoRemoveError =>
      'Could not remove the profile photo. Try again.';

  @override
  String get username => 'Username';

  @override
  String get messengerId => 'Messenger ID';

  @override
  String get copyId => 'Copy ID';

  @override
  String get findById => 'Find by ID';

  @override
  String get searchIdHint =>
      'Enter at least two username characters or a full Messenger ID.';

  @override
  String get noIdMatches => 'No matching people or communities.';

  @override
  String get directorySearchRateLimited =>
      'Too many searches. Wait a moment and try again.';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemTheme => 'System default';

  @override
  String get systemThemeDescription =>
      'Use your device’s light or dark setting.';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get settingsSaveError =>
      'Could not save your settings. Select an option to try again.';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get refresh => 'Refresh';

  @override
  String get create => 'Create';

  @override
  String get open => 'Open';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get done => 'Done';

  @override
  String get copy => 'Copy';

  @override
  String get add => 'Add';

  @override
  String get unknown => 'Unknown';

  @override
  String get networkError =>
      'Could not reach the server. Check your connection and try again.';

  @override
  String get invalidForm => 'Check the information you entered and try again.';

  @override
  String get forbiddenError =>
      'You do not have permission to perform this action.';

  @override
  String get callHistory => 'Call history';

  @override
  String get callNoCalls => 'No calls yet';

  @override
  String get callNoCallsBody => 'Calls you make or receive will appear here.';

  @override
  String get callAudioCall => 'Audio call';

  @override
  String get callVideoCall => 'Video call';

  @override
  String get callIncomingAudioCall => 'Incoming audio call';

  @override
  String get callIncomingVideoCall => 'Incoming video call';

  @override
  String get callUnknownCaller => 'Unknown caller';

  @override
  String get callIncoming => 'Incoming call';

  @override
  String get callActive => 'Active call';

  @override
  String get callReturn => 'Return to call';

  @override
  String get callOutgoingCall => 'Outgoing call';

  @override
  String get callCalling => 'Calling…';

  @override
  String get callRinging => 'Ringing…';

  @override
  String get callConnecting => 'Connecting securely…';

  @override
  String get callReconnecting => 'Reconnecting…';

  @override
  String get callConnected => 'Connected';

  @override
  String get callWaitingForAnswer => 'Waiting for an answer';

  @override
  String get callCallEnded => 'Call ended';

  @override
  String get callDeclined => 'Declined';

  @override
  String get callMissed => 'Missed';

  @override
  String get callAnswer => 'Answer';

  @override
  String get callDecline => 'Decline';

  @override
  String get callEndCall => 'End call';

  @override
  String get callMicrophoneOn => 'Mute microphone';

  @override
  String get callMicrophoneOff => 'Unmute microphone';

  @override
  String get callSpeakerOn => 'Use earpiece';

  @override
  String get callSpeakerOff => 'Use speaker';

  @override
  String get callCameraOn => 'Turn camera off';

  @override
  String get callCameraOff => 'Turn camera on';

  @override
  String get callSwitchCamera => 'Switch camera';

  @override
  String get callWaitingForVideo => 'Waiting for video';

  @override
  String get callIncomingCallEnded => 'This call is no longer ringing.';

  @override
  String get callCallUnavailable => 'Call unavailable';

  @override
  String get callCallInProgress => 'A call is already in progress.';

  @override
  String get callDirectCallsOnly =>
      'Calls are available in direct messages only.';

  @override
  String get callDirectCallUnavailable => 'This conversation cannot be called.';

  @override
  String get callMediaConnectionError =>
      'Could not connect call audio or video. Check permissions and try again.';

  @override
  String get callMediaDeviceError =>
      'Could not change that device setting. Check device permissions.';

  @override
  String get callActiveCallRequired => 'The call has already ended.';

  @override
  String callIdentity(String name, String status) {
    return '$name, $status';
  }

  @override
  String dateAndTime(String date, String time) {
    return '$date, $time';
  }

  @override
  String get chatNavigation => 'Open navigation';

  @override
  String get savedMessages => 'Saved messages';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get photo => 'Photo';

  @override
  String get video => 'Video';

  @override
  String get voiceMessage => 'Voice message';

  @override
  String get audio => 'Audio';

  @override
  String get file => 'File';

  @override
  String get document => 'Document';

  @override
  String get album => 'Album';

  @override
  String get poll => 'Poll';

  @override
  String get sticker => 'Sticker';

  @override
  String get gif => 'GIF';

  @override
  String get attachment => 'Attachment';

  @override
  String get attach => 'Attach';

  @override
  String get media => 'Media';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get retryImage => 'Retry image';

  @override
  String get retryAttachment => 'Retry attachment';

  @override
  String get imageAttachment => 'Image attachment';

  @override
  String get download => 'Download';

  @override
  String mediaSavedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get mediaSaveFailed => 'Could not save this attachment. Try again.';

  @override
  String get mediaPlaybackUnavailable =>
      'Playback unavailable. Try downloading the attachment.';

  @override
  String get mediaFormatUnavailable =>
      'This device cannot play this format. You can still download it.';

  @override
  String get mediaPlay => 'Play';

  @override
  String get mediaPause => 'Pause';

  @override
  String mediaBytes(String size) {
    return '$size B';
  }

  @override
  String mediaKilobytes(String size) {
    return '$size KB';
  }

  @override
  String mediaMegabytes(String size) {
    return '$size MB';
  }

  @override
  String get chatAttachmentLimit => 'Choose up to 10 attachments per message.';

  @override
  String get chatUploadFailed =>
      'Upload failed. Check your connection and try again.';

  @override
  String get chatCreatePoll => 'Create poll';

  @override
  String get chatPollQuestion => 'Question';

  @override
  String chatPollOption(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'Option $numberString';
  }

  @override
  String chatPollVotes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString votes',
      one: '$countString vote',
    );
    return '$_temp0';
  }

  @override
  String get chatStickerLoadError => 'Could not load stickers and GIFs.';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatStickers => 'Stickers';

  @override
  String get chatGifs => 'GIFs';

  @override
  String get chatAddSticker => 'Add a sticker';

  @override
  String get chatAddGif => 'Add a GIF';

  @override
  String get chatSendStickerError =>
      'Could not send this sticker or GIF. Try again.';

  @override
  String get chatForwardTo => 'Forward to';

  @override
  String get chatForwardAdded => 'Forward added to chat';

  @override
  String get chatForwardFailed => 'Could not forward this message. Try again.';

  @override
  String get chatNoPinned => 'No pinned messages';

  @override
  String get chatFavoriteSticker => 'Favorite sticker';

  @override
  String get chatStickerFavorited => 'Sticker added to favorites.';

  @override
  String get chatFavoriteFailed => 'Could not favorite this sticker.';

  @override
  String get chatSaveGif => 'Save GIF';

  @override
  String get chatGifSaved => 'GIF saved to your library.';

  @override
  String get chatGifSaveFailed => 'Could not save this GIF.';

  @override
  String get chatReply => 'Reply';

  @override
  String get chatReact => 'React';

  @override
  String chatReactWith(String emoji) {
    return 'React with $emoji';
  }

  @override
  String get chatForward => 'Forward';

  @override
  String get chatPinMessage => 'Pin message';

  @override
  String get chatUnpinMessage => 'Unpin message';

  @override
  String get chatConversationInfo => 'Conversation info';

  @override
  String get chatPinnedMessages => 'Pinned messages';

  @override
  String get chatForwardedMessage => 'Forwarded message';

  @override
  String chatForwardedFrom(String name) {
    return 'Forwarded from $name';
  }

  @override
  String get chatViewOriginal => 'View original message';

  @override
  String get chatOriginalMessage => 'Original message';

  @override
  String get chatOriginalUnavailable => 'Original message is unavailable.';

  @override
  String get chatNoStickers => 'No installed stickers';

  @override
  String get chatNoGifs => 'No saved GIFs';

  @override
  String get chatEditingMessage => 'Editing message';

  @override
  String get chatMessageSent => 'Sent';

  @override
  String get chatStickerFavorites => 'Favorites';

  @override
  String get chatStickerRecents => 'Recent stickers';

  @override
  String get chatMediaPicker => 'Photo, video or file';

  @override
  String get chatStickerPicker => 'Emoji, stickers and GIFs';

  @override
  String get chatCampusNotes => 'Campus Notes';

  @override
  String get chatMyStickers => 'My stickers';

  @override
  String get chatServerRequired =>
      'Connect to the messenger server to start a chat.';

  @override
  String get message => 'Message';

  @override
  String get account => 'Account';

  @override
  String get professor => 'Professor';

  @override
  String get reportSubmitTitle => 'Report';

  @override
  String get reportSubmitBody =>
      'Tell the moderation team what happened. Relevant conversation context may be reviewed while the report is open.';

  @override
  String get reportTarget => 'Report target';

  @override
  String get reportTargetUnknown => 'Unknown target';

  @override
  String get reportReason => 'Reason';

  @override
  String get reportChooseReason => 'Choose a reason';

  @override
  String get reportReasonHarassment => 'Harassment or abuse';

  @override
  String get reportReasonSpam => 'Spam or scam';

  @override
  String get reportReasonHate => 'Hate or discrimination';

  @override
  String get reportReasonImpersonation => 'Impersonation';

  @override
  String get reportReasonViolence => 'Violence or threat';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportDescribeReason => 'Describe the reason';

  @override
  String get reportReasonRequired => 'Choose or enter a reason.';

  @override
  String get reportReasonTooShort => 'Enter at least 2 characters.';

  @override
  String get reportReasonTooLong =>
      'Use no more than 80 characters for the reason.';

  @override
  String get reportNote => 'Additional note (optional)';

  @override
  String get reportNoteHint =>
      'Add details that can help a moderator understand the report.';

  @override
  String get reportNoteTooLong =>
      'Use no more than 1,000 characters for the note.';

  @override
  String get reportPrivacyNotice =>
      'Submitting creates a report and a protected evidence snapshot. A moderator only receives conversation access after claiming the report.';

  @override
  String get reportSubmitAction => 'Submit report';

  @override
  String get reportSubmitting => 'Submitting report';

  @override
  String get reportSubmitted => 'Report submitted';

  @override
  String get reportSubmittedBody => 'You can track its outcome in My reports.';

  @override
  String get reportMyReportsTitle => 'My reports';

  @override
  String get reportNoReportsTitle => 'No reports yet';

  @override
  String get reportNoReportsBody =>
      'Reports you submit and their outcomes will appear here.';

  @override
  String get reportLoadingReports => 'Loading reports';

  @override
  String get reportStatusAssigned => 'Under review';

  @override
  String get reportStatusResolved => 'Resolved';

  @override
  String get reportStatusDismissed => 'Dismissed';

  @override
  String get reportOutcomeWarn => 'Warning outcome recorded';

  @override
  String get reportOutcomeMute => 'Mute outcome recorded';

  @override
  String get reportOutcomeRemoveContent => 'Reported content removed';

  @override
  String get reportOutcomeBan => 'Eligible account banned';

  @override
  String get reportOutcomeEscalate => 'Escalation outcome recorded';

  @override
  String get reportOutcomeUnknown => 'Outcome recorded';

  @override
  String get reportModeratorNote => 'Moderator note';

  @override
  String get reportAwaitingOutcome => 'No outcome has been recorded yet.';

  @override
  String get reportUnderReview =>
      'This conversation is under moderator review.';

  @override
  String get reportUnderReviewBody =>
      'A moderator has temporary access to messages relevant to the report until it is resolved.';

  @override
  String get reportReviewStarted => 'Review started';

  @override
  String get reportModerationQueue => 'Moderation queue';

  @override
  String get reportModerationTitle => 'Moderation reports';

  @override
  String get reportModerationAccessTitle => 'Moderator access required';

  @override
  String get reportModerationAccessBody =>
      'This area is only available to moderator accounts.';

  @override
  String get reportNoQueueTitle => 'Queue clear';

  @override
  String get reportNoQueueBody =>
      'There are no unassigned or claimed reports to review.';

  @override
  String get reportLoadingQueue => 'Loading moderation queue';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get reportAssignedToYou => 'Assigned to you';

  @override
  String get reportOpenReport => 'Open report';

  @override
  String get reportReportDetails => 'Report details';

  @override
  String get reportReportId => 'Report ID';

  @override
  String get reportConversationId => 'Conversation ID';

  @override
  String get reportMessageId => 'Message ID';

  @override
  String get reportReporterId => 'Reporter ID';

  @override
  String get reportTargetId => 'Target ID';

  @override
  String get reportReportNote => 'Reporter note';

  @override
  String get reportNoNote => 'No note provided.';

  @override
  String get reportClaimReport => 'Claim report';

  @override
  String get reportClaimingReport => 'Claiming report';

  @override
  String get reportClaimBody =>
      'Claiming creates temporary, audited access to the conversation evidence for this report.';

  @override
  String get reportAssignedElsewhere =>
      'This report is assigned to another moderator.';

  @override
  String get reportEvidenceTitle => 'Report evidence';

  @override
  String get reportEvidenceAccess => 'Reviewing under report';

  @override
  String get reportEvidenceAccessBody =>
      'Access is read-only, limited to the granted message window, and audited by the server.';

  @override
  String get reportEvidenceAfterClaim =>
      'Claim this report to request access to the relevant messages.';

  @override
  String get reportNoConversationEvidence =>
      'This report has no conversation evidence to display.';

  @override
  String get reportLoadingEvidence => 'Loading granted evidence';

  @override
  String get reportEvidenceExpired =>
      'Access to the report evidence has expired or was revoked.';

  @override
  String get reportNoEvidenceMessages =>
      'No messages are available in the granted evidence window.';

  @override
  String get reportMessageType => 'Message type';

  @override
  String get reportSender => 'Sender';

  @override
  String get reportSequence => 'Sequence';

  @override
  String get reportReportedMessage => 'Reported message';

  @override
  String get reportResolveReport => 'Resolve report';

  @override
  String get reportResolvingReport => 'Resolving report';

  @override
  String get reportResolutionNote => 'Resolution note (optional)';

  @override
  String get reportResolutionNoteHint =>
      'Add a short note for the audit record.';

  @override
  String get reportResolutionNoteTooLong =>
      'Use no more than 500 characters for the resolution note.';

  @override
  String get reportDismissAction => 'Dismiss report';

  @override
  String get reportDismissDescription =>
      'Close the report without applying an account or content action.';

  @override
  String get reportRemoveContentAction => 'Remove reported content';

  @override
  String get reportRemoveContentDescription =>
      'Delete the reported message content.';

  @override
  String get reportBanAction => 'Ban eligible account';

  @override
  String get reportBanDescription =>
      'Ban the reported student or professor account. The server rejects ineligible targets.';

  @override
  String get reportResolutionFinal =>
      'Resolving this report is final and revokes access to the evidence.';

  @override
  String get reportReportResolved => 'Report resolved';

  @override
  String get reportResolvedBody =>
      'The report is closed and access to its evidence has been revoked.';

  @override
  String get reportInvalidTargetError =>
      'This report target is no longer available.';

  @override
  String get reportMessageRequiredError =>
      'A reported message is required for this action.';

  @override
  String get reportNotFoundError => 'This report is no longer available.';

  @override
  String get reportModeratorConflictError =>
      'You cannot review a report involving your own account.';

  @override
  String get reportAlreadyAssignedError =>
      'Another moderator has already claimed this report.';

  @override
  String get reportClosedError => 'This report has already been closed.';

  @override
  String get reportUnsafeBanError =>
      'This target is not eligible for an account ban.';

  @override
  String get createGroup => 'Create group';

  @override
  String get createChannel => 'Create channel';

  @override
  String get createGroupOrChannel => 'Create group or channel';

  @override
  String get discoverCommunities => 'Discover communities';

  @override
  String get universityServices => 'University services';

  @override
  String get services => 'Services';

  @override
  String get serviceCatalog => 'Service catalog';

  @override
  String get serviceMyRequests => 'My requests';

  @override
  String get serviceStaffQueue => 'Staff queue';

  @override
  String get serviceAvailable => 'Available';

  @override
  String get serviceAssignedToMe => 'Assigned to me';

  @override
  String get serviceSubmitRequest => 'Submit request';

  @override
  String get serviceNewRequest => 'New request';

  @override
  String get serviceClaimRequest => 'Claim request';

  @override
  String get serviceRequestClaimed => 'Request claimed';

  @override
  String get serviceRequestCancelled => 'Request cancelled';

  @override
  String get serviceRequestSubmitted => 'Request submitted';

  @override
  String get serviceChangeStatus => 'Change status';

  @override
  String get serviceUpdateStatus => 'Update status';

  @override
  String get serviceResultDocument => 'Result document';

  @override
  String get serviceAssociateResult => 'Attach result document';

  @override
  String get serviceReplaceResult => 'Replace result document';

  @override
  String get serviceTicketChat => 'Request chat';

  @override
  String get serviceAddAttachment => 'Add attachment';

  @override
  String get serviceRemoveAttachment => 'Remove attachment';

  @override
  String get details => 'Details';

  @override
  String get documents => 'Documents';

  @override
  String get review => 'Review';

  @override
  String get serviceTimeline => 'Timeline';

  @override
  String get serviceRequestDetails => 'Request details';

  @override
  String get serviceRequestData => 'Request data';

  @override
  String get serviceRequiredDocuments => 'Required documents';

  @override
  String get serviceAssigned => 'Assigned';

  @override
  String get status => 'Status';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String serviceEstimatedTime(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hoursString hours',
      one: '$hoursString hour',
    );
    return 'Estimated time: $_temp0';
  }

  @override
  String get serviceOptionalNote => 'Note (optional)';

  @override
  String get serviceNote => 'Note';

  @override
  String get serviceEmail => 'Email';

  @override
  String get serviceDate => 'Date';

  @override
  String serviceFieldIdentifier(String identifier) {
    return 'Field: $identifier';
  }

  @override
  String get invalidNumber => 'Enter a valid number.';

  @override
  String get invalidWholeNumber => 'Enter a valid whole number.';

  @override
  String get serviceLoadServicesError => 'Could not load services';

  @override
  String get serviceLoadRequestsError => 'Could not load requests';

  @override
  String get serviceLoadRequestError => 'Could not load this request';

  @override
  String get serviceLoadMessagesError => 'Could not load request messages';

  @override
  String get serviceNoServices => 'No services are available';

  @override
  String get serviceNoServicesBody =>
      'New university services will appear here.';

  @override
  String get serviceNoRequests => 'No requests yet';

  @override
  String get serviceNoRequestsBody =>
      'Choose a service to submit your first request.';

  @override
  String get serviceNoQueue => 'The queue is clear';

  @override
  String get serviceNoQueueBody =>
      'New requests for your department will appear here.';

  @override
  String get serviceNoAssigned => 'No assigned requests';

  @override
  String get serviceNoAssignedBody =>
      'Claim a request from the available queue.';

  @override
  String get serviceNoMessages => 'No request messages yet';

  @override
  String get serviceNoMessagesBody =>
      'Messages between the student and assigned staff appear here.';

  @override
  String get serviceNoTimeline => 'No timeline events are available.';

  @override
  String get serviceNoDocuments => 'No documents are attached.';

  @override
  String get serviceNoRequestData => 'No additional information was provided.';

  @override
  String get serviceFieldHelp =>
      'Provide the information requested by this service.';

  @override
  String get serviceDocumentHelp => 'Upload a file for each required document.';

  @override
  String get serviceReviewHelp =>
      'Check the information before submitting. You cannot edit a request after submitting it.';

  @override
  String get serviceCancellationTitle => 'Cancel this request?';

  @override
  String get serviceCancellationBody =>
      'You can only cancel before a staff member starts processing it.';

  @override
  String get serviceCancelRequest => 'Cancel request';

  @override
  String get serviceKeepRequest => 'Keep request';

  @override
  String get serviceUnsupportedRole =>
      'Services are not available for this account role.';

  @override
  String get serviceUnknownService => 'Unknown service';

  @override
  String get serviceRequest => 'Request';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get serviceDraft => 'Draft';

  @override
  String get serviceInReview => 'In review';

  @override
  String get serviceNeedsInfo => 'Needs information';

  @override
  String get serviceApproved => 'Approved';

  @override
  String get serviceRejected => 'Rejected';

  @override
  String get serviceReadyForPickup => 'Ready for pickup';

  @override
  String get serviceDeliveredDigitally => 'Delivered digitally';

  @override
  String get serviceCompleted => 'Completed';

  @override
  String get serviceCancelled => 'Cancelled';

  @override
  String get serviceUnknownStatus => 'Unknown status';

  @override
  String get serviceEventClaimed => 'Request claimed by staff';

  @override
  String get serviceEventResultUploaded => 'Result document attached';

  @override
  String serviceEventStatusChanged(String status) {
    return 'Status changed: $status';
  }

  @override
  String get serviceUnknownEvent => 'Request updated';

  @override
  String get serviceRequestMissing =>
      'This service request is no longer available.';

  @override
  String get serviceTypeMissing => 'This service is no longer available.';

  @override
  String get serviceRequirementsMissing =>
      'Fill in all required fields and upload the required documents.';

  @override
  String get serviceDocumentUnavailable =>
      'A document or attachment is unavailable. Select the file again.';

  @override
  String get serviceAlreadyAssigned =>
      'Another staff member has already claimed this request.';

  @override
  String get serviceInvalidTransition =>
      'That status change is no longer available. Refresh the request and try again.';

  @override
  String get serviceCannotCancel =>
      'Processing has started. You can no longer cancel this request.';

  @override
  String get chooseFile => 'Choose a file';

  @override
  String get replace => 'Replace';

  @override
  String get upload => 'Upload';

  @override
  String get pdfDocuments => 'PDF documents';

  @override
  String get send => 'Send';

  @override
  String get degreeBachelor => 'Bachelor’s';

  @override
  String get degreeMaster => 'Master’s';

  @override
  String get degreeDoctorate => 'Doctorate';

  @override
  String get degreeOther => 'Other';

  @override
  String get communityStudentGroup => 'Student group';

  @override
  String get communityCreateStudentGroup => 'Create student group';

  @override
  String get communityGroupsUnavailable => 'Student groups are unavailable';

  @override
  String get communityGroupsUnavailableBody =>
      'Only students can create student groups.';

  @override
  String get communityChannelsUnavailable => 'Channel creation is unavailable';

  @override
  String get communityChannelsUnavailableBody =>
      'Only students and professors can create channels.';

  @override
  String get communityUnavailable => 'Communities are unavailable';

  @override
  String get communityUnavailableBody =>
      'Only active students and professors can use communities.';

  @override
  String get communityCreate => 'Create community';

  @override
  String get name => 'Name';

  @override
  String get enterName => 'Enter a name.';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get visibility => 'Visibility';

  @override
  String get publicVisibility => 'Public';

  @override
  String get privateVisibility => 'Private';

  @override
  String get handleOptional => 'Username (optional)';

  @override
  String get communityHandleRequired => 'Public communities need a username.';

  @override
  String get communityProfessorChannel => 'Professor channel';

  @override
  String get communityProfessorChannelHelp =>
      'This channel will appear under Professor channels.';

  @override
  String get communityJoin => 'Join';

  @override
  String get communityJoinWithInvite => 'Join with an invite';

  @override
  String get communityInviteToken => 'Invite token';

  @override
  String get communityPasteInvite => 'Paste an invite token';

  @override
  String get communitySearch => 'Search names and usernames';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get communityAllPublic => 'All public';

  @override
  String get communityProfessorChannels => 'Professor channels';

  @override
  String get communityLoadError => 'Could not load communities';

  @override
  String get communityNotFoundList => 'No communities found';

  @override
  String get communityNoPublic =>
      'There are no public communities in this category yet.';

  @override
  String get communityNoMatches => 'Try a different name or username.';

  @override
  String communityJoined(String name) {
    return 'You joined $name.';
  }

  @override
  String get communityInfo => 'Community info';

  @override
  String get communityUnderReview => 'Conversation under review';

  @override
  String get communityUnderReviewBody =>
      'Some actions may be limited while a report is reviewed.';

  @override
  String get about => 'About';

  @override
  String get members => 'Members';

  @override
  String get created => 'Created';

  @override
  String get manage => 'Manage';

  @override
  String get communityDetailsAndSettings => 'Details and settings';

  @override
  String get communityInviteLinks => 'Invite links';

  @override
  String get communityReport => 'Report community';

  @override
  String get communityDelete => 'Delete community';

  @override
  String get communityLeave => 'Leave community';

  @override
  String communityLeaveTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get communityLeaveBody =>
      'You will need to join again to see new messages.';

  @override
  String get leave => 'Leave';

  @override
  String communityDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get communityDeleteBody =>
      'This permanently deletes the community and its conversation.';

  @override
  String get communityLoadOneError => 'Could not load this community';

  @override
  String get communityJoinAction => 'Join community';

  @override
  String get communityCannotJoin => 'You cannot join this community';

  @override
  String get communityChatUnavailable => 'Conversation unavailable';

  @override
  String get communityOpenChat => 'Open conversation';

  @override
  String get communityDetails => 'Community details';

  @override
  String get communitySaveDetails => 'Save details';

  @override
  String get communityDetailsSaved => 'Community details saved.';

  @override
  String get communityConversationSettings => 'Conversation settings';

  @override
  String get communitySlowMode => 'Slow mode (seconds)';

  @override
  String get communitySlowModeHelp => 'Use 0 to turn slow mode off.';

  @override
  String get communitySlowModeInvalid =>
      'Enter a number from 0 to 86,400 seconds.';

  @override
  String get communityMembersCanPost => 'Members can post';

  @override
  String get communityMembersCanPostHelp =>
      'Allow regular members to send messages.';

  @override
  String get communityMembersCanInvite => 'Members can invite';

  @override
  String get communityMembersCanInviteHelp =>
      'Allow members to share invite links.';

  @override
  String get communityCommentsEnabled => 'Comments enabled';

  @override
  String get communityCommentsEnabledHelp =>
      'Allow discussion on channel posts.';

  @override
  String get saveSettings => 'Save settings';

  @override
  String get communitySettingsSaved => 'Community settings saved.';

  @override
  String get communityAddMember => 'Add member';

  @override
  String get communityLoadMembersError => 'Could not load members';

  @override
  String get communityNoMembers => 'No members';

  @override
  String get communityNoMembersBody => 'No active members were found.';

  @override
  String get communityManageMember => 'Manage member';

  @override
  String get communityOwnerRole => 'Owner';

  @override
  String get communityAdminRole => 'Administrator';

  @override
  String get communityMemberRole => 'Member';

  @override
  String get communitySubscriberRole => 'Subscriber';

  @override
  String get communityBannedRole => 'Banned';

  @override
  String get communityPromoteMember => 'Promote to administrator';

  @override
  String get communityDemoteMember => 'Remove administrator role';

  @override
  String get communityBanMember => 'Ban member';

  @override
  String get ban => 'Ban';

  @override
  String get communityRemoveMember => 'Remove member';

  @override
  String communityBanMemberTitle(String name) {
    return 'Ban $name?';
  }

  @override
  String communityRemoveMemberTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get communityBanMemberBody =>
      'They will be removed and will not be able to rejoin.';

  @override
  String get communityRemoveMemberBody =>
      'They will be removed from this community.';

  @override
  String get communityMemberPromoted => 'Member promoted to administrator.';

  @override
  String get communityMemberDemoted => 'Administrator role removed.';

  @override
  String get communityMemberBanned => 'Member banned.';

  @override
  String get communityMemberRemoved => 'Member removed.';

  @override
  String communityMemberAdded(String name) {
    return '$name was added.';
  }

  @override
  String get communityInviteCreated => 'Invite link created';

  @override
  String get communityCopyInviteHelp =>
      'Copy this token now. It will not be shown again.';

  @override
  String get communityInviteCopied => 'Invite token copied.';

  @override
  String get communityRevokeInvite => 'Revoke invite';

  @override
  String get communityRevokeInviteTitle => 'Revoke this invite?';

  @override
  String get communityRevokeInviteBody =>
      'This invite will stop working immediately.';

  @override
  String get communityInviteRevoked => 'Invite revoked.';

  @override
  String get communityCreateInvite => 'Create invite link';

  @override
  String get communityLoadInvitesError => 'Could not load invites';

  @override
  String get communityNoInvites => 'No invite links';

  @override
  String get communityNoInvitesBody => 'Create an invite for this community.';

  @override
  String get communityActiveInvite => 'Active invite';

  @override
  String get communityRevokedInvite => 'Revoked invite';

  @override
  String get communityExpiredInvite => 'Expired invite';

  @override
  String get communityUsedInvite => 'Used invite';

  @override
  String get communityExpiresAfter => 'Expires after';

  @override
  String get communityExpiryOneDay => '24 hours';

  @override
  String get communityExpiryOneWeek => '7 days';

  @override
  String get communityExpiryThirtyDays => '30 days';

  @override
  String get communityNeverExpires => 'No expiry';

  @override
  String get communityMaxUses => 'Maximum uses (optional)';

  @override
  String get communityMaxUsesInvalid => 'Enter a number from 1 to 10,000.';

  @override
  String communityInviteUses(int uses) {
    final intl.NumberFormat usesNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String usesString = usesNumberFormat.format(uses);

    String _temp0 = intl.Intl.pluralLogic(
      uses,
      locale: localeName,
      other: '$usesString uses',
      one: '$usesString use',
    );
    return '$_temp0';
  }

  @override
  String communityInviteUsesOf(int uses, int maxUses) {
    final intl.NumberFormat usesNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String usesString = usesNumberFormat.format(uses);
    final intl.NumberFormat maxUsesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxUsesString = maxUsesNumberFormat.format(maxUses);

    return '$usesString of $maxUsesString uses';
  }

  @override
  String communityInviteExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get communityInvalidHandle => 'Enter a valid username.';

  @override
  String get communityHandleTaken => 'This username is already in use.';

  @override
  String get communityInvalidGroupMember =>
      'Only students can join student groups.';

  @override
  String get communityRejoinDenied =>
      'This account cannot rejoin the community.';

  @override
  String get communityMissing => 'This community is no longer available.';

  @override
  String get communityInviteInvalid => 'This invite is invalid or has expired.';

  @override
  String get communityUserMissing => 'No user was found with that username.';

  @override
  String get communityAlreadyMember => 'This user is already a member.';

  @override
  String get communityOwnerCannotLeave =>
      'Transfer ownership or delete the community before leaving.';

  @override
  String get communityMemberMissing => 'This person is no longer a member.';

  @override
  String get communityInvalidMemberRole =>
      'That role is not available for this community.';

  @override
  String get communityDmUnavailable =>
      'This action is unavailable in direct messages.';

  @override
  String communityOfficialDescription(String name) {
    return 'Official channel for $name';
  }

  @override
  String get mediaInvalidSize => 'Choose a non-empty file of 25 MB or less.';

  @override
  String get mediaUnsupportedType => 'Choose a supported file type.';

  @override
  String get mediaInvalidContent =>
      'The file does not match its format. Choose another file.';

  @override
  String get chatDemoStudy => 'Study Group · Algorithms';

  @override
  String get chatDemoProfessor => 'Professor Rahimi · Data Structures';

  @override
  String get chatDemoSara => 'Sara Ahmadi';

  @override
  String get chatDemoStudyOne =>
      'Does anyone want to review dynamic programming today?';

  @override
  String get chatDemoStudyTwo => 'Yes, after the 2 PM lecture works for me.';

  @override
  String get chatDemoStudyThree => 'I uploaded the practice set.';

  @override
  String get chatDemoProfessorOne => 'The week six slides are now available.';

  @override
  String get chatDemoProfessorTwo => 'Office hours moved to 14:30.';

  @override
  String get chatDemoSaraPreview => 'See you at the library.';
}
