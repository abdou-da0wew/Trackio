// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get close => 'إغلاق';

  @override
  String get tagline => 'راقب ما يحمل يومك دائمًا.';

  @override
  String get onboardingSkip => 'تخطّي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingGetStarted => 'ابدأ الآن';

  @override
  String get onboarding1Title => 'حقيبتك أمام عينيك دائمًا';

  @override
  String get onboarding1Body =>
      'يدمج Trackio نظام تحديد المواقع في هاتفك ونظام الحقيبة ورابط الراديو ESP32 في إشارة واحدة حية ومستمرة لحقيبتك.';

  @override
  String get onboarding2Title => 'اعرف لحظة ابتعادها';

  @override
  String get onboarding2Body =>
      'أي زيادة غير معتادة في المسافة تُطلق تنبيهًا فوريًا، وتطلب حزمات الذعر من وحدة الحقيبة إشارات عالية التردد وعالية الدقة.';

  @override
  String get onboarding3Title => 'استعدّها بسرعة';

  @override
  String get onboarding3Body =>
      'مسار استرداد موجّه يجمع كل مصادر الموقع حتى تلتقي بحقيبتك من جديد — ثم تؤكدها بلمسة واحدة.';

  @override
  String get loginWelcomeBack => 'مرحبًا بعودتك';

  @override
  String get loginSubtitle => 'سجّل دخولك لتبقى حقيبتك في متناولك.';

  @override
  String get fieldEmail => 'البريد الإلكتروني';

  @override
  String get fieldPassword => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signingIn => 'جارٍ تسجيل الدخول…';

  @override
  String get newToTrackio => 'جديد على Trackio؟';

  @override
  String get createAccount => 'أنشئ حسابًا';

  @override
  String get demoLoginBanner =>
      'نسخة تجريبية — أي بيانات تُدخلها تُسجّل دخولك.';

  @override
  String get errEnterEmail => 'أدخل بريدًا إلكترونيًا لمتابعة العرض التجريبي';

  @override
  String get signupTitle => 'أنشئ حسابك';

  @override
  String get signupSubtitle => 'حساب واحد لكل حقيبة تتتبعها.';

  @override
  String get fieldFullName => 'الاسم الكامل';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get creating => 'جارٍ الإنشاء…';

  @override
  String get demoSignupBanner =>
      'نسخة تجريبية — ينشئ التسجيل رمز تحقق وهميًا يظهر في الشاشة التالية.';

  @override
  String get errFillNameEmail => 'اكتب اسمك وبريدك الإلكتروني للمتابعة';

  @override
  String get otpTitle => 'أكّد بريدك الإلكتروني';

  @override
  String otpSentTo(String email) {
    return 'أرسلنا رمزًا من 6 أرقام إلى $email.';
  }

  @override
  String get otpFallbackEmail => 'بريدك الإلكتروني';

  @override
  String get otpIncorrect => 'الرمز غير صحيح — راجع التلميحة التجريبية أدناه.';

  @override
  String get otpVerify => 'تحقّق وتابع';

  @override
  String get otpVerifying => 'جارٍ التحقق…';

  @override
  String otpResendIn(int seconds) {
    return 'إعادة إرسال الرمز بعد $seconds ث';
  }

  @override
  String get otpResend => 'أعد إرسال الرمز';

  @override
  String otpDemoHint(String code) {
    return 'رمز العرض التجريبي: $code — في الإنتاج يُرسَل عبر Supabase.';
  }

  @override
  String get otpDemoNoCode =>
      'نسخة تجريبية — يظهر الرمز هنا بدل البريد الإلكتروني.';

  @override
  String get codeCopied => 'تم نسخ الرمز';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabMap => 'الخريطة';

  @override
  String get tabHistory => 'السجل';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get statusTracking => 'تتبّع';

  @override
  String get statusWarning => 'تحذير مسافة';

  @override
  String get statusLost => 'يُرجَّح فقدانها';

  @override
  String get statusPanic => 'وضع الذعر';

  @override
  String get statusRecovering => 'جارٍ الاسترداد';

  @override
  String get statusRecovered => 'تم الاسترداد';

  @override
  String goodMorning(String name) {
    return 'صباح الخير، $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'نهار سعيد، $name';
  }

  @override
  String goodEvening(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String get demoUser => 'مستخدم تجريبي';

  @override
  String updatedAgo(String ago) {
    return 'آخر تحديث $ago';
  }

  @override
  String get agoNow => 'الآن';

  @override
  String agoSeconds(int n) {
    return 'قبل $n ث';
  }

  @override
  String agoMinutes(int n) {
    return 'قبل $n د';
  }

  @override
  String agoHours(int n) {
    return 'قبل $n س';
  }

  @override
  String radioLinkDown(int retries) {
    return 'الرابط اللاسلكي متوقف · جارٍ إعادة المحاولة ($retries)';
  }

  @override
  String get fromYourBag => 'من حقيبتك · GPS مدمج + راديو ESP32';

  @override
  String get linkLost => 'انقطع الرابط';

  @override
  String get noFix => 'لا إشارة';

  @override
  String get locateBag => 'حدّد الحقيبة';

  @override
  String get ringTag => 'رنّ الوسم';

  @override
  String get demoMode => 'وضع العرض';

  @override
  String playingOnBag(String sound) {
    return 'يشغّل $sound على وحدة الحقيبة';
  }

  @override
  String get livePosition => 'الموقع المباشر';

  @override
  String get openMap => 'افتح الخريطة';

  @override
  String get recentActivity => 'النشاط الأخير';

  @override
  String get unitMeters => 'م';

  @override
  String get unitKm => 'كم';

  @override
  String get mapTooltipDemo => 'أدوات العرض';

  @override
  String get tooltipFollow => 'تابعني';

  @override
  String get tooltipCenterBag => 'وسّط على الحقيبة';

  @override
  String get tooltipFitBoth => 'أظهر الاثنتين';

  @override
  String mapSignalLost(int retries) {
    return 'انقطعت الإشارة · محاولة #$retries';
  }

  @override
  String bagFixLine(String accuracy, String rssi, int battery) {
    return 'دقة ±$accuracy م · $rssi · البطارية $battery٪';
  }

  @override
  String get buzzQueued => 'أُرسل أمر الاهتزاز إلى وحدة ESP32';

  @override
  String get alertTitle => 'قد تكون حقيبتك مفقودة';

  @override
  String get alertBody =>
      'تجاوزت المسافة حدّ الأمان. ينبّه Trackio وحدة الحقيبة كل ثانية ويدمج إشارات GPS والراديو لتحديد موقعها بدقة.';

  @override
  String get statLiveDistance => 'المسافة الحية';

  @override
  String get statPanicPackets => 'حزم الذعر';

  @override
  String get statRadioRetries => 'محاولات الراديو';

  @override
  String get openRecoveryMap => 'افتح خريطة الاسترداد';

  @override
  String get iFoundMyBag => 'وجدت حقيبتي';

  @override
  String get minimise => 'تصغير';

  @override
  String get foundToast => 'تم استرداد الحقيبة — مرحبًا بعودتك!';

  @override
  String get demoControls => 'أدوات العرض';

  @override
  String get demoSubtitle =>
      'شغّل قصة الفقد والاسترداد كاملة، أو أطلق الأحداث يدويًا واحدًا تلو الآخر.';

  @override
  String get scriptedScenario => 'السيناريو المُبرمَج';

  @override
  String get stopScenario => 'أوقف السيناريو';

  @override
  String get startScenario => 'ابدأ سيناريو العرض';

  @override
  String get manualTriggers => 'إطلاق يدوي';

  @override
  String get speed => 'السرعة';

  @override
  String get trigLeftBag => 'تركتُ الحقيبة';

  @override
  String get trigCutLink => 'اقطع الرابط';

  @override
  String get trigPanicPacket => 'حزمة ذعر';

  @override
  String get trigRecover => 'استرداد';

  @override
  String get trigMarkFound => 'حدّدها كموجودة';

  @override
  String get trigReset => 'إعادة الجلسة';

  @override
  String get historyTitle => 'السجل';

  @override
  String get lossAlerts => 'تنبيهات الفقد';

  @override
  String get avgDistance => 'متوسط المسافة';

  @override
  String get dataPoints => 'نقاط البيانات';

  @override
  String get distanceTimeline => 'الخط الزمني للمسافة';

  @override
  String get legendSafe => 'النطاق الآمن';

  @override
  String get legendLoss => 'أحداث الفقد';

  @override
  String get eventLog => 'سجل الأحداث';

  @override
  String get noEventsYet => 'لا أحداث بعد — ابدأ سيناريو العرض.';

  @override
  String get collectingData => 'جارٍ جمع بيانات التتبع…';

  @override
  String get lossLimit => 'حد الفقد';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get sectionAppearance => 'المظهر';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get sectionLanguage => 'اللغة';

  @override
  String get langSystem => 'النظام';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get sectionSound => 'صوت تنبيه الفقد';

  @override
  String get soundSonarPing => 'نبضة سونار';

  @override
  String get soundAlarmPulse => 'نبض إنذار';

  @override
  String get soundGentleChime => 'رنين لطيف';

  @override
  String get soundPreview => 'تشغيل تجريبي';

  @override
  String get sectionIntervals => 'فواصل التتبع وGPS';

  @override
  String get intervalPhoneGps => 'تحديث GPS الهاتف';

  @override
  String get intervalBagGps => 'تحديث GPS الحقيبة';

  @override
  String get intervalRecheck => 'إعادة فحص المسافة';

  @override
  String intervalSeconds(int value) {
    return '$value ث';
  }

  @override
  String get intervalsNote =>
      'وضع الذعر يتجاوز هذه الفواصل: تتحول وحدة الحقيبة إلى إشارة كل ثانية حتى تؤكد الاسترداد.';

  @override
  String get sectionConnection => 'الاتصال';

  @override
  String get backendSupabase => 'Supabase · خادم خاص VDS';

  @override
  String get supabaseSyncing => 'مزامنة الأحداث · عرض';

  @override
  String get supabaseAuth => 'مصادقة + مزامنة التتبع';

  @override
  String get backendTigris => 'تخزين Tigris السحابي';

  @override
  String get tigrisSubtitle => 'أرشيف المسارات والتصدير';

  @override
  String get connected => 'متصل';

  @override
  String get down => 'متوقف';

  @override
  String get sectionAccount => 'الحساب';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutTitle => 'تسجيل الخروج من Trackio؟';

  @override
  String get signOutBody =>
      'ستبقى جلستك التجريبية وبيانات التتبع المحلية على هذا الجهاز.';

  @override
  String get versionLine => 'Trackio 1.0.0 · نسخة عرض لأصحاب المصلحة';

  @override
  String get eventLocationUpdate => 'تحديث موقع';

  @override
  String get eventWarning => 'تحذير مسافة';

  @override
  String get eventLost => 'فُقدت الحقيبة';

  @override
  String get eventPanicSent => 'أُرسلت حزمة ذعر';

  @override
  String get eventConnectionLost => 'انقطع الاتصال';

  @override
  String get eventReconnect => 'استُعيد الاتصال';

  @override
  String get eventRecovered => 'جارٍ الاسترداد';

  @override
  String get eventFound => 'وُجدت الحقيبة';

  @override
  String get evSessionStarted => 'بدأت جلسة التتبع · GPS مدمج + راديو';

  @override
  String evUnusualDistance(int meters) {
    return 'زيادة غير معتادة في المسافة · $meters م';
  }

  @override
  String evDistanceExceeded(int meters, int limit) {
    return 'مسافة الحقيبة $meters م · تجاوزت حد $limit م';
  }

  @override
  String evBagGpsFix(String accuracy) {
    return 'إشارة GPS للحقيبة · ±$accuracy م';
  }

  @override
  String evBagGpsFixPanic(String accuracy) {
    return 'إشارة GPS للحقيبة · ±$accuracy م · عالية التردد';
  }

  @override
  String get evLinkLost => 'انقطع رابط ESP32 اللاسلكي · جارٍ إعادة المحاولة…';

  @override
  String get evLinkReestablished =>
      'استُعيد الرابط اللاسلكي · تمت المصافحة مع ESP32';

  @override
  String evLinkRestored(int meters, String accuracy) {
    return 'استُعيد الرابط عند $meters م · دقة الإشارة المدمجة ±$accuracy م';
  }

  @override
  String get evPanicPacket => 'حزمة ذعر ← وحدة الحقيبة · طلب إشارة كل ثانية';

  @override
  String evPanicPacketN(int n) {
    return 'حزمة ذعر رقم $n · طلب إشارة فورية';
  }

  @override
  String get evRecoveryStarted => 'بدأ الاسترداد · توجيه إلى آخر إشارة مدمجة';

  @override
  String evRecoveryConfirmed(int meters) {
    return 'أكّد المستخدم الاسترداد عند $meters م';
  }

  @override
  String get evMotionChanged => 'تغيّر نمط حركة الحقيبة · ساكنة';

  @override
  String get capIntro => 'تتبّع مباشر · الحقيبة داخل نطاق الراديو';

  @override
  String get capDrifting => 'تُركت الحقيبة · أنت تبتعد';

  @override
  String get capLeftBehind => 'واصلت مشيتك… وبقيت الحقيبة في المقهى';

  @override
  String get capWarning => 'المسافة تكبر · نراقب إشارات الفقد';

  @override
  String get capLost => 'اكتُشف الفقد · يبدأ وضع الذعر';

  @override
  String get capPanic => 'وضع الذعر · نبض عالي التردد كل ثانية';

  @override
  String get capReconnected =>
      'استُعادت الإشارة · أكّد استلام حقيبتك لإنهاء وضع الذعر';

  @override
  String capNear(int meters) {
    return 'صرت على بُعد $meters م من حقيبتك';
  }

  @override
  String get capRecovering => 'مسار الاسترداد نشط · يعيدك إليها';

  @override
  String get capFound => 'تم استرداد الحقيبة';
}
