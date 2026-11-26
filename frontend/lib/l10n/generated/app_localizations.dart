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
  /// **'فارسی'**
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

  /// No description provided for @statusStep.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get statusStep;

  /// No description provided for @themeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change theme'**
  String get themeTooltip;

  /// No description provided for @languageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get languageTooltip;

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
  /// **'{count} members'**
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
