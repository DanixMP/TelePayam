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
  String get welcomeTitle => 'دانشگاه شما، در یک گفت‌وگو';

  @override
  String get welcomeBody =>
      'با هویت تأییدشده دانشگاهی به همکلاسی‌ها و استادان پیام بدهید.';

  @override
  String get continueLabel => 'ادامه';

  @override
  String get persian => 'فارسی';

  @override
  String get english => 'English';

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
    return 'ارسال دوباره تا $seconds ثانیه';
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
  String get statusStep => 'دسترسی';

  @override
  String get themeTooltip => 'تغییر پوسته';

  @override
  String get languageTooltip => 'تغییر زبان';

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
    return '$count عضو';
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
      'عکس به‌روزرسانی نشد. یک تصویر JPG، PNG یا WebP تا ۲۵ مگابایت انتخاب کنید و دوباره تلاش کنید.';

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
}
