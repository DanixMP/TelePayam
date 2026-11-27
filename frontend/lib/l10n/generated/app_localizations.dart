import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'University Messenger'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'University-verified messaging, services, and academic channels.'**
  String get appDescription;

  /// No description provided for @enableAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Enable accessibility'**
  String get enableAccessibility;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your university, in one conversation'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Message classmates and professors with a university-verified identity.'**
  String get welcomeBody;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @persian.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get persian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @phoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneTitle;

  /// No description provided for @phoneBody.
  ///
  /// In en, this message translates to:
  /// **'We will send a six-digit code to verify this number.'**
  String get phoneBody;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'912 123 4567'**
  String get phoneHint;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Iranian mobile number.'**
  String get invalidPhone;

  /// No description provided for @termsNote.
  ///
  /// In en, this message translates to:
  /// **'Continuing confirms that this number belongs to you.'**
  String get termsNote;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your messages'**
  String get otpTitle;

  /// No description provided for @otpBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to {phone}.'**
  String otpBody(String phone);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get codeLabel;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Send again in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code again'**
  String get resendCode;

  /// No description provided for @developmentCode.
  ///
  /// In en, this message translates to:
  /// **'Development code: {code}'**
  String developmentCode(String code);

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the complete six-digit code.'**
  String get invalidCode;

  /// No description provided for @changePhone.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get changePhone;

  /// No description provided for @studentProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your student profile'**
  String get studentProfileTitle;

  /// No description provided for @studentProfileBody.
  ///
  /// In en, this message translates to:
  /// **'These details are reviewed by your university before messaging is enabled.'**
  String get studentProfileBody;

  /// No description provided for @professorProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your professor profile'**
  String get professorProfileTitle;

  /// No description provided for @professorProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Your invitation assigned this account as a professor.'**
  String get professorProfileBody;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get lastName;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @nationalIdHint.
  ///
  /// In en, this message translates to:
  /// **'10 digits'**
  String get nationalIdHint;

  /// No description provided for @degree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get degree;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @universityId.
  ///
  /// In en, this message translates to:
  /// **'University ID'**
  String get universityId;

  /// No description provided for @academicTitle.
  ///
  /// In en, this message translates to:
  /// **'Academic title'**
  String get academicTitle;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Review details'**
  String get next;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @invalidNationalId.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Iranian National ID.'**
  String get invalidNationalId;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your details'**
  String get reviewTitle;

  /// No description provided for @studentReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Make sure these details match your university records.'**
  String get studentReviewBody;

  /// No description provided for @professorReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm how your profile should appear to students.'**
  String get professorReviewBody;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get submitForReview;

  /// No description provided for @activateProfile.
  ///
  /// In en, this message translates to:
  /// **'Activate profile'**
  String get activateProfile;

  /// No description provided for @pendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile is under review'**
  String get pendingTitle;

  /// No description provided for @pendingBody.
  ///
  /// In en, this message translates to:
  /// **'Return here to check when your university has reviewed your profile.'**
  String get pendingBody;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'University review'**
  String get underReview;

  /// No description provided for @decision.
  ///
  /// In en, this message translates to:
  /// **'Messaging access'**
  String get decision;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Check status'**
  String get refreshStatus;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @lastChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked just now'**
  String get lastChecked;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @rejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your submission needs changes'**
  String get rejectedTitle;

  /// No description provided for @rejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Review your details and submit them again. Your university may contact you if more information is needed.'**
  String get rejectedBody;

  /// No description provided for @correctSubmission.
  ///
  /// In en, this message translates to:
  /// **'Review and resubmit'**
  String get correctSubmission;

  /// No description provided for @correctionTitle.
  ///
  /// In en, this message translates to:
  /// **'A correction was requested'**
  String get correctionTitle;

  /// No description provided for @correctionBody.
  ///
  /// In en, this message translates to:
  /// **'Update the highlighted information and send your profile again.'**
  String get correctionBody;

  /// No description provided for @blockedTitle.
  ///
  /// In en, this message translates to:
  /// **'This account is unavailable'**
  String get blockedTitle;

  /// No description provided for @blockedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended or blocked. Contact your university administrator for help.'**
  String get blockedBody;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity verified'**
  String get homeTitle;

  /// No description provided for @homeBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is active. Chats will appear here in the next product phase.'**
  String get homeBody;

  /// No description provided for @phoneStep.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneStep;

  /// No description provided for @verifyStep.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyStep;

  /// No description provided for @profileStep.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileStep;

  /// No description provided for @reviewStep.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewStep;

  /// No description provided for @verificationProgress.
  ///
  /// In en, this message translates to:
  /// **'{step}, step {current} of {total}'**
  String verificationProgress(String step, int current, int total);

  /// No description provided for @statusStep.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get statusStep;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again.'**
  String get genericError;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'That code expired. Request a new one.'**
  String get otpExpired;

  /// No description provided for @otpIncorrect.
  ///
  /// In en, this message translates to:
  /// **'That code is not correct.'**
  String get otpIncorrect;

  /// No description provided for @otpLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Request a new code.'**
  String get otpLocked;

  /// No description provided for @otpRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many code requests. Wait a little and try again.'**
  String get otpRateLimited;

  /// No description provided for @profileExists.
  ///
  /// In en, this message translates to:
  /// **'This identity is already registered. Contact your university administrator.'**
  String get profileExists;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Verify your phone again.'**
  String get sessionExpired;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @searchChats.
  ///
  /// In en, this message translates to:
  /// **'Search chats and messages'**
  String get searchChats;

  /// No description provided for @noChats.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noChats;

  /// No description provided for @noChatsBody.
  ///
  /// In en, this message translates to:
  /// **'New conversations will appear here after they are created.'**
  String get noChatsBody;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching chats or messages'**
  String get noSearchResults;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageHint;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'typing…'**
  String get typing;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} member} other{{count} members}}'**
  String membersCount(int count);

  /// No description provided for @channel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get channel;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @directMessage.
  ///
  /// In en, this message translates to:
  /// **'Direct message'**
  String get directMessage;

  /// No description provided for @messageFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent · Tap to retry'**
  String get messageFailed;

  /// No description provided for @messageSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get messageSending;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get edited;

  /// No description provided for @loadEarlier.
  ///
  /// In en, this message translates to:
  /// **'Load earlier messages'**
  String get loadEarlier;

  /// No description provided for @selectConversation.
  ///
  /// In en, this message translates to:
  /// **'Select a conversation to start messaging'**
  String get selectConversation;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get justNow;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Could not update chats. Showing saved messages.'**
  String get syncError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin panel'**
  String get adminPanel;

  /// No description provided for @superAdminPanel.
  ///
  /// In en, this message translates to:
  /// **'Super admin panel'**
  String get superAdminPanel;

  /// No description provided for @studentRequests.
  ///
  /// In en, this message translates to:
  /// **'Student registrations'**
  String get studentRequests;

  /// No description provided for @noStudentRequests.
  ///
  /// In en, this message translates to:
  /// **'No registrations awaiting review.'**
  String get noStudentRequests;

  /// No description provided for @approveStudent.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveStudent;

  /// No description provided for @studentApproved.
  ///
  /// In en, this message translates to:
  /// **'Student approved. Their account is now active.'**
  String get studentApproved;

  /// No description provided for @requestAlreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'This registration is no longer pending.'**
  String get requestAlreadyReviewed;

  /// No description provided for @addAdmin.
  ///
  /// In en, this message translates to:
  /// **'Add admin'**
  String get addAdmin;

  /// No description provided for @createAdmin.
  ///
  /// In en, this message translates to:
  /// **'Create admin'**
  String get createAdmin;

  /// No description provided for @newAdminHint.
  ///
  /// In en, this message translates to:
  /// **'Use an unregistered mobile number. This admin can approve students but cannot add admins.'**
  String get newAdminHint;

  /// No description provided for @adminCreated.
  ///
  /// In en, this message translates to:
  /// **'Admin added. They can now sign in with their SMS code.'**
  String get adminCreated;

  /// No description provided for @phoneAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This number already belongs to an account.'**
  String get phoneAlreadyRegistered;

  /// No description provided for @adminAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'An active administrator account is required.'**
  String get adminAccessRequired;

  /// No description provided for @refreshRequests.
  ///
  /// In en, this message translates to:
  /// **'Refresh registrations'**
  String get refreshRequests;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @photoUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Could not update the photo. Choose a JPG, PNG or WebP image up to 25 MB and retry.'**
  String get photoUpdateError;

  /// No description provided for @photoRemoveError.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the profile photo. Try again.'**
  String get photoRemoveError;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @messengerId.
  ///
  /// In en, this message translates to:
  /// **'Messenger ID'**
  String get messengerId;

  /// No description provided for @copyId.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get copyId;

  /// No description provided for @findById.
  ///
  /// In en, this message translates to:
  /// **'Find by ID'**
  String get findById;

  /// No description provided for @searchIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter at least two username characters or a full Messenger ID.'**
  String get searchIdHint;

  /// No description provided for @noIdMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching people or communities.'**
  String get noIdMatches;

  /// No description provided for @directorySearchRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many searches. Wait a moment and try again.'**
  String get directorySearchRateLimited;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemTheme;

  /// No description provided for @systemThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Use your device’s light or dark setting.'**
  String get systemThemeDescription;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @settingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your settings. Select an option to try again.'**
  String get settingsSaveError;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection and try again.'**
  String get networkError;

  /// No description provided for @invalidForm.
  ///
  /// In en, this message translates to:
  /// **'Check the information you entered and try again.'**
  String get invalidForm;

  /// No description provided for @forbiddenError.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get forbiddenError;

  /// No description provided for @callHistory.
  ///
  /// In en, this message translates to:
  /// **'Call history'**
  String get callHistory;

  /// No description provided for @callNoCalls.
  ///
  /// In en, this message translates to:
  /// **'No calls yet'**
  String get callNoCalls;

  /// No description provided for @callNoCallsBody.
  ///
  /// In en, this message translates to:
  /// **'Calls you make or receive will appear here.'**
  String get callNoCallsBody;

  /// No description provided for @callAudioCall.
  ///
  /// In en, this message translates to:
  /// **'Audio call'**
  String get callAudioCall;

  /// No description provided for @callVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get callVideoCall;

  /// No description provided for @callIncomingAudioCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming audio call'**
  String get callIncomingAudioCall;

  /// No description provided for @callIncomingVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming video call'**
  String get callIncomingVideoCall;

  /// No description provided for @callUnknownCaller.
  ///
  /// In en, this message translates to:
  /// **'Unknown caller'**
  String get callUnknownCaller;

  /// No description provided for @callIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get callIncoming;

  /// No description provided for @callActive.
  ///
  /// In en, this message translates to:
  /// **'Active call'**
  String get callActive;

  /// No description provided for @callReturn.
  ///
  /// In en, this message translates to:
  /// **'Return to call'**
  String get callReturn;

  /// No description provided for @callOutgoingCall.
  ///
  /// In en, this message translates to:
  /// **'Outgoing call'**
  String get callOutgoingCall;

  /// No description provided for @callCalling.
  ///
  /// In en, this message translates to:
  /// **'Calling…'**
  String get callCalling;

  /// No description provided for @callRinging.
  ///
  /// In en, this message translates to:
  /// **'Ringing…'**
  String get callRinging;

  /// No description provided for @callConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting securely…'**
  String get callConnecting;

  /// No description provided for @callReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get callReconnecting;

  /// No description provided for @callConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get callConnected;

  /// No description provided for @callWaitingForAnswer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an answer'**
  String get callWaitingForAnswer;

  /// No description provided for @callCallEnded.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get callCallEnded;

  /// No description provided for @callDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get callDeclined;

  /// No description provided for @callMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get callMissed;

  /// No description provided for @callAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get callAnswer;

  /// No description provided for @callDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get callDecline;

  /// No description provided for @callEndCall.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get callEndCall;

  /// No description provided for @callMicrophoneOn.
  ///
  /// In en, this message translates to:
  /// **'Mute microphone'**
  String get callMicrophoneOn;

  /// No description provided for @callMicrophoneOff.
  ///
  /// In en, this message translates to:
  /// **'Unmute microphone'**
  String get callMicrophoneOff;

  /// No description provided for @callSpeakerOn.
  ///
  /// In en, this message translates to:
  /// **'Use earpiece'**
  String get callSpeakerOn;

  /// No description provided for @callSpeakerOff.
  ///
  /// In en, this message translates to:
  /// **'Use speaker'**
  String get callSpeakerOff;

  /// No description provided for @callCameraOn.
  ///
  /// In en, this message translates to:
  /// **'Turn camera off'**
  String get callCameraOn;

  /// No description provided for @callCameraOff.
  ///
  /// In en, this message translates to:
  /// **'Turn camera on'**
  String get callCameraOff;

  /// No description provided for @callSwitchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get callSwitchCamera;

  /// No description provided for @callWaitingForVideo.
  ///
  /// In en, this message translates to:
  /// **'Waiting for video'**
  String get callWaitingForVideo;

  /// No description provided for @callIncomingCallEnded.
  ///
  /// In en, this message translates to:
  /// **'This call is no longer ringing.'**
  String get callIncomingCallEnded;

  /// No description provided for @callCallUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Call unavailable'**
  String get callCallUnavailable;

  /// No description provided for @callCallInProgress.
  ///
  /// In en, this message translates to:
  /// **'A call is already in progress.'**
  String get callCallInProgress;

  /// No description provided for @callDirectCallsOnly.
  ///
  /// In en, this message translates to:
  /// **'Calls are available in direct messages only.'**
  String get callDirectCallsOnly;

  /// No description provided for @callDirectCallUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This conversation cannot be called.'**
  String get callDirectCallUnavailable;

  /// No description provided for @callMediaConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect call audio or video. Check permissions and try again.'**
  String get callMediaConnectionError;

  /// No description provided for @callMediaDeviceError.
  ///
  /// In en, this message translates to:
  /// **'Could not change that device setting. Check device permissions.'**
  String get callMediaDeviceError;

  /// No description provided for @callActiveCallRequired.
  ///
  /// In en, this message translates to:
  /// **'The call has already ended.'**
  String get callActiveCallRequired;

  /// No description provided for @callIdentity.
  ///
  /// In en, this message translates to:
  /// **'{name}, {status}'**
  String callIdentity(String name, String status);

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String dateAndTime(String date, String time);

  /// No description provided for @chatNavigation.
  ///
  /// In en, this message translates to:
  /// **'Open navigation'**
  String get chatNavigation;

  /// No description provided for @savedMessages.
  ///
  /// In en, this message translates to:
  /// **'Saved messages'**
  String get savedMessages;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get voiceMessage;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// No description provided for @poll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get poll;

  /// No description provided for @sticker.
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get sticker;

  /// No description provided for @gif.
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get gif;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// No description provided for @attach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get attach;

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @retryImage.
  ///
  /// In en, this message translates to:
  /// **'Retry image'**
  String get retryImage;

  /// No description provided for @retryAttachment.
  ///
  /// In en, this message translates to:
  /// **'Retry attachment'**
  String get retryAttachment;

  /// No description provided for @imageAttachment.
  ///
  /// In en, this message translates to:
  /// **'Image attachment'**
  String get imageAttachment;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @mediaSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String mediaSavedTo(String path);

  /// No description provided for @mediaSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this attachment. Try again.'**
  String get mediaSaveFailed;

  /// No description provided for @mediaPlaybackUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Playback unavailable. Try downloading the attachment.'**
  String get mediaPlaybackUnavailable;

  /// No description provided for @mediaFormatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device cannot play this format. You can still download it.'**
  String get mediaFormatUnavailable;

  /// No description provided for @mediaPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get mediaPlay;

  /// No description provided for @mediaPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get mediaPause;

  /// No description provided for @mediaBytes.
  ///
  /// In en, this message translates to:
  /// **'{size} B'**
  String mediaBytes(String size);

  /// No description provided for @mediaKilobytes.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String mediaKilobytes(String size);

  /// No description provided for @mediaMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String mediaMegabytes(String size);

  /// No description provided for @chatAttachmentLimit.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 10 attachments per message.'**
  String get chatAttachmentLimit;

  /// No description provided for @chatUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Check your connection and try again.'**
  String get chatUploadFailed;

  /// No description provided for @chatCreatePoll.
  ///
  /// In en, this message translates to:
  /// **'Create poll'**
  String get chatCreatePoll;

  /// No description provided for @chatPollQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get chatPollQuestion;

  /// No description provided for @chatPollOption.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String chatPollOption(int number);

  /// No description provided for @chatPollVotes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} vote} other{{count} votes}}'**
  String chatPollVotes(int count);

  /// No description provided for @chatStickerLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load stickers and GIFs.'**
  String get chatStickerLoadError;

  /// No description provided for @chatEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get chatEmoji;

  /// No description provided for @chatStickers.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get chatStickers;

  /// No description provided for @chatGifs.
  ///
  /// In en, this message translates to:
  /// **'GIFs'**
  String get chatGifs;

  /// No description provided for @chatAddSticker.
  ///
  /// In en, this message translates to:
  /// **'Add a sticker'**
  String get chatAddSticker;

  /// No description provided for @chatAddGif.
  ///
  /// In en, this message translates to:
  /// **'Add a GIF'**
  String get chatAddGif;

  /// No description provided for @chatSendStickerError.
  ///
  /// In en, this message translates to:
  /// **'Could not send this sticker or GIF. Try again.'**
  String get chatSendStickerError;

  /// No description provided for @chatForwardTo.
  ///
  /// In en, this message translates to:
  /// **'Forward to'**
  String get chatForwardTo;

  /// No description provided for @chatForwardAdded.
  ///
  /// In en, this message translates to:
  /// **'Forward added to chat'**
  String get chatForwardAdded;

  /// No description provided for @chatForwardFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not forward this message. Try again.'**
  String get chatForwardFailed;

  /// No description provided for @chatNoPinned.
  ///
  /// In en, this message translates to:
  /// **'No pinned messages'**
  String get chatNoPinned;

  /// No description provided for @chatFavoriteSticker.
  ///
  /// In en, this message translates to:
  /// **'Favorite sticker'**
  String get chatFavoriteSticker;

  /// No description provided for @chatStickerFavorited.
  ///
  /// In en, this message translates to:
  /// **'Sticker added to favorites.'**
  String get chatStickerFavorited;

  /// No description provided for @chatFavoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not favorite this sticker.'**
  String get chatFavoriteFailed;

  /// No description provided for @chatSaveGif.
  ///
  /// In en, this message translates to:
  /// **'Save GIF'**
  String get chatSaveGif;

  /// No description provided for @chatGifSaved.
  ///
  /// In en, this message translates to:
  /// **'GIF saved to your library.'**
  String get chatGifSaved;

  /// No description provided for @chatGifSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this GIF.'**
  String get chatGifSaveFailed;

  /// No description provided for @chatReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatReply;

  /// No description provided for @chatReact.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get chatReact;

  /// No description provided for @chatReactWith.
  ///
  /// In en, this message translates to:
  /// **'React with {emoji}'**
  String chatReactWith(String emoji);

  /// No description provided for @chatForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatForward;

  /// No description provided for @chatPinMessage.
  ///
  /// In en, this message translates to:
  /// **'Pin message'**
  String get chatPinMessage;

  /// No description provided for @chatUnpinMessage.
  ///
  /// In en, this message translates to:
  /// **'Unpin message'**
  String get chatUnpinMessage;

  /// No description provided for @chatConversationInfo.
  ///
  /// In en, this message translates to:
  /// **'Conversation info'**
  String get chatConversationInfo;

  /// No description provided for @chatPinnedMessages.
  ///
  /// In en, this message translates to:
  /// **'Pinned messages'**
  String get chatPinnedMessages;

  /// No description provided for @chatForwardedMessage.
  ///
  /// In en, this message translates to:
  /// **'Forwarded message'**
  String get chatForwardedMessage;

  /// No description provided for @chatForwardedFrom.
  ///
  /// In en, this message translates to:
  /// **'Forwarded from {name}'**
  String chatForwardedFrom(String name);

  /// No description provided for @chatViewOriginal.
  ///
  /// In en, this message translates to:
  /// **'View original message'**
  String get chatViewOriginal;

  /// No description provided for @chatOriginalMessage.
  ///
  /// In en, this message translates to:
  /// **'Original message'**
  String get chatOriginalMessage;

  /// No description provided for @chatOriginalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Original message is unavailable.'**
  String get chatOriginalUnavailable;

  /// No description provided for @chatNoStickers.
  ///
  /// In en, this message translates to:
  /// **'No installed stickers'**
  String get chatNoStickers;

  /// No description provided for @chatNoGifs.
  ///
  /// In en, this message translates to:
  /// **'No saved GIFs'**
  String get chatNoGifs;

  /// No description provided for @chatEditingMessage.
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get chatEditingMessage;

  /// No description provided for @chatMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatMessageSent;

  /// No description provided for @chatStickerFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get chatStickerFavorites;

  /// No description provided for @chatStickerRecents.
  ///
  /// In en, this message translates to:
  /// **'Recent stickers'**
  String get chatStickerRecents;

  /// No description provided for @chatMediaPicker.
  ///
  /// In en, this message translates to:
  /// **'Photo, video or file'**
  String get chatMediaPicker;

  /// No description provided for @chatStickerPicker.
  ///
  /// In en, this message translates to:
  /// **'Emoji, stickers and GIFs'**
  String get chatStickerPicker;

  /// No description provided for @chatCampusNotes.
  ///
  /// In en, this message translates to:
  /// **'Campus Notes'**
  String get chatCampusNotes;

  /// No description provided for @chatMyStickers.
  ///
  /// In en, this message translates to:
  /// **'My stickers'**
  String get chatMyStickers;

  /// No description provided for @chatServerRequired.
  ///
  /// In en, this message translates to:
  /// **'Connect to the messenger server to start a chat.'**
  String get chatServerRequired;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @professor.
  ///
  /// In en, this message translates to:
  /// **'Professor'**
  String get professor;

  /// No description provided for @reportSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportSubmitTitle;

  /// No description provided for @reportSubmitBody.
  ///
  /// In en, this message translates to:
  /// **'Tell the moderation team what happened. Relevant conversation context may be reviewed while the report is open.'**
  String get reportSubmitBody;

  /// No description provided for @reportTarget.
  ///
  /// In en, this message translates to:
  /// **'Report target'**
  String get reportTarget;

  /// No description provided for @reportTargetUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown target'**
  String get reportTargetUnknown;

  /// No description provided for @reportReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportReason;

  /// No description provided for @reportChooseReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason'**
  String get reportChooseReason;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or abuse'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonHate.
  ///
  /// In en, this message translates to:
  /// **'Hate or discrimination'**
  String get reportReasonHate;

  /// No description provided for @reportReasonImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Impersonation'**
  String get reportReasonImpersonation;

  /// No description provided for @reportReasonViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence or threat'**
  String get reportReasonViolence;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// No description provided for @reportDescribeReason.
  ///
  /// In en, this message translates to:
  /// **'Describe the reason'**
  String get reportDescribeReason;

  /// No description provided for @reportReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose or enter a reason.'**
  String get reportReasonRequired;

  /// No description provided for @reportReasonTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters.'**
  String get reportReasonTooShort;

  /// No description provided for @reportReasonTooLong.
  ///
  /// In en, this message translates to:
  /// **'Use no more than 80 characters for the reason.'**
  String get reportReasonTooLong;

  /// No description provided for @reportNote.
  ///
  /// In en, this message translates to:
  /// **'Additional note (optional)'**
  String get reportNote;

  /// No description provided for @reportNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add details that can help a moderator understand the report.'**
  String get reportNoteHint;

  /// No description provided for @reportNoteTooLong.
  ///
  /// In en, this message translates to:
  /// **'Use no more than 1,000 characters for the note.'**
  String get reportNoteTooLong;

  /// No description provided for @reportPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Submitting creates a report and a protected evidence snapshot. A moderator only receives conversation access after claiming the report.'**
  String get reportPrivacyNotice;

  /// No description provided for @reportSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmitAction;

  /// No description provided for @reportSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting report'**
  String get reportSubmitting;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmitted;

  /// No description provided for @reportSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'You can track its outcome in My reports.'**
  String get reportSubmittedBody;

  /// No description provided for @reportMyReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get reportMyReportsTitle;

  /// No description provided for @reportNoReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get reportNoReportsTitle;

  /// No description provided for @reportNoReportsBody.
  ///
  /// In en, this message translates to:
  /// **'Reports you submit and their outcomes will appear here.'**
  String get reportNoReportsBody;

  /// No description provided for @reportLoadingReports.
  ///
  /// In en, this message translates to:
  /// **'Loading reports'**
  String get reportLoadingReports;

  /// No description provided for @reportStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get reportStatusAssigned;

  /// No description provided for @reportStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get reportStatusResolved;

  /// No description provided for @reportStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get reportStatusDismissed;

  /// No description provided for @reportOutcomeWarn.
  ///
  /// In en, this message translates to:
  /// **'Warning outcome recorded'**
  String get reportOutcomeWarn;

  /// No description provided for @reportOutcomeMute.
  ///
  /// In en, this message translates to:
  /// **'Mute outcome recorded'**
  String get reportOutcomeMute;

  /// No description provided for @reportOutcomeRemoveContent.
  ///
  /// In en, this message translates to:
  /// **'Reported content removed'**
  String get reportOutcomeRemoveContent;

  /// No description provided for @reportOutcomeBan.
  ///
  /// In en, this message translates to:
  /// **'Eligible account banned'**
  String get reportOutcomeBan;

  /// No description provided for @reportOutcomeEscalate.
  ///
  /// In en, this message translates to:
  /// **'Escalation outcome recorded'**
  String get reportOutcomeEscalate;

  /// No description provided for @reportOutcomeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Outcome recorded'**
  String get reportOutcomeUnknown;

  /// No description provided for @reportModeratorNote.
  ///
  /// In en, this message translates to:
  /// **'Moderator note'**
  String get reportModeratorNote;

  /// No description provided for @reportAwaitingOutcome.
  ///
  /// In en, this message translates to:
  /// **'No outcome has been recorded yet.'**
  String get reportAwaitingOutcome;

  /// No description provided for @reportUnderReview.
  ///
  /// In en, this message translates to:
  /// **'This conversation is under moderator review.'**
  String get reportUnderReview;

  /// No description provided for @reportUnderReviewBody.
  ///
  /// In en, this message translates to:
  /// **'A moderator has temporary access to messages relevant to the report until it is resolved.'**
  String get reportUnderReviewBody;

  /// No description provided for @reportReviewStarted.
  ///
  /// In en, this message translates to:
  /// **'Review started'**
  String get reportReviewStarted;

  /// No description provided for @reportModerationQueue.
  ///
  /// In en, this message translates to:
  /// **'Moderation queue'**
  String get reportModerationQueue;

  /// No description provided for @reportModerationTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation reports'**
  String get reportModerationTitle;

  /// No description provided for @reportModerationAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderator access required'**
  String get reportModerationAccessTitle;

  /// No description provided for @reportModerationAccessBody.
  ///
  /// In en, this message translates to:
  /// **'This area is only available to moderator accounts.'**
  String get reportModerationAccessBody;

  /// No description provided for @reportNoQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue clear'**
  String get reportNoQueueTitle;

  /// No description provided for @reportNoQueueBody.
  ///
  /// In en, this message translates to:
  /// **'There are no unassigned or claimed reports to review.'**
  String get reportNoQueueBody;

  /// No description provided for @reportLoadingQueue.
  ///
  /// In en, this message translates to:
  /// **'Loading moderation queue'**
  String get reportLoadingQueue;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @reportAssignedToYou.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you'**
  String get reportAssignedToYou;

  /// No description provided for @reportOpenReport.
  ///
  /// In en, this message translates to:
  /// **'Open report'**
  String get reportOpenReport;

  /// No description provided for @reportReportDetails.
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get reportReportDetails;

  /// No description provided for @reportReportId.
  ///
  /// In en, this message translates to:
  /// **'Report ID'**
  String get reportReportId;

  /// No description provided for @reportConversationId.
  ///
  /// In en, this message translates to:
  /// **'Conversation ID'**
  String get reportConversationId;

  /// No description provided for @reportMessageId.
  ///
  /// In en, this message translates to:
  /// **'Message ID'**
  String get reportMessageId;

  /// No description provided for @reportReporterId.
  ///
  /// In en, this message translates to:
  /// **'Reporter ID'**
  String get reportReporterId;

  /// No description provided for @reportTargetId.
  ///
  /// In en, this message translates to:
  /// **'Target ID'**
  String get reportTargetId;

  /// No description provided for @reportReportNote.
  ///
  /// In en, this message translates to:
  /// **'Reporter note'**
  String get reportReportNote;

  /// No description provided for @reportNoNote.
  ///
  /// In en, this message translates to:
  /// **'No note provided.'**
  String get reportNoNote;

  /// No description provided for @reportClaimReport.
  ///
  /// In en, this message translates to:
  /// **'Claim report'**
  String get reportClaimReport;

  /// No description provided for @reportClaimingReport.
  ///
  /// In en, this message translates to:
  /// **'Claiming report'**
  String get reportClaimingReport;

  /// No description provided for @reportClaimBody.
  ///
  /// In en, this message translates to:
  /// **'Claiming creates temporary, audited access to the conversation evidence for this report.'**
  String get reportClaimBody;

  /// No description provided for @reportAssignedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'This report is assigned to another moderator.'**
  String get reportAssignedElsewhere;

  /// No description provided for @reportEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Report evidence'**
  String get reportEvidenceTitle;

  /// No description provided for @reportEvidenceAccess.
  ///
  /// In en, this message translates to:
  /// **'Reviewing under report'**
  String get reportEvidenceAccess;

  /// No description provided for @reportEvidenceAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Access is read-only, limited to the granted message window, and audited by the server.'**
  String get reportEvidenceAccessBody;

  /// No description provided for @reportEvidenceAfterClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim this report to request access to the relevant messages.'**
  String get reportEvidenceAfterClaim;

  /// No description provided for @reportNoConversationEvidence.
  ///
  /// In en, this message translates to:
  /// **'This report has no conversation evidence to display.'**
  String get reportNoConversationEvidence;

  /// No description provided for @reportLoadingEvidence.
  ///
  /// In en, this message translates to:
  /// **'Loading granted evidence'**
  String get reportLoadingEvidence;

  /// No description provided for @reportEvidenceExpired.
  ///
  /// In en, this message translates to:
  /// **'Access to the report evidence has expired or was revoked.'**
  String get reportEvidenceExpired;

  /// No description provided for @reportNoEvidenceMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages are available in the granted evidence window.'**
  String get reportNoEvidenceMessages;

  /// No description provided for @reportMessageType.
  ///
  /// In en, this message translates to:
  /// **'Message type'**
  String get reportMessageType;

  /// No description provided for @reportSender.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get reportSender;

  /// No description provided for @reportSequence.
  ///
  /// In en, this message translates to:
  /// **'Sequence'**
  String get reportSequence;

  /// No description provided for @reportReportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reported message'**
  String get reportReportedMessage;

  /// No description provided for @reportResolveReport.
  ///
  /// In en, this message translates to:
  /// **'Resolve report'**
  String get reportResolveReport;

  /// No description provided for @reportResolvingReport.
  ///
  /// In en, this message translates to:
  /// **'Resolving report'**
  String get reportResolvingReport;

  /// No description provided for @reportResolutionNote.
  ///
  /// In en, this message translates to:
  /// **'Resolution note (optional)'**
  String get reportResolutionNote;

  /// No description provided for @reportResolutionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a short note for the audit record.'**
  String get reportResolutionNoteHint;

  /// No description provided for @reportResolutionNoteTooLong.
  ///
  /// In en, this message translates to:
  /// **'Use no more than 500 characters for the resolution note.'**
  String get reportResolutionNoteTooLong;

  /// No description provided for @reportDismissAction.
  ///
  /// In en, this message translates to:
  /// **'Dismiss report'**
  String get reportDismissAction;

  /// No description provided for @reportDismissDescription.
  ///
  /// In en, this message translates to:
  /// **'Close the report without applying an account or content action.'**
  String get reportDismissDescription;

  /// No description provided for @reportRemoveContentAction.
  ///
  /// In en, this message translates to:
  /// **'Remove reported content'**
  String get reportRemoveContentAction;

  /// No description provided for @reportRemoveContentDescription.
  ///
  /// In en, this message translates to:
  /// **'Delete the reported message content.'**
  String get reportRemoveContentDescription;

  /// No description provided for @reportBanAction.
  ///
  /// In en, this message translates to:
  /// **'Ban eligible account'**
  String get reportBanAction;

  /// No description provided for @reportBanDescription.
  ///
  /// In en, this message translates to:
  /// **'Ban the reported student or professor account. The server rejects ineligible targets.'**
  String get reportBanDescription;

  /// No description provided for @reportResolutionFinal.
  ///
  /// In en, this message translates to:
  /// **'Resolving this report is final and revokes access to the evidence.'**
  String get reportResolutionFinal;

  /// No description provided for @reportReportResolved.
  ///
  /// In en, this message translates to:
  /// **'Report resolved'**
  String get reportReportResolved;

  /// No description provided for @reportResolvedBody.
  ///
  /// In en, this message translates to:
  /// **'The report is closed and access to its evidence has been revoked.'**
  String get reportResolvedBody;

  /// No description provided for @reportInvalidTargetError.
  ///
  /// In en, this message translates to:
  /// **'This report target is no longer available.'**
  String get reportInvalidTargetError;

  /// No description provided for @reportMessageRequiredError.
  ///
  /// In en, this message translates to:
  /// **'A reported message is required for this action.'**
  String get reportMessageRequiredError;

  /// No description provided for @reportNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'This report is no longer available.'**
  String get reportNotFoundError;

  /// No description provided for @reportModeratorConflictError.
  ///
  /// In en, this message translates to:
  /// **'You cannot review a report involving your own account.'**
  String get reportModeratorConflictError;

  /// No description provided for @reportAlreadyAssignedError.
  ///
  /// In en, this message translates to:
  /// **'Another moderator has already claimed this report.'**
  String get reportAlreadyAssignedError;

  /// No description provided for @reportClosedError.
  ///
  /// In en, this message translates to:
  /// **'This report has already been closed.'**
  String get reportClosedError;

  /// No description provided for @reportUnsafeBanError.
  ///
  /// In en, this message translates to:
  /// **'This target is not eligible for an account ban.'**
  String get reportUnsafeBanError;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroup;

  /// No description provided for @createChannel.
  ///
  /// In en, this message translates to:
  /// **'Create channel'**
  String get createChannel;

  /// No description provided for @createGroupOrChannel.
  ///
  /// In en, this message translates to:
  /// **'Create group or channel'**
  String get createGroupOrChannel;

  /// No description provided for @discoverCommunities.
  ///
  /// In en, this message translates to:
  /// **'Discover communities'**
  String get discoverCommunities;

  /// No description provided for @universityServices.
  ///
  /// In en, this message translates to:
  /// **'University services'**
  String get universityServices;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @serviceCatalog.
  ///
  /// In en, this message translates to:
  /// **'Service catalog'**
  String get serviceCatalog;

  /// No description provided for @serviceMyRequests.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get serviceMyRequests;

  /// No description provided for @serviceStaffQueue.
  ///
  /// In en, this message translates to:
  /// **'Staff queue'**
  String get serviceStaffQueue;

  /// No description provided for @serviceAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get serviceAvailable;

  /// No description provided for @serviceAssignedToMe.
  ///
  /// In en, this message translates to:
  /// **'Assigned to me'**
  String get serviceAssignedToMe;

  /// No description provided for @serviceSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get serviceSubmitRequest;

  /// No description provided for @serviceNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get serviceNewRequest;

  /// No description provided for @serviceClaimRequest.
  ///
  /// In en, this message translates to:
  /// **'Claim request'**
  String get serviceClaimRequest;

  /// No description provided for @serviceRequestClaimed.
  ///
  /// In en, this message translates to:
  /// **'Request claimed'**
  String get serviceRequestClaimed;

  /// No description provided for @serviceRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get serviceRequestCancelled;

  /// No description provided for @serviceRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get serviceRequestSubmitted;

  /// No description provided for @serviceChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get serviceChangeStatus;

  /// No description provided for @serviceUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update status'**
  String get serviceUpdateStatus;

  /// No description provided for @serviceResultDocument.
  ///
  /// In en, this message translates to:
  /// **'Result document'**
  String get serviceResultDocument;

  /// No description provided for @serviceAssociateResult.
  ///
  /// In en, this message translates to:
  /// **'Attach result document'**
  String get serviceAssociateResult;

  /// No description provided for @serviceReplaceResult.
  ///
  /// In en, this message translates to:
  /// **'Replace result document'**
  String get serviceReplaceResult;

  /// No description provided for @serviceTicketChat.
  ///
  /// In en, this message translates to:
  /// **'Request chat'**
  String get serviceTicketChat;

  /// No description provided for @serviceAddAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get serviceAddAttachment;

  /// No description provided for @serviceRemoveAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get serviceRemoveAttachment;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @serviceTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get serviceTimeline;

  /// No description provided for @serviceRequestDetails.
  ///
  /// In en, this message translates to:
  /// **'Request details'**
  String get serviceRequestDetails;

  /// No description provided for @serviceRequestData.
  ///
  /// In en, this message translates to:
  /// **'Request data'**
  String get serviceRequestData;

  /// No description provided for @serviceRequiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required documents'**
  String get serviceRequiredDocuments;

  /// No description provided for @serviceAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get serviceAssigned;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @serviceEstimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated time: {hours, plural, one{{hours} hour} other{{hours} hours}}'**
  String serviceEstimatedTime(int hours);

  /// No description provided for @serviceOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get serviceOptionalNote;

  /// No description provided for @serviceNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get serviceNote;

  /// No description provided for @serviceEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get serviceEmail;

  /// No description provided for @serviceDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get serviceDate;

  /// No description provided for @serviceFieldIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Field: {identifier}'**
  String serviceFieldIdentifier(String identifier);

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get invalidNumber;

  /// No description provided for @invalidWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid whole number.'**
  String get invalidWholeNumber;

  /// No description provided for @serviceLoadServicesError.
  ///
  /// In en, this message translates to:
  /// **'Could not load services'**
  String get serviceLoadServicesError;

  /// No description provided for @serviceLoadRequestsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load requests'**
  String get serviceLoadRequestsError;

  /// No description provided for @serviceLoadRequestError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this request'**
  String get serviceLoadRequestError;

  /// No description provided for @serviceLoadMessagesError.
  ///
  /// In en, this message translates to:
  /// **'Could not load request messages'**
  String get serviceLoadMessagesError;

  /// No description provided for @serviceNoServices.
  ///
  /// In en, this message translates to:
  /// **'No services are available'**
  String get serviceNoServices;

  /// No description provided for @serviceNoServicesBody.
  ///
  /// In en, this message translates to:
  /// **'New university services will appear here.'**
  String get serviceNoServicesBody;

  /// No description provided for @serviceNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get serviceNoRequests;

  /// No description provided for @serviceNoRequestsBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a service to submit your first request.'**
  String get serviceNoRequestsBody;

  /// No description provided for @serviceNoQueue.
  ///
  /// In en, this message translates to:
  /// **'The queue is clear'**
  String get serviceNoQueue;

  /// No description provided for @serviceNoQueueBody.
  ///
  /// In en, this message translates to:
  /// **'New requests for your department will appear here.'**
  String get serviceNoQueueBody;

  /// No description provided for @serviceNoAssigned.
  ///
  /// In en, this message translates to:
  /// **'No assigned requests'**
  String get serviceNoAssigned;

  /// No description provided for @serviceNoAssignedBody.
  ///
  /// In en, this message translates to:
  /// **'Claim a request from the available queue.'**
  String get serviceNoAssignedBody;

  /// No description provided for @serviceNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No request messages yet'**
  String get serviceNoMessages;

  /// No description provided for @serviceNoMessagesBody.
  ///
  /// In en, this message translates to:
  /// **'Messages between the student and assigned staff appear here.'**
  String get serviceNoMessagesBody;

  /// No description provided for @serviceNoTimeline.
  ///
  /// In en, this message translates to:
  /// **'No timeline events are available.'**
  String get serviceNoTimeline;

  /// No description provided for @serviceNoDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents are attached.'**
  String get serviceNoDocuments;

  /// No description provided for @serviceNoRequestData.
  ///
  /// In en, this message translates to:
  /// **'No additional information was provided.'**
  String get serviceNoRequestData;

  /// No description provided for @serviceFieldHelp.
  ///
  /// In en, this message translates to:
  /// **'Provide the information requested by this service.'**
  String get serviceFieldHelp;

  /// No description provided for @serviceDocumentHelp.
  ///
  /// In en, this message translates to:
  /// **'Upload a file for each required document.'**
  String get serviceDocumentHelp;

  /// No description provided for @serviceReviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Check the information before submitting. You cannot edit a request after submitting it.'**
  String get serviceReviewHelp;

  /// No description provided for @serviceCancellationTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get serviceCancellationTitle;

  /// No description provided for @serviceCancellationBody.
  ///
  /// In en, this message translates to:
  /// **'You can only cancel before a staff member starts processing it.'**
  String get serviceCancellationBody;

  /// No description provided for @serviceCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get serviceCancelRequest;

  /// No description provided for @serviceKeepRequest.
  ///
  /// In en, this message translates to:
  /// **'Keep request'**
  String get serviceKeepRequest;

  /// No description provided for @serviceUnsupportedRole.
  ///
  /// In en, this message translates to:
  /// **'Services are not available for this account role.'**
  String get serviceUnsupportedRole;

  /// No description provided for @serviceUnknownService.
  ///
  /// In en, this message translates to:
  /// **'Unknown service'**
  String get serviceUnknownService;

  /// No description provided for @serviceRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get serviceRequest;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @serviceDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get serviceDraft;

  /// No description provided for @serviceInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get serviceInReview;

  /// No description provided for @serviceNeedsInfo.
  ///
  /// In en, this message translates to:
  /// **'Needs information'**
  String get serviceNeedsInfo;

  /// No description provided for @serviceApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get serviceApproved;

  /// No description provided for @serviceRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get serviceRejected;

  /// No description provided for @serviceReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get serviceReadyForPickup;

  /// No description provided for @serviceDeliveredDigitally.
  ///
  /// In en, this message translates to:
  /// **'Delivered digitally'**
  String get serviceDeliveredDigitally;

  /// No description provided for @serviceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get serviceCompleted;

  /// No description provided for @serviceCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get serviceCancelled;

  /// No description provided for @serviceUnknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown status'**
  String get serviceUnknownStatus;

  /// No description provided for @serviceEventClaimed.
  ///
  /// In en, this message translates to:
  /// **'Request claimed by staff'**
  String get serviceEventClaimed;

  /// No description provided for @serviceEventResultUploaded.
  ///
  /// In en, this message translates to:
  /// **'Result document attached'**
  String get serviceEventResultUploaded;

  /// No description provided for @serviceEventStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed: {status}'**
  String serviceEventStatusChanged(String status);

  /// No description provided for @serviceUnknownEvent.
  ///
  /// In en, this message translates to:
  /// **'Request updated'**
  String get serviceUnknownEvent;

  /// No description provided for @serviceRequestMissing.
  ///
  /// In en, this message translates to:
  /// **'This service request is no longer available.'**
  String get serviceRequestMissing;

  /// No description provided for @serviceTypeMissing.
  ///
  /// In en, this message translates to:
  /// **'This service is no longer available.'**
  String get serviceTypeMissing;

  /// No description provided for @serviceRequirementsMissing.
  ///
  /// In en, this message translates to:
  /// **'Fill in all required fields and upload the required documents.'**
  String get serviceRequirementsMissing;

  /// No description provided for @serviceDocumentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A document or attachment is unavailable. Select the file again.'**
  String get serviceDocumentUnavailable;

  /// No description provided for @serviceAlreadyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Another staff member has already claimed this request.'**
  String get serviceAlreadyAssigned;

  /// No description provided for @serviceInvalidTransition.
  ///
  /// In en, this message translates to:
  /// **'That status change is no longer available. Refresh the request and try again.'**
  String get serviceInvalidTransition;

  /// No description provided for @serviceCannotCancel.
  ///
  /// In en, this message translates to:
  /// **'Processing has started. You can no longer cancel this request.'**
  String get serviceCannotCancel;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get chooseFile;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @pdfDocuments.
  ///
  /// In en, this message translates to:
  /// **'PDF documents'**
  String get pdfDocuments;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @degreeBachelor.
  ///
  /// In en, this message translates to:
  /// **'Bachelor’s'**
  String get degreeBachelor;

  /// No description provided for @degreeMaster.
  ///
  /// In en, this message translates to:
  /// **'Master’s'**
  String get degreeMaster;

  /// No description provided for @degreeDoctorate.
  ///
  /// In en, this message translates to:
  /// **'Doctorate'**
  String get degreeDoctorate;

  /// No description provided for @degreeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get degreeOther;

  /// No description provided for @communityStudentGroup.
  ///
  /// In en, this message translates to:
  /// **'Student group'**
  String get communityStudentGroup;

  /// No description provided for @communityCreateStudentGroup.
  ///
  /// In en, this message translates to:
  /// **'Create student group'**
  String get communityCreateStudentGroup;

  /// No description provided for @communityGroupsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Student groups are unavailable'**
  String get communityGroupsUnavailable;

  /// No description provided for @communityGroupsUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Only students can create student groups.'**
  String get communityGroupsUnavailableBody;

  /// No description provided for @communityChannelsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Channel creation is unavailable'**
  String get communityChannelsUnavailable;

  /// No description provided for @communityChannelsUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Only students and professors can create channels.'**
  String get communityChannelsUnavailableBody;

  /// No description provided for @communityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Communities are unavailable'**
  String get communityUnavailable;

  /// No description provided for @communityUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Only active students and professors can use communities.'**
  String get communityUnavailableBody;

  /// No description provided for @communityCreate.
  ///
  /// In en, this message translates to:
  /// **'Create community'**
  String get communityCreate;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get enterName;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @publicVisibility.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicVisibility;

  /// No description provided for @privateVisibility.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privateVisibility;

  /// No description provided for @handleOptional.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get handleOptional;

  /// No description provided for @communityHandleRequired.
  ///
  /// In en, this message translates to:
  /// **'Public communities need a username.'**
  String get communityHandleRequired;

  /// No description provided for @communityProfessorChannel.
  ///
  /// In en, this message translates to:
  /// **'Professor channel'**
  String get communityProfessorChannel;

  /// No description provided for @communityProfessorChannelHelp.
  ///
  /// In en, this message translates to:
  /// **'This channel will appear under Professor channels.'**
  String get communityProfessorChannelHelp;

  /// No description provided for @communityJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get communityJoin;

  /// No description provided for @communityJoinWithInvite.
  ///
  /// In en, this message translates to:
  /// **'Join with an invite'**
  String get communityJoinWithInvite;

  /// No description provided for @communityInviteToken.
  ///
  /// In en, this message translates to:
  /// **'Invite token'**
  String get communityInviteToken;

  /// No description provided for @communityPasteInvite.
  ///
  /// In en, this message translates to:
  /// **'Paste an invite token'**
  String get communityPasteInvite;

  /// No description provided for @communitySearch.
  ///
  /// In en, this message translates to:
  /// **'Search names and usernames'**
  String get communitySearch;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @communityAllPublic.
  ///
  /// In en, this message translates to:
  /// **'All public'**
  String get communityAllPublic;

  /// No description provided for @communityProfessorChannels.
  ///
  /// In en, this message translates to:
  /// **'Professor channels'**
  String get communityProfessorChannels;

  /// No description provided for @communityLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load communities'**
  String get communityLoadError;

  /// No description provided for @communityNotFoundList.
  ///
  /// In en, this message translates to:
  /// **'No communities found'**
  String get communityNotFoundList;

  /// No description provided for @communityNoPublic.
  ///
  /// In en, this message translates to:
  /// **'There are no public communities in this category yet.'**
  String get communityNoPublic;

  /// No description provided for @communityNoMatches.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or username.'**
  String get communityNoMatches;

  /// No description provided for @communityJoined.
  ///
  /// In en, this message translates to:
  /// **'You joined {name}.'**
  String communityJoined(String name);

  /// No description provided for @communityInfo.
  ///
  /// In en, this message translates to:
  /// **'Community info'**
  String get communityInfo;

  /// No description provided for @communityUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Conversation under review'**
  String get communityUnderReview;

  /// No description provided for @communityUnderReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Some actions may be limited while a report is reviewed.'**
  String get communityUnderReviewBody;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @communityDetailsAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Details and settings'**
  String get communityDetailsAndSettings;

  /// No description provided for @communityInviteLinks.
  ///
  /// In en, this message translates to:
  /// **'Invite links'**
  String get communityInviteLinks;

  /// No description provided for @communityReport.
  ///
  /// In en, this message translates to:
  /// **'Report community'**
  String get communityReport;

  /// No description provided for @communityDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete community'**
  String get communityDelete;

  /// No description provided for @communityLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave community'**
  String get communityLeave;

  /// No description provided for @communityLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {name}?'**
  String communityLeaveTitle(String name);

  /// No description provided for @communityLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to join again to see new messages.'**
  String get communityLeaveBody;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @communityDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String communityDeleteTitle(String name);

  /// No description provided for @communityDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes the community and its conversation.'**
  String get communityDeleteBody;

  /// No description provided for @communityLoadOneError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this community'**
  String get communityLoadOneError;

  /// No description provided for @communityJoinAction.
  ///
  /// In en, this message translates to:
  /// **'Join community'**
  String get communityJoinAction;

  /// No description provided for @communityCannotJoin.
  ///
  /// In en, this message translates to:
  /// **'You cannot join this community'**
  String get communityCannotJoin;

  /// No description provided for @communityChatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Conversation unavailable'**
  String get communityChatUnavailable;

  /// No description provided for @communityOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open conversation'**
  String get communityOpenChat;

  /// No description provided for @communityDetails.
  ///
  /// In en, this message translates to:
  /// **'Community details'**
  String get communityDetails;

  /// No description provided for @communitySaveDetails.
  ///
  /// In en, this message translates to:
  /// **'Save details'**
  String get communitySaveDetails;

  /// No description provided for @communityDetailsSaved.
  ///
  /// In en, this message translates to:
  /// **'Community details saved.'**
  String get communityDetailsSaved;

  /// No description provided for @communityConversationSettings.
  ///
  /// In en, this message translates to:
  /// **'Conversation settings'**
  String get communityConversationSettings;

  /// No description provided for @communitySlowMode.
  ///
  /// In en, this message translates to:
  /// **'Slow mode (seconds)'**
  String get communitySlowMode;

  /// No description provided for @communitySlowModeHelp.
  ///
  /// In en, this message translates to:
  /// **'Use 0 to turn slow mode off.'**
  String get communitySlowModeHelp;

  /// No description provided for @communitySlowModeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 0 to 86,400 seconds.'**
  String get communitySlowModeInvalid;

  /// No description provided for @communityMembersCanPost.
  ///
  /// In en, this message translates to:
  /// **'Members can post'**
  String get communityMembersCanPost;

  /// No description provided for @communityMembersCanPostHelp.
  ///
  /// In en, this message translates to:
  /// **'Allow regular members to send messages.'**
  String get communityMembersCanPostHelp;

  /// No description provided for @communityMembersCanInvite.
  ///
  /// In en, this message translates to:
  /// **'Members can invite'**
  String get communityMembersCanInvite;

  /// No description provided for @communityMembersCanInviteHelp.
  ///
  /// In en, this message translates to:
  /// **'Allow members to share invite links.'**
  String get communityMembersCanInviteHelp;

  /// No description provided for @communityCommentsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Comments enabled'**
  String get communityCommentsEnabled;

  /// No description provided for @communityCommentsEnabledHelp.
  ///
  /// In en, this message translates to:
  /// **'Allow discussion on channel posts.'**
  String get communityCommentsEnabledHelp;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveSettings;

  /// No description provided for @communitySettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Community settings saved.'**
  String get communitySettingsSaved;

  /// No description provided for @communityAddMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get communityAddMember;

  /// No description provided for @communityLoadMembersError.
  ///
  /// In en, this message translates to:
  /// **'Could not load members'**
  String get communityLoadMembersError;

  /// No description provided for @communityNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get communityNoMembers;

  /// No description provided for @communityNoMembersBody.
  ///
  /// In en, this message translates to:
  /// **'No active members were found.'**
  String get communityNoMembersBody;

  /// No description provided for @communityManageMember.
  ///
  /// In en, this message translates to:
  /// **'Manage member'**
  String get communityManageMember;

  /// No description provided for @communityOwnerRole.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get communityOwnerRole;

  /// No description provided for @communityAdminRole.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get communityAdminRole;

  /// No description provided for @communityMemberRole.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get communityMemberRole;

  /// No description provided for @communitySubscriberRole.
  ///
  /// In en, this message translates to:
  /// **'Subscriber'**
  String get communitySubscriberRole;

  /// No description provided for @communityBannedRole.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get communityBannedRole;

  /// No description provided for @communityPromoteMember.
  ///
  /// In en, this message translates to:
  /// **'Promote to administrator'**
  String get communityPromoteMember;

  /// No description provided for @communityDemoteMember.
  ///
  /// In en, this message translates to:
  /// **'Remove administrator role'**
  String get communityDemoteMember;

  /// No description provided for @communityBanMember.
  ///
  /// In en, this message translates to:
  /// **'Ban member'**
  String get communityBanMember;

  /// No description provided for @ban.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get ban;

  /// No description provided for @communityRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get communityRemoveMember;

  /// No description provided for @communityBanMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Ban {name}?'**
  String communityBanMemberTitle(String name);

  /// No description provided for @communityRemoveMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String communityRemoveMemberTitle(String name);

  /// No description provided for @communityBanMemberBody.
  ///
  /// In en, this message translates to:
  /// **'They will be removed and will not be able to rejoin.'**
  String get communityBanMemberBody;

  /// No description provided for @communityRemoveMemberBody.
  ///
  /// In en, this message translates to:
  /// **'They will be removed from this community.'**
  String get communityRemoveMemberBody;

  /// No description provided for @communityMemberPromoted.
  ///
  /// In en, this message translates to:
  /// **'Member promoted to administrator.'**
  String get communityMemberPromoted;

  /// No description provided for @communityMemberDemoted.
  ///
  /// In en, this message translates to:
  /// **'Administrator role removed.'**
  String get communityMemberDemoted;

  /// No description provided for @communityMemberBanned.
  ///
  /// In en, this message translates to:
  /// **'Member banned.'**
  String get communityMemberBanned;

  /// No description provided for @communityMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed.'**
  String get communityMemberRemoved;

  /// No description provided for @communityMemberAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} was added.'**
  String communityMemberAdded(String name);

  /// No description provided for @communityInviteCreated.
  ///
  /// In en, this message translates to:
  /// **'Invite link created'**
  String get communityInviteCreated;

  /// No description provided for @communityCopyInviteHelp.
  ///
  /// In en, this message translates to:
  /// **'Copy this token now. It will not be shown again.'**
  String get communityCopyInviteHelp;

  /// No description provided for @communityInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite token copied.'**
  String get communityInviteCopied;

  /// No description provided for @communityRevokeInvite.
  ///
  /// In en, this message translates to:
  /// **'Revoke invite'**
  String get communityRevokeInvite;

  /// No description provided for @communityRevokeInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke this invite?'**
  String get communityRevokeInviteTitle;

  /// No description provided for @communityRevokeInviteBody.
  ///
  /// In en, this message translates to:
  /// **'This invite will stop working immediately.'**
  String get communityRevokeInviteBody;

  /// No description provided for @communityInviteRevoked.
  ///
  /// In en, this message translates to:
  /// **'Invite revoked.'**
  String get communityInviteRevoked;

  /// No description provided for @communityCreateInvite.
  ///
  /// In en, this message translates to:
  /// **'Create invite link'**
  String get communityCreateInvite;

  /// No description provided for @communityLoadInvitesError.
  ///
  /// In en, this message translates to:
  /// **'Could not load invites'**
  String get communityLoadInvitesError;

  /// No description provided for @communityNoInvites.
  ///
  /// In en, this message translates to:
  /// **'No invite links'**
  String get communityNoInvites;

  /// No description provided for @communityNoInvitesBody.
  ///
  /// In en, this message translates to:
  /// **'Create an invite for this community.'**
  String get communityNoInvitesBody;

  /// No description provided for @communityActiveInvite.
  ///
  /// In en, this message translates to:
  /// **'Active invite'**
  String get communityActiveInvite;

  /// No description provided for @communityRevokedInvite.
  ///
  /// In en, this message translates to:
  /// **'Revoked invite'**
  String get communityRevokedInvite;

  /// No description provided for @communityExpiredInvite.
  ///
  /// In en, this message translates to:
  /// **'Expired invite'**
  String get communityExpiredInvite;

  /// No description provided for @communityUsedInvite.
  ///
  /// In en, this message translates to:
  /// **'Used invite'**
  String get communityUsedInvite;

  /// No description provided for @communityExpiresAfter.
  ///
  /// In en, this message translates to:
  /// **'Expires after'**
  String get communityExpiresAfter;

  /// No description provided for @communityExpiryOneDay.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get communityExpiryOneDay;

  /// No description provided for @communityExpiryOneWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get communityExpiryOneWeek;

  /// No description provided for @communityExpiryThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get communityExpiryThirtyDays;

  /// No description provided for @communityNeverExpires.
  ///
  /// In en, this message translates to:
  /// **'No expiry'**
  String get communityNeverExpires;

  /// No description provided for @communityMaxUses.
  ///
  /// In en, this message translates to:
  /// **'Maximum uses (optional)'**
  String get communityMaxUses;

  /// No description provided for @communityMaxUsesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 10,000.'**
  String get communityMaxUsesInvalid;

  /// No description provided for @communityInviteUses.
  ///
  /// In en, this message translates to:
  /// **'{uses, plural, one{{uses} use} other{{uses} uses}}'**
  String communityInviteUses(int uses);

  /// No description provided for @communityInviteUsesOf.
  ///
  /// In en, this message translates to:
  /// **'{uses} of {maxUses} uses'**
  String communityInviteUsesOf(int uses, int maxUses);

  /// No description provided for @communityInviteExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String communityInviteExpires(String date);

  /// No description provided for @communityInvalidHandle.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid username.'**
  String get communityInvalidHandle;

  /// No description provided for @communityHandleTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already in use.'**
  String get communityHandleTaken;

  /// No description provided for @communityInvalidGroupMember.
  ///
  /// In en, this message translates to:
  /// **'Only students can join student groups.'**
  String get communityInvalidGroupMember;

  /// No description provided for @communityRejoinDenied.
  ///
  /// In en, this message translates to:
  /// **'This account cannot rejoin the community.'**
  String get communityRejoinDenied;

  /// No description provided for @communityMissing.
  ///
  /// In en, this message translates to:
  /// **'This community is no longer available.'**
  String get communityMissing;

  /// No description provided for @communityInviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'This invite is invalid or has expired.'**
  String get communityInviteInvalid;

  /// No description provided for @communityUserMissing.
  ///
  /// In en, this message translates to:
  /// **'No user was found with that username.'**
  String get communityUserMissing;

  /// No description provided for @communityAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'This user is already a member.'**
  String get communityAlreadyMember;

  /// No description provided for @communityOwnerCannotLeave.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership or delete the community before leaving.'**
  String get communityOwnerCannotLeave;

  /// No description provided for @communityMemberMissing.
  ///
  /// In en, this message translates to:
  /// **'This person is no longer a member.'**
  String get communityMemberMissing;

  /// No description provided for @communityInvalidMemberRole.
  ///
  /// In en, this message translates to:
  /// **'That role is not available for this community.'**
  String get communityInvalidMemberRole;

  /// No description provided for @communityDmUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This action is unavailable in direct messages.'**
  String get communityDmUnavailable;

  /// No description provided for @communityOfficialDescription.
  ///
  /// In en, this message translates to:
  /// **'Official channel for {name}'**
  String communityOfficialDescription(String name);

  /// No description provided for @mediaInvalidSize.
  ///
  /// In en, this message translates to:
  /// **'Choose a non-empty file of 25 MB or less.'**
  String get mediaInvalidSize;

  /// No description provided for @mediaUnsupportedType.
  ///
  /// In en, this message translates to:
  /// **'Choose a supported file type.'**
  String get mediaUnsupportedType;

  /// No description provided for @mediaInvalidContent.
  ///
  /// In en, this message translates to:
  /// **'The file does not match its format. Choose another file.'**
  String get mediaInvalidContent;

  /// No description provided for @chatDemoStudy.
  ///
  /// In en, this message translates to:
  /// **'Study Group · Algorithms'**
  String get chatDemoStudy;

  /// No description provided for @chatDemoProfessor.
  ///
  /// In en, this message translates to:
  /// **'Professor Rahimi · Data Structures'**
  String get chatDemoProfessor;

  /// No description provided for @chatDemoSara.
  ///
  /// In en, this message translates to:
  /// **'Sara Ahmadi'**
  String get chatDemoSara;

  /// No description provided for @chatDemoStudyOne.
  ///
  /// In en, this message translates to:
  /// **'Does anyone want to review dynamic programming today?'**
  String get chatDemoStudyOne;

  /// No description provided for @chatDemoStudyTwo.
  ///
  /// In en, this message translates to:
  /// **'Yes, after the 2 PM lecture works for me.'**
  String get chatDemoStudyTwo;

  /// No description provided for @chatDemoStudyThree.
  ///
  /// In en, this message translates to:
  /// **'I uploaded the practice set.'**
  String get chatDemoStudyThree;

  /// No description provided for @chatDemoProfessorOne.
  ///
  /// In en, this message translates to:
  /// **'The week six slides are now available.'**
  String get chatDemoProfessorOne;

  /// No description provided for @chatDemoProfessorTwo.
  ///
  /// In en, this message translates to:
  /// **'Office hours moved to 14:30.'**
  String get chatDemoProfessorTwo;

  /// No description provided for @chatDemoSaraPreview.
  ///
  /// In en, this message translates to:
  /// **'See you at the library.'**
  String get chatDemoSaraPreview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
