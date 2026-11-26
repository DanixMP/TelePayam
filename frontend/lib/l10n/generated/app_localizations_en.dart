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
  String get welcomeTitle => 'Your university, in one conversation';

  @override
  String get welcomeBody =>
      'Message classmates and professors with a university-verified identity.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get persian => 'فارسی';

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
    return 'Send again in ${seconds}s';
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
  String get statusStep => 'Access';

  @override
  String get themeTooltip => 'Change theme';

  @override
  String get languageTooltip => 'Change language';

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
    return '$count members';
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
}
