// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'پیام‌رسان دانشگاه';

  @override
  String get appDescription =>
      'پیام‌رسانی با هویت تأییدشده، خدمات دانشگاهی و کانال‌های آموزشی.';

  @override
  String get enableAccessibility => 'فعال‌کردن دسترس‌پذیری';

  @override
  String get welcomeTitle => 'دانشگاه شما، در یک گفت‌وگو';

  @override
  String get welcomeBody =>
      'با هویت تأییدشده دانشگاهی به همکلاسی‌ها و استادان پیام بدهید.';

  @override
  String get continueLabel => 'ادامه';

  @override
  String get persian => 'فارسی';

  @override
  String get english => 'انگلیسی';

  @override
  String get phoneTitle => 'شماره تلفن خود را وارد کنید';

  @override
  String get phoneBody => 'برای تأیید این شماره، یک کد شش‌رقمی می‌فرستیم.';

  @override
  String get phoneLabel => 'شماره همراه';

  @override
  String get phoneHint => '۹۱۲ ۱۲۳ ۴۵۶۷';

  @override
  String get sendCode => 'ارسال کد';

  @override
  String get invalidPhone => 'یک شماره همراه معتبر ایرانی وارد کنید.';

  @override
  String get termsNote =>
      'با ادامه، تأیید می‌کنید که این شماره متعلق به شماست.';

  @override
  String get otpTitle => 'پیامک‌های خود را بررسی کنید';

  @override
  String otpBody(String phone) {
    return 'کد ارسال‌شده به $phone را وارد کنید.';
  }

  @override
  String get codeLabel => 'کد تأیید';

  @override
  String get verify => 'تأیید';

  @override
  String resendIn(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'ارسال دوباره تا $secondsString ثانیه';
  }

  @override
  String get resendCode => 'ارسال دوباره کد';

  @override
  String developmentCode(String code) {
    return 'کد محیط توسعه: $code';
  }

  @override
  String get invalidCode => 'کد شش‌رقمی کامل را وارد کنید.';

  @override
  String get changePhone => 'تغییر شماره تلفن';

  @override
  String get studentProfileTitle => 'پروفایل دانشجویی خود را کامل کنید';

  @override
  String get studentProfileBody =>
      'این اطلاعات پیش از فعال‌شدن پیام‌رسان توسط دانشگاه بررسی می‌شود.';

  @override
  String get professorProfileTitle => 'پروفایل استادی خود را تأیید کنید';

  @override
  String get professorProfileBody =>
      'دعوت‌نامه شما این حساب را به‌عنوان استاد ثبت کرده است.';

  @override
  String get firstName => 'نام';

  @override
  String get lastName => 'نام خانوادگی';

  @override
  String get nationalId => 'کد ملی';

  @override
  String get nationalIdHint => '۱۰ رقم';

  @override
  String get degree => 'مقطع تحصیلی';

  @override
  String get department => 'دانشکده یا گروه';

  @override
  String get universityId => 'شماره دانشجویی';

  @override
  String get academicTitle => 'عنوان علمی';

  @override
  String get next => 'بررسی اطلاعات';

  @override
  String get requiredField => 'تکمیل این بخش الزامی است.';

  @override
  String get invalidNationalId => 'یک کد ملی معتبر وارد کنید.';

  @override
  String get reviewTitle => 'اطلاعات خود را بررسی کنید';

  @override
  String get studentReviewBody =>
      'مطمئن شوید اطلاعات با پرونده دانشگاهی شما مطابقت دارد.';

  @override
  String get professorReviewBody =>
      'نحوه نمایش پروفایل خود به دانشجویان را تأیید کنید.';

  @override
  String get edit => 'ویرایش';

  @override
  String get submitForReview => 'ارسال برای بررسی';

  @override
  String get activateProfile => 'فعال‌کردن پروفایل';

  @override
  String get pendingTitle => 'پروفایل شما در حال بررسی است';

  @override
  String get pendingBody =>
      'برای دیدن نتیجه بررسی دانشگاه، دوباره به این صفحه برگردید.';

  @override
  String get submitted => 'ارسال شد';

  @override
  String get underReview => 'بررسی دانشگاه';

  @override
  String get decision => 'دسترسی پیام‌رسان';

  @override
  String get refreshStatus => 'بررسی وضعیت';

  @override
  String get checking => 'در حال بررسی…';

  @override
  String get lastChecked => 'همین حالا بررسی شد';

  @override
  String get logout => 'خروج از حساب';

  @override
  String get rejectedTitle => 'اطلاعات شما نیاز به اصلاح دارد';

  @override
  String get rejectedBody =>
      'اطلاعات را بررسی و دوباره ارسال کنید. در صورت نیاز، دانشگاه با شما تماس می‌گیرد.';

  @override
  String get correctSubmission => 'بررسی و ارسال دوباره';

  @override
  String get correctionTitle => 'اصلاح اطلاعات درخواست شده است';

  @override
  String get correctionBody =>
      'اطلاعات خواسته‌شده را به‌روز و پروفایل را دوباره ارسال کنید.';

  @override
  String get blockedTitle => 'این حساب در دسترس نیست';

  @override
  String get blockedBody =>
      'حساب شما تعلیق یا مسدود شده است. با مدیر سامانه دانشگاه تماس بگیرید.';

  @override
  String get homeTitle => 'هویت شما تأیید شد';

  @override
  String get homeBody =>
      'حساب شما فعال است. گفت‌وگوها در مرحله بعدی محصول اینجا نمایش داده می‌شوند.';

  @override
  String get phoneStep => 'تلفن';

  @override
  String get verifyStep => 'تأیید';

  @override
  String get profileStep => 'پروفایل';

  @override
  String get reviewStep => 'بازبینی';

  @override
  String verificationProgress(String step, int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$step، مرحلهٔ $currentString از $totalString';
  }

  @override
  String get statusStep => 'دسترسی';

  @override
  String get tryAgain => 'تلاش دوباره';

  @override
  String get genericError =>
      'مشکلی پیش آمد. اتصال اینترنت را بررسی و دوباره تلاش کنید.';

  @override
  String get otpExpired => 'زمان این کد تمام شده است. کد جدیدی بگیرید.';

  @override
  String get otpIncorrect => 'این کد درست نیست.';

  @override
  String get otpLocked => 'تعداد تلاش‌ها بیش از حد بود. کد جدیدی بگیرید.';

  @override
  String get otpRateLimited =>
      'تعداد درخواست کد زیاد است. کمی صبر و دوباره تلاش کنید.';

  @override
  String get profileExists =>
      'این هویت قبلاً ثبت شده است. با مدیر دانشگاه تماس بگیرید.';

  @override
  String get sessionExpired =>
      'نشست شما منقضی شد. شماره تلفن را دوباره تأیید کنید.';

  @override
  String get chats => 'گفت‌وگوها';

  @override
  String get searchChats => 'جست‌وجوی گفت‌وگو و پیام';

  @override
  String get noChats => 'هنوز گفت‌وگویی ندارید';

  @override
  String get noChatsBody =>
      'گفت‌وگوهای جدید پس از ایجاد در اینجا نمایش داده می‌شوند.';

  @override
  String get noSearchResults => 'گفت‌وگو یا پیام مرتبطی پیدا نشد';

  @override
  String get newMessage => 'پیام جدید';

  @override
  String get messageHint => 'پیام';

  @override
  String get sendMessage => 'ارسال پیام';

  @override
  String get typing => 'در حال نوشتن…';

  @override
  String membersCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString عضو';
  }

  @override
  String get channel => 'کانال';

  @override
  String get group => 'گروه';

  @override
  String get directMessage => 'گفت‌وگوی خصوصی';

  @override
  String get messageFailed => 'ارسال نشد · برای تلاش دوباره بزنید';

  @override
  String get messageSending => 'در حال ارسال';

  @override
  String get edited => 'ویرایش‌شده';

  @override
  String get loadEarlier => 'نمایش پیام‌های قدیمی‌تر';

  @override
  String get selectConversation =>
      'برای شروع پیام‌رسانی یک گفت‌وگو را انتخاب کنید';

  @override
  String get today => 'امروز';

  @override
  String get yesterday => 'دیروز';

  @override
  String get justNow => 'اکنون';

  @override
  String get syncError =>
      'به‌روزرسانی گفت‌وگوها انجام نشد. پیام‌های ذخیره‌شده نمایش داده می‌شوند.';

  @override
  String get retry => 'تلاش دوباره';

  @override
  String get adminPanel => 'پنل مدیریت';

  @override
  String get superAdminPanel => 'پنل مدیر ارشد';

  @override
  String get studentRequests => 'درخواست‌های ثبت‌نام دانشجویان';

  @override
  String get noStudentRequests => 'درخواست ثبت‌نامی در انتظار بررسی نیست.';

  @override
  String get approveStudent => 'تأیید';

  @override
  String get studentApproved => 'ثبت‌نام تأیید شد. حساب دانشجو اکنون فعال است.';

  @override
  String get requestAlreadyReviewed => 'این درخواست دیگر در انتظار بررسی نیست.';

  @override
  String get addAdmin => 'افزودن مدیر';

  @override
  String get createAdmin => 'ایجاد حساب مدیر';

  @override
  String get newAdminHint =>
      'شماره همراهی وارد کنید که قبلاً ثبت نشده باشد. این مدیر می‌تواند دانشجویان را تأیید کند، اما نمی‌تواند مدیر دیگری اضافه کند.';

  @override
  String get adminCreated => 'مدیر اضافه شد و می‌تواند با کد پیامکی وارد شود.';

  @override
  String get phoneAlreadyRegistered =>
      'این شماره قبلاً برای حساب دیگری ثبت شده است.';

  @override
  String get adminAccessRequired =>
      'دسترسی به این بخش به حساب مدیر فعال نیاز دارد.';

  @override
  String get refreshRequests => 'به‌روزرسانی درخواست‌ها';

  @override
  String get myProfile => 'پروفایل من';

  @override
  String get changePhoto => 'تغییر عکس پروفایل';

  @override
  String get removePhoto => 'حذف عکس';

  @override
  String get photoUpdateError =>
      'عکس به‌روزرسانی نشد. یک تصویر جی‌پی‌جی، پی‌ان‌جی یا وب‌پی تا ۲۵ مگابایت انتخاب کنید و دوباره تلاش کنید.';

  @override
  String get photoRemoveError => 'عکس پروفایل حذف نشد. دوباره تلاش کنید.';

  @override
  String get username => 'نام کاربری';

  @override
  String get messengerId => 'شناسه پیام‌رسان';

  @override
  String get copyId => 'کپی شناسه';

  @override
  String get findById => 'جست‌وجو با شناسه';

  @override
  String get searchIdHint =>
      'دست‌کم دو حرف از نام کاربری یا شناسه کامل پیام‌رسان را وارد کنید.';

  @override
  String get noIdMatches => 'کاربر، گروه یا کانالی پیدا نشد.';

  @override
  String get directorySearchRateLimited =>
      'تعداد جست‌وجوها بیش از حد مجاز است. کمی صبر کنید و دوباره تلاش کنید.';

  @override
  String get settings => 'تنظیمات';

  @override
  String get language => 'زبان';

  @override
  String get appearance => 'ظاهر';

  @override
  String get systemTheme => 'پیش‌فرض دستگاه';

  @override
  String get systemThemeDescription =>
      'از حالت روشن یا تیرهٔ دستگاه پیروی می‌کند.';

  @override
  String get lightTheme => 'روشن';

  @override
  String get darkTheme => 'تیره';

  @override
  String get settingsSaveError =>
      'تنظیمات ذخیره نشد. برای تلاش دوباره یک گزینه انتخاب کنید.';

  @override
  String get pageNotFound => 'صفحه پیدا نشد';

  @override
  String get back => 'بازگشت';

  @override
  String get cancel => 'لغو';

  @override
  String get close => 'بستن';

  @override
  String get dismiss => 'بستن پیام';

  @override
  String get refresh => 'به‌روزرسانی';

  @override
  String get create => 'ایجاد';

  @override
  String get open => 'باز کردن';

  @override
  String get delete => 'حذف';

  @override
  String get remove => 'حذف';

  @override
  String get done => 'انجام شد';

  @override
  String get copy => 'کپی';

  @override
  String get add => 'افزودن';

  @override
  String get unknown => 'نامشخص';

  @override
  String get networkError =>
      'اتصال به سرور برقرار نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get invalidForm => 'اطلاعات واردشده را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get forbiddenError => 'اجازهٔ انجام این کار را ندارید.';

  @override
  String get callHistory => 'تاریخچهٔ تماس‌ها';

  @override
  String get callNoCalls => 'هنوز تماسی ندارید';

  @override
  String get callNoCallsBody =>
      'تماس‌های ورودی و خروجی شما اینجا نمایش داده می‌شوند.';

  @override
  String get callAudioCall => 'تماس صوتی';

  @override
  String get callVideoCall => 'تماس تصویری';

  @override
  String get callIncomingAudioCall => 'تماس صوتی ورودی';

  @override
  String get callIncomingVideoCall => 'تماس تصویری ورودی';

  @override
  String get callUnknownCaller => 'تماس‌گیرندهٔ ناشناس';

  @override
  String get callIncoming => 'تماس ورودی';

  @override
  String get callActive => 'تماس جاری';

  @override
  String get callReturn => 'بازگشت به تماس';

  @override
  String get callOutgoingCall => 'تماس خروجی';

  @override
  String get callCalling => 'در حال تماس…';

  @override
  String get callRinging => 'در حال زنگ خوردن…';

  @override
  String get callConnecting => 'در حال برقراری اتصال امن…';

  @override
  String get callReconnecting => 'در حال اتصال دوباره…';

  @override
  String get callConnected => 'متصل شد';

  @override
  String get callWaitingForAnswer => 'در انتظار پاسخ';

  @override
  String get callCallEnded => 'تماس پایان یافت';

  @override
  String get callDeclined => 'رد شد';

  @override
  String get callMissed => 'بی‌پاسخ';

  @override
  String get callAnswer => 'پاسخ';

  @override
  String get callDecline => 'رد تماس';

  @override
  String get callEndCall => 'پایان تماس';

  @override
  String get callMicrophoneOn => 'قطع صدای میکروفون';

  @override
  String get callMicrophoneOff => 'وصل کردن صدای میکروفون';

  @override
  String get callSpeakerOn => 'پخش از بلندگوی گوشی';

  @override
  String get callSpeakerOff => 'پخش از بلندگوی اصلی';

  @override
  String get callCameraOn => 'خاموش کردن دوربین';

  @override
  String get callCameraOff => 'روشن کردن دوربین';

  @override
  String get callSwitchCamera => 'تعویض دوربین';

  @override
  String get callWaitingForVideo => 'در انتظار تصویر';

  @override
  String get callIncomingCallEnded => 'این تماس دیگر زنگ نمی‌خورد.';

  @override
  String get callCallUnavailable => 'تماس در دسترس نیست';

  @override
  String get callCallInProgress => 'تماس دیگری در جریان است.';

  @override
  String get callDirectCallsOnly =>
      'تماس فقط در گفت‌وگوهای خصوصی در دسترس است.';

  @override
  String get callDirectCallUnavailable => 'تماس در این گفت‌وگو ممکن نیست.';

  @override
  String get callMediaConnectionError =>
      'صدا یا تصویر تماس برقرار نشد. مجوزهای دستگاه را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get callMediaDeviceError =>
      'تنظیم دستگاه تغییر نکرد. مجوزهای دستگاه را بررسی کنید.';

  @override
  String get callActiveCallRequired => 'تماس قبلاً پایان یافته است.';

  @override
  String callIdentity(String name, String status) {
    return '$name، $status';
  }

  @override
  String dateAndTime(String date, String time) {
    return '$date، $time';
  }

  @override
  String get chatNavigation => 'باز کردن منو';

  @override
  String get savedMessages => 'پیام‌های ذخیره‌شده';

  @override
  String get messageDeleted => 'پیام حذف شد';

  @override
  String get photo => 'عکس';

  @override
  String get video => 'ویدیو';

  @override
  String get voiceMessage => 'پیام صوتی';

  @override
  String get audio => 'صدا';

  @override
  String get file => 'فایل';

  @override
  String get document => 'مدرک';

  @override
  String get album => 'آلبوم';

  @override
  String get poll => 'نظرسنجی';

  @override
  String get sticker => 'برچسب';

  @override
  String get gif => 'گیف';

  @override
  String get attachment => 'پیوست';

  @override
  String get attach => 'افزودن پیوست';

  @override
  String get media => 'رسانه';

  @override
  String get profilePhoto => 'عکس پروفایل';

  @override
  String get retryImage => 'تلاش دوباره برای بارگیری تصویر';

  @override
  String get retryAttachment => 'تلاش دوباره برای بارگیری پیوست';

  @override
  String get imageAttachment => 'تصویر پیوست‌شده';

  @override
  String get download => 'بارگیری';

  @override
  String mediaSavedTo(String path) {
    return 'در این مسیر ذخیره شد: $path';
  }

  @override
  String get mediaSaveFailed => 'پیوست ذخیره نشد. دوباره تلاش کنید.';

  @override
  String get mediaPlaybackUnavailable =>
      'پخش ممکن نیست. پیوست را بارگیری کنید.';

  @override
  String get mediaFormatUnavailable =>
      'این دستگاه نمی‌تواند این قالب را پخش کند. می‌توانید پیوست را بارگیری کنید.';

  @override
  String get mediaPlay => 'پخش';

  @override
  String get mediaPause => 'مکث';

  @override
  String mediaBytes(String size) {
    return '$size بایت';
  }

  @override
  String mediaKilobytes(String size) {
    return '$size کیلوبایت';
  }

  @override
  String mediaMegabytes(String size) {
    return '$size مگابایت';
  }

  @override
  String get chatAttachmentLimit => 'برای هر پیام حداکثر ۱۰ پیوست انتخاب کنید.';

  @override
  String get chatUploadFailed =>
      'بارگذاری انجام نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get chatCreatePoll => 'ایجاد نظرسنجی';

  @override
  String get chatPollQuestion => 'پرسش';

  @override
  String chatPollOption(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'گزینهٔ $numberString';
  }

  @override
  String chatPollVotes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString رأی';
  }

  @override
  String get chatStickerLoadError => 'برچسب‌ها و گیف‌ها بارگیری نشدند.';

  @override
  String get chatEmoji => 'شکلک';

  @override
  String get chatStickers => 'برچسب‌ها';

  @override
  String get chatGifs => 'گیف‌ها';

  @override
  String get chatAddSticker => 'افزودن برچسب';

  @override
  String get chatAddGif => 'افزودن گیف';

  @override
  String get chatSendStickerError =>
      'برچسب یا گیف ارسال نشد. دوباره تلاش کنید.';

  @override
  String get chatForwardTo => 'بازفرستادن به';

  @override
  String get chatForwardAdded => 'پیام به گفت‌وگو بازفرستاده شد';

  @override
  String get chatForwardFailed => 'پیام بازفرستاده نشد. دوباره تلاش کنید.';

  @override
  String get chatNoPinned => 'پیام سنجاق‌شده‌ای وجود ندارد';

  @override
  String get chatFavoriteSticker => 'افزودن برچسب به علاقه‌مندی‌ها';

  @override
  String get chatStickerFavorited => 'برچسب به علاقه‌مندی‌ها اضافه شد.';

  @override
  String get chatFavoriteFailed => 'برچسب به علاقه‌مندی‌ها اضافه نشد.';

  @override
  String get chatSaveGif => 'ذخیرهٔ گیف';

  @override
  String get chatGifSaved => 'گیف در مجموعهٔ شما ذخیره شد.';

  @override
  String get chatGifSaveFailed => 'گیف ذخیره نشد.';

  @override
  String get chatReply => 'پاسخ';

  @override
  String get chatReact => 'واکنش';

  @override
  String chatReactWith(String emoji) {
    return 'واکنش با $emoji';
  }

  @override
  String get chatForward => 'بازفرستادن';

  @override
  String get chatPinMessage => 'سنجاق کردن پیام';

  @override
  String get chatUnpinMessage => 'برداشتن سنجاق پیام';

  @override
  String get chatConversationInfo => 'اطلاعات گفت‌وگو';

  @override
  String get chatPinnedMessages => 'پیام‌های سنجاق‌شده';

  @override
  String get chatForwardedMessage => 'پیام بازفرستاده‌شده';

  @override
  String chatForwardedFrom(String name) {
    return 'بازفرستاده‌شده از $name';
  }

  @override
  String get chatViewOriginal => 'دیدن پیام اصلی';

  @override
  String get chatOriginalMessage => 'پیام اصلی';

  @override
  String get chatOriginalUnavailable => 'پیام اصلی در دسترس نیست.';

  @override
  String get chatNoStickers => 'برچسبی نصب نشده است';

  @override
  String get chatNoGifs => 'گیف ذخیره‌شده‌ای وجود ندارد';

  @override
  String get chatEditingMessage => 'در حال ویرایش پیام';

  @override
  String get chatMessageSent => 'ارسال شد';

  @override
  String get chatStickerFavorites => 'علاقه‌مندی‌ها';

  @override
  String get chatStickerRecents => 'برچسب‌های اخیر';

  @override
  String get chatMediaPicker => 'عکس، ویدیو یا فایل';

  @override
  String get chatStickerPicker => 'شکلک، برچسب و گیف';

  @override
  String get chatCampusNotes => 'یادداشت‌های دانشگاه';

  @override
  String get chatMyStickers => 'برچسب‌های من';

  @override
  String get chatServerRequired =>
      'برای شروع گفت‌وگو به سرور پیام‌رسان متصل شوید.';

  @override
  String get message => 'پیام';

  @override
  String get account => 'حساب کاربری';

  @override
  String get professor => 'استاد';

  @override
  String get reportSubmitTitle => 'گزارش تخلف';

  @override
  String get reportSubmitBody =>
      'به تیم نظارت بگویید چه اتفاقی افتاده است. تا زمانی که گزارش باز است، بخش مرتبط گفت‌وگو ممکن است بررسی شود.';

  @override
  String get reportTarget => 'مورد گزارش‌شده';

  @override
  String get reportTargetUnknown => 'مورد نامشخص';

  @override
  String get reportReason => 'دلیل';

  @override
  String get reportChooseReason => 'یک دلیل انتخاب کنید';

  @override
  String get reportReasonHarassment => 'آزار یا توهین';

  @override
  String get reportReasonSpam => 'هرزنامه یا کلاهبرداری';

  @override
  String get reportReasonHate => 'نفرت‌پراکنی یا تبعیض';

  @override
  String get reportReasonImpersonation => 'جعل هویت';

  @override
  String get reportReasonViolence => 'خشونت یا تهدید';

  @override
  String get reportReasonOther => 'سایر موارد';

  @override
  String get reportDescribeReason => 'دلیل را توضیح دهید';

  @override
  String get reportReasonRequired => 'دلیلی را انتخاب یا وارد کنید.';

  @override
  String get reportReasonTooShort => 'دست‌کم ۲ نویسه وارد کنید.';

  @override
  String get reportReasonTooLong => 'دلیل نباید بیش از ۸۰ نویسه باشد.';

  @override
  String get reportNote => 'توضیحات بیشتر (اختیاری)';

  @override
  String get reportNoteHint =>
      'جزئیاتی بنویسید که به ناظر در بررسی گزارش کمک کند.';

  @override
  String get reportNoteTooLong => 'توضیحات نباید بیش از ۱٬۰۰۰ نویسه باشد.';

  @override
  String get reportPrivacyNotice =>
      'با ارسال گزارش، نسخه‌ای محافظت‌شده از شواهد ثبت می‌شود. ناظر فقط پس از قبول بررسی گزارش به گفت‌وگو دسترسی پیدا می‌کند.';

  @override
  String get reportSubmitAction => 'ارسال گزارش';

  @override
  String get reportSubmitting => 'در حال ارسال گزارش';

  @override
  String get reportSubmitted => 'گزارش ارسال شد';

  @override
  String get reportSubmittedBody =>
      'می‌توانید نتیجه را در «گزارش‌های من» دنبال کنید.';

  @override
  String get reportMyReportsTitle => 'گزارش‌های من';

  @override
  String get reportNoReportsTitle => 'هنوز گزارشی ندارید';

  @override
  String get reportNoReportsBody =>
      'گزارش‌هایی که ارسال می‌کنید و نتیجهٔ آن‌ها اینجا نمایش داده می‌شوند.';

  @override
  String get reportLoadingReports => 'در حال بارگیری گزارش‌ها';

  @override
  String get reportStatusAssigned => 'در حال بررسی';

  @override
  String get reportStatusResolved => 'رسیدگی‌شده';

  @override
  String get reportStatusDismissed => 'ردشده';

  @override
  String get reportOutcomeWarn => 'اخطار ثبت شد';

  @override
  String get reportOutcomeMute => 'محدودیت ارسال پیام ثبت شد';

  @override
  String get reportOutcomeRemoveContent => 'محتوای گزارش‌شده حذف شد';

  @override
  String get reportOutcomeBan => 'حساب واجد شرایط مسدود شد';

  @override
  String get reportOutcomeEscalate => 'ارجاع گزارش ثبت شد';

  @override
  String get reportOutcomeUnknown => 'نتیجه ثبت شد';

  @override
  String get reportModeratorNote => 'یادداشت ناظر';

  @override
  String get reportAwaitingOutcome => 'هنوز نتیجه‌ای ثبت نشده است.';

  @override
  String get reportUnderReview => 'این گفت‌وگو در حال بررسی توسط ناظر است.';

  @override
  String get reportUnderReviewBody =>
      'ناظر تا پایان رسیدگی، به پیام‌های مرتبط با گزارش دسترسی موقت دارد.';

  @override
  String get reportReviewStarted => 'آغاز بررسی';

  @override
  String get reportModerationQueue => 'صف بررسی گزارش‌ها';

  @override
  String get reportModerationTitle => 'گزارش‌های نظارت';

  @override
  String get reportModerationAccessTitle => 'دسترسی ناظر لازم است';

  @override
  String get reportModerationAccessBody =>
      'این بخش فقط در دسترس حساب‌های ناظر است.';

  @override
  String get reportNoQueueTitle => 'صف بررسی خالی است';

  @override
  String get reportNoQueueBody =>
      'هیچ گزارش واگذارشده یا بدون ناظری برای بررسی وجود ندارد.';

  @override
  String get reportLoadingQueue => 'در حال بارگیری صف بررسی گزارش‌ها';

  @override
  String get unassigned => 'واگذارنشده';

  @override
  String get reportAssignedToYou => 'واگذارشده به شما';

  @override
  String get reportOpenReport => 'باز کردن گزارش';

  @override
  String get reportReportDetails => 'جزئیات گزارش';

  @override
  String get reportReportId => 'شناسهٔ گزارش';

  @override
  String get reportConversationId => 'شناسهٔ گفت‌وگو';

  @override
  String get reportMessageId => 'شناسهٔ پیام';

  @override
  String get reportReporterId => 'شناسهٔ گزارش‌دهنده';

  @override
  String get reportTargetId => 'شناسهٔ مورد گزارش‌شده';

  @override
  String get reportReportNote => 'یادداشت گزارش‌دهنده';

  @override
  String get reportNoNote => 'یادداشتی ثبت نشده است.';

  @override
  String get reportClaimReport => 'قبول بررسی گزارش';

  @override
  String get reportClaimingReport => 'در حال واگذاری گزارش به شما';

  @override
  String get reportClaimBody =>
      'با قبول گزارش، به شواهد گفت‌وگوی مرتبط دسترسی موقت می‌گیرید. این دسترسی ثبت می‌شود.';

  @override
  String get reportAssignedElsewhere =>
      'این گزارش به ناظر دیگری واگذار شده است.';

  @override
  String get reportEvidenceTitle => 'شواهد گزارش';

  @override
  String get reportEvidenceAccess => 'در حال بررسی گزارش';

  @override
  String get reportEvidenceAccessBody =>
      'دسترسی فقط برای خواندن پیام‌های مشخص‌شده است و در سرور ثبت می‌شود.';

  @override
  String get reportEvidenceAfterClaim =>
      'برای درخواست دسترسی به پیام‌های مرتبط، بررسی این گزارش را قبول کنید.';

  @override
  String get reportNoConversationEvidence =>
      'این گزارش شواهدی از گفت‌وگو برای نمایش ندارد.';

  @override
  String get reportLoadingEvidence => 'در حال بارگیری شواهد مجاز';

  @override
  String get reportEvidenceExpired =>
      'دسترسی به شواهد گزارش منقضی یا لغو شده است.';

  @override
  String get reportNoEvidenceMessages =>
      'در محدودهٔ مجاز شواهد، پیامی برای نمایش وجود ندارد.';

  @override
  String get reportMessageType => 'نوع پیام';

  @override
  String get reportSender => 'فرستنده';

  @override
  String get reportSequence => 'شمارهٔ ترتیب';

  @override
  String get reportReportedMessage => 'پیام گزارش‌شده';

  @override
  String get reportResolveReport => 'ثبت نتیجهٔ گزارش';

  @override
  String get reportResolvingReport => 'در حال ثبت نتیجهٔ گزارش';

  @override
  String get reportResolutionNote => 'یادداشت رسیدگی (اختیاری)';

  @override
  String get reportResolutionNoteHint =>
      'یادداشت کوتاهی برای سابقهٔ بررسی بنویسید.';

  @override
  String get reportResolutionNoteTooLong =>
      'یادداشت رسیدگی نباید بیش از ۵۰۰ نویسه باشد.';

  @override
  String get reportDismissAction => 'رد گزارش';

  @override
  String get reportDismissDescription =>
      'گزارش را بدون اقدام دربارهٔ حساب یا محتوا ببندید.';

  @override
  String get reportRemoveContentAction => 'حذف محتوای گزارش‌شده';

  @override
  String get reportRemoveContentDescription =>
      'محتوای پیام گزارش‌شده را حذف کنید.';

  @override
  String get reportBanAction => 'مسدود کردن حساب واجد شرایط';

  @override
  String get reportBanDescription =>
      'حساب دانشجو یا استاد گزارش‌شده را مسدود کنید. سرور حساب‌های فاقد شرایط را نمی‌پذیرد.';

  @override
  String get reportResolutionFinal =>
      'ثبت نتیجه قطعی است و دسترسی به شواهد را لغو می‌کند.';

  @override
  String get reportReportResolved => 'نتیجهٔ گزارش ثبت شد';

  @override
  String get reportResolvedBody => 'گزارش بسته شد و دسترسی به شواهد آن لغو شد.';

  @override
  String get reportInvalidTargetError => 'مورد گزارش‌شده دیگر در دسترس نیست.';

  @override
  String get reportMessageRequiredError =>
      'برای این کار باید پیامی گزارش شده باشد.';

  @override
  String get reportNotFoundError => 'این گزارش دیگر در دسترس نیست.';

  @override
  String get reportModeratorConflictError =>
      'نمی‌توانید گزارشی را بررسی کنید که به حساب خودتان مربوط است.';

  @override
  String get reportAlreadyAssignedError =>
      'ناظر دیگری قبلاً بررسی این گزارش را قبول کرده است.';

  @override
  String get reportClosedError => 'این گزارش قبلاً بسته شده است.';

  @override
  String get reportUnsafeBanError =>
      'حساب گزارش‌شده واجد شرایط مسدود شدن نیست.';

  @override
  String get createGroup => 'ساخت گروه';

  @override
  String get createChannel => 'ساخت کانال';

  @override
  String get createGroupOrChannel => 'ساخت گروه یا کانال';

  @override
  String get discoverCommunities => 'یافتن گروه‌ها و کانال‌ها';

  @override
  String get universityServices => 'خدمات دانشگاه';

  @override
  String get services => 'خدمات';

  @override
  String get serviceCatalog => 'فهرست خدمات';

  @override
  String get serviceMyRequests => 'درخواست‌های من';

  @override
  String get serviceStaffQueue => 'صف درخواست‌ها';

  @override
  String get serviceAvailable => 'آمادهٔ واگذاری';

  @override
  String get serviceAssignedToMe => 'واگذارشده به من';

  @override
  String get serviceSubmitRequest => 'ارسال درخواست';

  @override
  String get serviceNewRequest => 'درخواست جدید';

  @override
  String get serviceClaimRequest => 'قبول درخواست';

  @override
  String get serviceRequestClaimed => 'درخواست به شما واگذار شد';

  @override
  String get serviceRequestCancelled => 'درخواست لغو شد';

  @override
  String get serviceRequestSubmitted => 'درخواست ارسال شد';

  @override
  String get serviceChangeStatus => 'تغییر وضعیت';

  @override
  String get serviceUpdateStatus => 'به‌روزرسانی وضعیت';

  @override
  String get serviceResultDocument => 'سند نتیجه';

  @override
  String get serviceAssociateResult => 'پیوست سند نتیجه';

  @override
  String get serviceReplaceResult => 'جایگزینی سند نتیجه';

  @override
  String get serviceTicketChat => 'گفت‌وگوی درخواست';

  @override
  String get serviceAddAttachment => 'افزودن پیوست';

  @override
  String get serviceRemoveAttachment => 'حذف پیوست';

  @override
  String get details => 'جزئیات';

  @override
  String get documents => 'مدارک';

  @override
  String get review => 'بازبینی';

  @override
  String get serviceTimeline => 'روند درخواست';

  @override
  String get serviceRequestDetails => 'جزئیات درخواست';

  @override
  String get serviceRequestData => 'اطلاعات درخواست';

  @override
  String get serviceRequiredDocuments => 'مدارک لازم';

  @override
  String get serviceAssigned => 'واگذارشده';

  @override
  String get status => 'وضعیت';

  @override
  String get lastUpdated => 'آخرین به‌روزرسانی';

  @override
  String serviceEstimatedTime(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return 'زمان تقریبی: $hoursString ساعت';
  }

  @override
  String get serviceOptionalNote => 'یادداشت (اختیاری)';

  @override
  String get serviceNote => 'یادداشت';

  @override
  String get serviceEmail => 'رایانامه';

  @override
  String get serviceDate => 'تاریخ';

  @override
  String serviceFieldIdentifier(String identifier) {
    return 'فیلد: $identifier';
  }

  @override
  String get invalidNumber => 'عدد معتبری وارد کنید.';

  @override
  String get invalidWholeNumber => 'عدد صحیح معتبری وارد کنید.';

  @override
  String get serviceLoadServicesError => 'بارگیری خدمات ممکن نبود';

  @override
  String get serviceLoadRequestsError => 'بارگیری درخواست‌ها ممکن نبود';

  @override
  String get serviceLoadRequestError => 'بارگیری این درخواست ممکن نبود';

  @override
  String get serviceLoadMessagesError => 'بارگیری پیام‌های درخواست ممکن نبود';

  @override
  String get serviceNoServices => 'خدمتی در دسترس نیست';

  @override
  String get serviceNoServicesBody =>
      'خدمات جدید دانشگاه اینجا نمایش داده می‌شوند.';

  @override
  String get serviceNoRequests => 'هنوز درخواستی ندارید';

  @override
  String get serviceNoRequestsBody =>
      'برای ارسال اولین درخواست، یکی از خدمات را انتخاب کنید.';

  @override
  String get serviceNoQueue => 'صف درخواست‌ها خالی است';

  @override
  String get serviceNoQueueBody =>
      'درخواست‌های جدید واحد شما اینجا نمایش داده می‌شوند.';

  @override
  String get serviceNoAssigned => 'درخواستی به شما واگذار نشده است';

  @override
  String get serviceNoAssignedBody =>
      'یکی از درخواست‌های آمادهٔ واگذاری را قبول کنید.';

  @override
  String get serviceNoMessages => 'این درخواست هنوز پیامی ندارد';

  @override
  String get serviceNoMessagesBody =>
      'پیام‌های دانشجو و کارشناس مسئول اینجا نمایش داده می‌شوند.';

  @override
  String get serviceNoTimeline => 'هنوز رویدادی برای این درخواست ثبت نشده است.';

  @override
  String get serviceNoDocuments => 'مدرکی پیوست نشده است.';

  @override
  String get serviceNoRequestData => 'اطلاعات بیشتری ثبت نشده است.';

  @override
  String get serviceFieldHelp => 'اطلاعات لازم برای این خدمت را وارد کنید.';

  @override
  String get serviceDocumentHelp =>
      'برای هر مدرک لازم یک پرونده بارگذاری کنید.';

  @override
  String get serviceReviewHelp =>
      'اطلاعات را پیش از ارسال بررسی کنید. پس از ارسال نمی‌توانید درخواست را ویرایش کنید.';

  @override
  String get serviceCancellationTitle => 'درخواست لغو شود؟';

  @override
  String get serviceCancellationBody =>
      'فقط پیش از شروع رسیدگی توسط کارشناس می‌توانید درخواست را لغو کنید.';

  @override
  String get serviceCancelRequest => 'لغو درخواست';

  @override
  String get serviceKeepRequest => 'نگه داشتن درخواست';

  @override
  String get serviceUnsupportedRole => 'خدمات برای این نوع حساب در دسترس نیست.';

  @override
  String get serviceUnknownService => 'خدمت نامشخص';

  @override
  String get serviceRequest => 'درخواست';

  @override
  String get yes => 'بله';

  @override
  String get no => 'خیر';

  @override
  String get serviceDraft => 'پیش‌نویس';

  @override
  String get serviceInReview => 'در حال بررسی';

  @override
  String get serviceNeedsInfo => 'نیازمند اطلاعات بیشتر';

  @override
  String get serviceApproved => 'تأییدشده';

  @override
  String get serviceRejected => 'ردشده';

  @override
  String get serviceReadyForPickup => 'آمادهٔ دریافت حضوری';

  @override
  String get serviceDeliveredDigitally => 'تحویل الکترونیکی';

  @override
  String get serviceCompleted => 'انجام‌شده';

  @override
  String get serviceCancelled => 'لغوشده';

  @override
  String get serviceUnknownStatus => 'وضعیت نامشخص';

  @override
  String get serviceEventClaimed => 'کارشناس رسیدگی به درخواست را قبول کرد';

  @override
  String get serviceEventResultUploaded => 'سند نتیجه پیوست شد';

  @override
  String serviceEventStatusChanged(String status) {
    return 'وضعیت تغییر کرد: $status';
  }

  @override
  String get serviceUnknownEvent => 'درخواست به‌روز شد';

  @override
  String get serviceRequestMissing => 'این درخواست دیگر در دسترس نیست.';

  @override
  String get serviceTypeMissing => 'این خدمت دیگر در دسترس نیست.';

  @override
  String get serviceRequirementsMissing =>
      'همهٔ فیلدهای لازم را پر کنید و مدارک موردنیاز را بارگذاری کنید.';

  @override
  String get serviceDocumentUnavailable =>
      'یکی از مدارک یا پیوست‌ها در دسترس نیست. پرونده را دوباره انتخاب کنید.';

  @override
  String get serviceAlreadyAssigned =>
      'کارشناس دیگری این درخواست را قبول کرده است.';

  @override
  String get serviceInvalidTransition =>
      'این تغییر وضعیت دیگر ممکن نیست. درخواست را به‌روز کنید و دوباره تلاش کنید.';

  @override
  String get serviceCannotCancel =>
      'رسیدگی شروع شده است و دیگر نمی‌توانید درخواست را لغو کنید.';

  @override
  String get chooseFile => 'انتخاب پرونده';

  @override
  String get replace => 'جایگزینی';

  @override
  String get upload => 'بارگذاری';

  @override
  String get pdfDocuments => 'سندهای پی‌دی‌اف';

  @override
  String get send => 'ارسال';

  @override
  String get degreeBachelor => 'کارشناسی';

  @override
  String get degreeMaster => 'کارشناسی ارشد';

  @override
  String get degreeDoctorate => 'دکتری';

  @override
  String get degreeOther => 'سایر';

  @override
  String get communityStudentGroup => 'گروه دانشجویی';

  @override
  String get communityCreateStudentGroup => 'ساخت گروه دانشجویی';

  @override
  String get communityGroupsUnavailable => 'گروه‌های دانشجویی در دسترس نیستند';

  @override
  String get communityGroupsUnavailableBody =>
      'فقط دانشجویان می‌توانند گروه دانشجویی بسازند.';

  @override
  String get communityChannelsUnavailable => 'ساخت کانال در دسترس نیست';

  @override
  String get communityChannelsUnavailableBody =>
      'فقط دانشجویان و استادان می‌توانند کانال بسازند.';

  @override
  String get communityUnavailable => 'گروه‌ها و کانال‌ها در دسترس نیستند';

  @override
  String get communityUnavailableBody =>
      'فقط دانشجویان و استادان با حساب فعال می‌توانند از گروه‌ها و کانال‌ها استفاده کنند.';

  @override
  String get communityCreate => 'ساخت گروه یا کانال';

  @override
  String get name => 'نام';

  @override
  String get enterName => 'نامی وارد کنید.';

  @override
  String get descriptionOptional => 'توضیحات (اختیاری)';

  @override
  String get visibility => 'دسترسی';

  @override
  String get publicVisibility => 'عمومی';

  @override
  String get privateVisibility => 'خصوصی';

  @override
  String get handleOptional => 'نام کاربری (اختیاری)';

  @override
  String get communityHandleRequired =>
      'برای گروه یا کانال عمومی نام کاربری لازم است.';

  @override
  String get communityProfessorChannel => 'کانال استاد';

  @override
  String get communityProfessorChannelHelp =>
      'این کانال در بخش کانال‌های استادان نمایش داده می‌شود.';

  @override
  String get communityJoin => 'عضویت';

  @override
  String get communityJoinWithInvite => 'عضویت با دعوت‌نامه';

  @override
  String get communityInviteToken => 'کد دعوت';

  @override
  String get communityPasteInvite => 'کد دعوت را اینجا جای‌گذاری کنید';

  @override
  String get communitySearch => 'جست‌وجوی نام و نام کاربری';

  @override
  String get clearSearch => 'پاک کردن جست‌وجو';

  @override
  String get communityAllPublic => 'همهٔ عمومی‌ها';

  @override
  String get communityProfessorChannels => 'کانال‌های استادان';

  @override
  String get communityLoadError => 'بارگیری گروه‌ها و کانال‌ها ممکن نبود';

  @override
  String get communityNotFoundList => 'گروه یا کانالی پیدا نشد';

  @override
  String get communityNoPublic =>
      'هنوز گروه یا کانال عمومی‌ای در این دسته نیست.';

  @override
  String get communityNoMatches => 'نام یا نام کاربری دیگری را امتحان کنید.';

  @override
  String communityJoined(String name) {
    return 'به «$name» پیوستید.';
  }

  @override
  String get communityInfo => 'اطلاعات گروه یا کانال';

  @override
  String get communityUnderReview => 'گفت‌وگو در حال بررسی است';

  @override
  String get communityUnderReviewBody =>
      'تا پایان بررسی گزارش، ممکن است برخی اقدام‌ها محدود باشند.';

  @override
  String get about => 'درباره';

  @override
  String get members => 'اعضا';

  @override
  String get created => 'تاریخ ایجاد';

  @override
  String get manage => 'مدیریت';

  @override
  String get communityDetailsAndSettings => 'مشخصات و تنظیمات';

  @override
  String get communityInviteLinks => 'پیوندهای دعوت';

  @override
  String get communityReport => 'گزارش گروه یا کانال';

  @override
  String get communityDelete => 'حذف گروه یا کانال';

  @override
  String get communityLeave => 'خروج از گروه یا کانال';

  @override
  String communityLeaveTitle(String name) {
    return 'از «$name» خارج می‌شوید؟';
  }

  @override
  String get communityLeaveBody =>
      'برای دیدن پیام‌های تازه باید دوباره عضو شوید.';

  @override
  String get leave => 'خروج';

  @override
  String communityDeleteTitle(String name) {
    return '«$name» حذف شود؟';
  }

  @override
  String get communityDeleteBody =>
      'گروه یا کانال و گفت‌وگوی آن برای همیشه حذف می‌شوند.';

  @override
  String get communityLoadOneError => 'بارگیری این گروه یا کانال ممکن نبود';

  @override
  String get communityJoinAction => 'پیوستن به گروه یا کانال';

  @override
  String get communityCannotJoin =>
      'امکان عضویت در این گروه یا کانال را ندارید';

  @override
  String get communityChatUnavailable => 'گفت‌وگو در دسترس نیست';

  @override
  String get communityOpenChat => 'باز کردن گفت‌وگو';

  @override
  String get communityDetails => 'مشخصات گروه یا کانال';

  @override
  String get communitySaveDetails => 'ذخیرهٔ مشخصات';

  @override
  String get communityDetailsSaved => 'مشخصات ذخیره شد.';

  @override
  String get communityConversationSettings => 'تنظیمات گفت‌وگو';

  @override
  String get communitySlowMode => 'فاصلهٔ ارسال پیام (ثانیه)';

  @override
  String get communitySlowModeHelp => 'برای برداشتن محدودیت، ۰ وارد کنید.';

  @override
  String get communitySlowModeInvalid => 'عددی بین ۰ و ۸۶٬۴۰۰ ثانیه وارد کنید.';

  @override
  String get communityMembersCanPost => 'ارسال پیام توسط اعضا';

  @override
  String get communityMembersCanPostHelp => 'اعضای عادی بتوانند پیام بفرستند.';

  @override
  String get communityMembersCanInvite => 'دعوت توسط اعضا';

  @override
  String get communityMembersCanInviteHelp =>
      'اعضا بتوانند پیوند دعوت را به اشتراک بگذارند.';

  @override
  String get communityCommentsEnabled => 'دیدگاه‌ها';

  @override
  String get communityCommentsEnabledHelp =>
      'اعضا بتوانند برای مطالب کانال دیدگاه بنویسند.';

  @override
  String get saveSettings => 'ذخیرهٔ تنظیمات';

  @override
  String get communitySettingsSaved => 'تنظیمات گفت‌وگو ذخیره شد.';

  @override
  String get communityAddMember => 'افزودن عضو';

  @override
  String get communityLoadMembersError => 'بارگیری اعضا ممکن نبود';

  @override
  String get communityNoMembers => 'عضوی وجود ندارد';

  @override
  String get communityNoMembersBody => 'هیچ عضو فعالی پیدا نشد.';

  @override
  String get communityManageMember => 'مدیریت عضو';

  @override
  String get communityOwnerRole => 'مالک';

  @override
  String get communityAdminRole => 'مدیر';

  @override
  String get communityMemberRole => 'عضو';

  @override
  String get communitySubscriberRole => 'عضو کانال';

  @override
  String get communityBannedRole => 'مسدودشده';

  @override
  String get communityPromoteMember => 'ارتقا به مدیر';

  @override
  String get communityDemoteMember => 'گرفتن دسترسی مدیریت';

  @override
  String get communityBanMember => 'مسدود کردن عضو';

  @override
  String get ban => 'مسدود کردن';

  @override
  String get communityRemoveMember => 'حذف عضو';

  @override
  String communityBanMemberTitle(String name) {
    return '«$name» مسدود شود؟';
  }

  @override
  String communityRemoveMemberTitle(String name) {
    return '«$name» حذف شود؟';
  }

  @override
  String get communityBanMemberBody =>
      'این عضو حذف می‌شود و نمی‌تواند دوباره بپیوندد.';

  @override
  String get communityRemoveMemberBody =>
      'این عضو از گروه یا کانال حذف می‌شود.';

  @override
  String get communityMemberPromoted => 'عضو به مدیر ارتقا یافت.';

  @override
  String get communityMemberDemoted => 'دسترسی مدیریت برداشته شد.';

  @override
  String get communityMemberBanned => 'عضو مسدود شد.';

  @override
  String get communityMemberRemoved => 'عضو حذف شد.';

  @override
  String communityMemberAdded(String name) {
    return '«$name» اضافه شد.';
  }

  @override
  String get communityInviteCreated => 'پیوند دعوت ساخته شد';

  @override
  String get communityCopyInviteHelp =>
      'کد را همین حالا کپی کنید. دوباره نمایش داده نمی‌شود.';

  @override
  String get communityInviteCopied => 'کد دعوت کپی شد.';

  @override
  String get communityRevokeInvite => 'لغو دعوت‌نامه';

  @override
  String get communityRevokeInviteTitle => 'این دعوت‌نامه لغو شود؟';

  @override
  String get communityRevokeInviteBody => 'دعوت‌نامه بلافاصله از کار می‌افتد.';

  @override
  String get communityInviteRevoked => 'دعوت‌نامه لغو شد.';

  @override
  String get communityCreateInvite => 'ساخت پیوند دعوت';

  @override
  String get communityLoadInvitesError => 'بارگیری دعوت‌نامه‌ها ممکن نبود';

  @override
  String get communityNoInvites => 'هنوز پیوند دعوتی وجود ندارد';

  @override
  String get communityNoInvitesBody =>
      'برای این گروه یا کانال پیوند دعوت بسازید.';

  @override
  String get communityActiveInvite => 'دعوت‌نامهٔ فعال';

  @override
  String get communityRevokedInvite => 'دعوت‌نامهٔ لغوشده';

  @override
  String get communityExpiredInvite => 'دعوت‌نامهٔ منقضی‌شده';

  @override
  String get communityUsedInvite => 'سقف استفاده پر شده است';

  @override
  String get communityExpiresAfter => 'مدت اعتبار';

  @override
  String get communityExpiryOneDay => '۲۴ ساعت';

  @override
  String get communityExpiryOneWeek => '۷ روز';

  @override
  String get communityExpiryThirtyDays => '۳۰ روز';

  @override
  String get communityNeverExpires => 'بدون انقضا';

  @override
  String get communityMaxUses => 'حداکثر دفعات استفاده (اختیاری)';

  @override
  String get communityMaxUsesInvalid => 'عددی بین ۱ و ۱۰٬۰۰۰ وارد کنید.';

  @override
  String communityInviteUses(int uses) {
    final intl.NumberFormat usesNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String usesString = usesNumberFormat.format(uses);

    return '$usesString بار استفاده';
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

    return '$usesString بار از $maxUsesString بار استفاده شده';
  }

  @override
  String communityInviteExpires(String date) {
    return 'اعتبار تا $date';
  }

  @override
  String get communityInvalidHandle => 'نام کاربری معتبری وارد کنید.';

  @override
  String get communityHandleTaken => 'این نام کاربری قبلاً گرفته شده است.';

  @override
  String get communityInvalidGroupMember =>
      'فقط دانشجویان می‌توانند عضو گروه‌های دانشجویی شوند.';

  @override
  String get communityRejoinDenied =>
      'این حساب نمی‌تواند دوباره به گروه یا کانال بپیوندد.';

  @override
  String get communityMissing => 'این گروه یا کانال دیگر در دسترس نیست.';

  @override
  String get communityInviteInvalid =>
      'این دعوت‌نامه نامعتبر یا منقضی شده است.';

  @override
  String get communityUserMissing => 'کاربری با این نام کاربری پیدا نشد.';

  @override
  String get communityAlreadyMember => 'این کاربر از قبل عضو است.';

  @override
  String get communityOwnerCannotLeave =>
      'پیش از خروج، مالکیت را واگذار کنید یا گروه یا کانال را حذف کنید.';

  @override
  String get communityMemberMissing => 'این شخص دیگر عضو نیست.';

  @override
  String get communityInvalidMemberRole =>
      'این نقش برای این گروه یا کانال تعریف نشده است.';

  @override
  String get communityDmUnavailable =>
      'این اقدام در گفت‌وگوی خصوصی در دسترس نیست.';

  @override
  String communityOfficialDescription(String name) {
    return 'کانال رسمی $name';
  }

  @override
  String get mediaInvalidSize =>
      'پرونده‌ای غیرخالی با حجم حداکثر ۲۵ مگابایت انتخاب کنید.';

  @override
  String get mediaUnsupportedType =>
      'پرونده‌ای با قالب پشتیبانی‌شده انتخاب کنید.';

  @override
  String get mediaInvalidContent =>
      'محتوای پرونده با قالب آن سازگار نیست. پروندهٔ دیگری انتخاب کنید.';

  @override
  String get chatDemoStudy => 'گروه مطالعهٔ الگوریتم‌ها';

  @override
  String get chatDemoProfessor => 'استاد رحیمی · ساختمان داده‌ها';

  @override
  String get chatDemoSara => 'سارا احمدی';

  @override
  String get chatDemoStudyOne =>
      'کسی می‌خواهد امروز برنامه‌نویسی پویا را مرور کنیم؟';

  @override
  String get chatDemoStudyTwo => 'بله، بعد از کلاس ساعت ۲ برای من مناسب است.';

  @override
  String get chatDemoStudyThree => 'مجموعهٔ تمرین‌ها را بارگذاری کردم.';

  @override
  String get chatDemoProfessorOne => 'اسلایدهای هفتهٔ ششم در دسترس هستند.';

  @override
  String get chatDemoProfessorTwo => 'ساعت پاسخ‌گویی به ۱۴:۳۰ تغییر کرد.';

  @override
  String get chatDemoSaraPreview => 'در کتابخانه می‌بینمت.';
}
