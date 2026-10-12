import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Never lose sight of what carries your day.'**
  String get tagline;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'See your bag, always'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In en, this message translates to:
  /// **'Trackio fuses your phone GPS, the bag\'s own GPS and the ESP32 radio link into one live, continuous fix on your bag.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Know the moment it leaves'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In en, this message translates to:
  /// **'Abnormal distance triggers an instant alert. Panic packets ask the bag module for high-frequency, high-accuracy fixes.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Get it back, fast'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In en, this message translates to:
  /// **'A guided recovery route reconciles every location source until you\'re reunited — then you confirm it with one tap.'**
  String get onboarding3Body;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your bag within reach.'**
  String get loginSubtitle;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @newToTrackio.
  ///
  /// In en, this message translates to:
  /// **'New to Trackio?'**
  String get newToTrackio;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @demoLoginBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo build — any credentials sign you in.'**
  String get demoLoginBanner;

  /// No description provided for @errEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter an email to continue the demo'**
  String get errEnterEmail;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One account for every bag you track.'**
  String get signupSubtitle;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creating;

  /// No description provided for @demoSignupBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo build — signup generates a mock OTP shown on the next screen.'**
  String get demoSignupBanner;

  /// No description provided for @errFillNameEmail.
  ///
  /// In en, this message translates to:
  /// **'Fill your name and email to continue'**
  String get errFillNameEmail;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}.'**
  String otpSentTo(String email);

  /// No description provided for @otpFallbackEmail.
  ///
  /// In en, this message translates to:
  /// **'your email'**
  String get otpFallbackEmail;

  /// No description provided for @otpIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code — check the demo hint below.'**
  String get otpIncorrect;

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify & continue'**
  String get otpVerify;

  /// No description provided for @otpVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get otpVerifying;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String otpResendIn(int seconds);

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpDemoHint.
  ///
  /// In en, this message translates to:
  /// **'Demo OTP: {code} — production sends this via Supabase.'**
  String otpDemoHint(String code);

  /// No description provided for @otpDemoNoCode.
  ///
  /// In en, this message translates to:
  /// **'Demo build — OTP shown here instead of email.'**
  String get otpDemoNoCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @statusTracking.
  ///
  /// In en, this message translates to:
  /// **'TRACKING'**
  String get statusTracking;

  /// No description provided for @statusWarning.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE WARNING'**
  String get statusWarning;

  /// No description provided for @statusLost.
  ///
  /// In en, this message translates to:
  /// **'POSSIBLY LOST'**
  String get statusLost;

  /// No description provided for @statusPanic.
  ///
  /// In en, this message translates to:
  /// **'PANIC MODE'**
  String get statusPanic;

  /// No description provided for @statusRecovering.
  ///
  /// In en, this message translates to:
  /// **'RECOVERING'**
  String get statusRecovering;

  /// No description provided for @statusRecovered.
  ///
  /// In en, this message translates to:
  /// **'RECOVERED'**
  String get statusRecovered;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String goodMorning(String name);

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String goodAfternoon(String name);

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String goodEvening(String name);

  /// No description provided for @demoUser.
  ///
  /// In en, this message translates to:
  /// **'Demo User'**
  String get demoUser;

  /// No description provided for @updatedAgo.
  ///
  /// In en, this message translates to:
  /// **'updated {ago}'**
  String updatedAgo(String ago);

  /// No description provided for @agoNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get agoNow;

  /// No description provided for @agoSeconds.
  ///
  /// In en, this message translates to:
  /// **'{n}s ago'**
  String agoSeconds(int n);

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String agoMinutes(int n);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String agoHours(int n);

  /// No description provided for @radioLinkDown.
  ///
  /// In en, this message translates to:
  /// **'radio link down · retrying ({retries})'**
  String radioLinkDown(int retries);

  /// No description provided for @fromYourBag.
  ///
  /// In en, this message translates to:
  /// **'from your bag · fused GPS + ESP32 radio'**
  String get fromYourBag;

  /// No description provided for @linkLost.
  ///
  /// In en, this message translates to:
  /// **'link lost'**
  String get linkLost;

  /// No description provided for @noFix.
  ///
  /// In en, this message translates to:
  /// **'no fix'**
  String get noFix;

  /// No description provided for @locateBag.
  ///
  /// In en, this message translates to:
  /// **'Locate bag'**
  String get locateBag;

  /// No description provided for @ringTag.
  ///
  /// In en, this message translates to:
  /// **'Ring tag'**
  String get ringTag;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get demoMode;

  /// No description provided for @playingOnBag.
  ///
  /// In en, this message translates to:
  /// **'Playing {sound} on the bag module'**
  String playingOnBag(String sound);

  /// No description provided for @livePosition.
  ///
  /// In en, this message translates to:
  /// **'LIVE POSITION'**
  String get livePosition;

  /// No description provided for @openMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get openMap;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'RECENT ACTIVITY'**
  String get recentActivity;

  /// No description provided for @unitMeters.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get unitMeters;

  /// No description provided for @unitKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKm;

  /// No description provided for @mapTooltipDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo controls'**
  String get mapTooltipDemo;

  /// No description provided for @tooltipFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow me'**
  String get tooltipFollow;

  /// No description provided for @tooltipCenterBag.
  ///
  /// In en, this message translates to:
  /// **'Center on bag'**
  String get tooltipCenterBag;

  /// No description provided for @tooltipFitBoth.
  ///
  /// In en, this message translates to:
  /// **'Fit both'**
  String get tooltipFitBoth;

  /// No description provided for @mapSignalLost.
  ///
  /// In en, this message translates to:
  /// **'signal lost · retry #{retries}'**
  String mapSignalLost(int retries);

  /// No description provided for @bagFixLine.
  ///
  /// In en, this message translates to:
  /// **'±{accuracy} m fix · {rssi} · battery {battery}%'**
  String bagFixLine(String accuracy, String rssi, int battery);

  /// No description provided for @buzzQueued.
  ///
  /// In en, this message translates to:
  /// **'Buzz command queued on ESP32 module'**
  String get buzzQueued;

  /// No description provided for @alertTitle.
  ///
  /// In en, this message translates to:
  /// **'Your bag may be lost'**
  String get alertTitle;

  /// No description provided for @alertBody.
  ///
  /// In en, this message translates to:
  /// **'Distance exceeded your safety limit. Trackio is pinging the bag module at 1 Hz and fusing GPS + radio fixes to pinpoint it.'**
  String get alertBody;

  /// No description provided for @statLiveDistance.
  ///
  /// In en, this message translates to:
  /// **'LIVE DISTANCE'**
  String get statLiveDistance;

  /// No description provided for @statPanicPackets.
  ///
  /// In en, this message translates to:
  /// **'PANIC PACKETS'**
  String get statPanicPackets;

  /// No description provided for @statRadioRetries.
  ///
  /// In en, this message translates to:
  /// **'RADIO RETRIES'**
  String get statRadioRetries;

  /// No description provided for @openRecoveryMap.
  ///
  /// In en, this message translates to:
  /// **'Open recovery map'**
  String get openRecoveryMap;

  /// No description provided for @iFoundMyBag.
  ///
  /// In en, this message translates to:
  /// **'I found my bag'**
  String get iFoundMyBag;

  /// No description provided for @minimise.
  ///
  /// In en, this message translates to:
  /// **'Minimise'**
  String get minimise;

  /// No description provided for @foundToast.
  ///
  /// In en, this message translates to:
  /// **'Bag recovered — welcome back!'**
  String get foundToast;

  /// No description provided for @demoControls.
  ///
  /// In en, this message translates to:
  /// **'Demo Controls'**
  String get demoControls;

  /// No description provided for @demoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play the full loss-recovery story, or trigger individual events manually.'**
  String get demoSubtitle;

  /// No description provided for @scriptedScenario.
  ///
  /// In en, this message translates to:
  /// **'Scripted scenario'**
  String get scriptedScenario;

  /// No description provided for @stopScenario.
  ///
  /// In en, this message translates to:
  /// **'Stop scenario'**
  String get stopScenario;

  /// No description provided for @startScenario.
  ///
  /// In en, this message translates to:
  /// **'Start demo scenario'**
  String get startScenario;

  /// No description provided for @manualTriggers.
  ///
  /// In en, this message translates to:
  /// **'MANUAL TRIGGERS'**
  String get manualTriggers;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'SPEED'**
  String get speed;

  /// No description provided for @trigLeftBag.
  ///
  /// In en, this message translates to:
  /// **'Left bag behind'**
  String get trigLeftBag;

  /// No description provided for @trigCutLink.
  ///
  /// In en, this message translates to:
  /// **'Cut radio link'**
  String get trigCutLink;

  /// No description provided for @trigPanicPacket.
  ///
  /// In en, this message translates to:
  /// **'Panic packet'**
  String get trigPanicPacket;

  /// No description provided for @trigRecover.
  ///
  /// In en, this message translates to:
  /// **'Recover'**
  String get trigRecover;

  /// No description provided for @trigMarkFound.
  ///
  /// In en, this message translates to:
  /// **'Mark found'**
  String get trigMarkFound;

  /// No description provided for @trigReset.
  ///
  /// In en, this message translates to:
  /// **'Reset session'**
  String get trigReset;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @lossAlerts.
  ///
  /// In en, this message translates to:
  /// **'LOSS ALERTS'**
  String get lossAlerts;

  /// No description provided for @avgDistance.
  ///
  /// In en, this message translates to:
  /// **'AVG DISTANCE'**
  String get avgDistance;

  /// No description provided for @dataPoints.
  ///
  /// In en, this message translates to:
  /// **'DATA POINTS'**
  String get dataPoints;

  /// No description provided for @distanceTimeline.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE TIMELINE'**
  String get distanceTimeline;

  /// No description provided for @legendSafe.
  ///
  /// In en, this message translates to:
  /// **'safe range'**
  String get legendSafe;

  /// No description provided for @legendLoss.
  ///
  /// In en, this message translates to:
  /// **'loss events'**
  String get legendLoss;

  /// No description provided for @eventLog.
  ///
  /// In en, this message translates to:
  /// **'EVENT LOG'**
  String get eventLog;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No events yet — start the demo scenario.'**
  String get noEventsYet;

  /// No description provided for @collectingData.
  ///
  /// In en, this message translates to:
  /// **'Collecting tracking data…'**
  String get collectingData;

  /// No description provided for @lossLimit.
  ///
  /// In en, this message translates to:
  /// **'loss limit'**
  String get lossLimit;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get sectionAppearance;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get sectionLanguage;

  /// No description provided for @langSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get langSystem;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get langArabic;

  /// No description provided for @sectionSound.
  ///
  /// In en, this message translates to:
  /// **'LOST-BAG ALERT SOUND'**
  String get sectionSound;

  /// No description provided for @soundSonarPing.
  ///
  /// In en, this message translates to:
  /// **'Sonar Ping'**
  String get soundSonarPing;

  /// No description provided for @soundAlarmPulse.
  ///
  /// In en, this message translates to:
  /// **'Alarm Pulse'**
  String get soundAlarmPulse;

  /// No description provided for @soundGentleChime.
  ///
  /// In en, this message translates to:
  /// **'Gentle Chime'**
  String get soundGentleChime;

  /// No description provided for @soundPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get soundPreview;

  /// No description provided for @sectionIntervals.
  ///
  /// In en, this message translates to:
  /// **'TRACKING & GPS INTERVALS'**
  String get sectionIntervals;

  /// No description provided for @intervalPhoneGps.
  ///
  /// In en, this message translates to:
  /// **'Phone GPS update'**
  String get intervalPhoneGps;

  /// No description provided for @intervalBagGps.
  ///
  /// In en, this message translates to:
  /// **'Bag GPS update'**
  String get intervalBagGps;

  /// No description provided for @intervalRecheck.
  ///
  /// In en, this message translates to:
  /// **'Distance recheck'**
  String get intervalRecheck;

  /// No description provided for @intervalSeconds.
  ///
  /// In en, this message translates to:
  /// **'{value}s'**
  String intervalSeconds(int value);

  /// No description provided for @intervalsNote.
  ///
  /// In en, this message translates to:
  /// **'Panic mode overrides these: the bag module switches to 1 Hz fixes until you confirm recovery.'**
  String get intervalsNote;

  /// No description provided for @sectionConnection.
  ///
  /// In en, this message translates to:
  /// **'CONNECTION'**
  String get sectionConnection;

  /// No description provided for @backendSupabase.
  ///
  /// In en, this message translates to:
  /// **'Supabase · self-hosted VDS'**
  String get backendSupabase;

  /// No description provided for @supabaseSyncing.
  ///
  /// In en, this message translates to:
  /// **'syncing events · demo'**
  String get supabaseSyncing;

  /// No description provided for @supabaseAuth.
  ///
  /// In en, this message translates to:
  /// **'auth + tracking sync'**
  String get supabaseAuth;

  /// No description provided for @backendTigris.
  ///
  /// In en, this message translates to:
  /// **'Tigris object storage'**
  String get backendTigris;

  /// No description provided for @tigrisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'route archives & exports'**
  String get tigrisSubtitle;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @down.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get down;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get sectionAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Trackio?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your demo session and local tracking data stay on this device.'**
  String get signOutBody;

  /// No description provided for @versionLine.
  ///
  /// In en, this message translates to:
  /// **'Trackio 1.0.0 · demo build for stakeholder preview'**
  String get versionLine;

  /// No description provided for @eventLocationUpdate.
  ///
  /// In en, this message translates to:
  /// **'Location update'**
  String get eventLocationUpdate;

  /// No description provided for @eventWarning.
  ///
  /// In en, this message translates to:
  /// **'Distance warning'**
  String get eventWarning;

  /// No description provided for @eventLost.
  ///
  /// In en, this message translates to:
  /// **'Bag lost'**
  String get eventLost;

  /// No description provided for @eventPanicSent.
  ///
  /// In en, this message translates to:
  /// **'Panic packet sent'**
  String get eventPanicSent;

  /// No description provided for @eventConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get eventConnectionLost;

  /// No description provided for @eventReconnect.
  ///
  /// In en, this message translates to:
  /// **'Connection restored'**
  String get eventReconnect;

  /// No description provided for @eventRecovered.
  ///
  /// In en, this message translates to:
  /// **'Recovery in progress'**
  String get eventRecovered;

  /// No description provided for @eventFound.
  ///
  /// In en, this message translates to:
  /// **'Bag found'**
  String get eventFound;

  /// No description provided for @evSessionStarted.
  ///
  /// In en, this message translates to:
  /// **'Tracking session started · fused GPS + radio'**
  String get evSessionStarted;

  /// No description provided for @evUnusualDistance.
  ///
  /// In en, this message translates to:
  /// **'Unusual distance increase · {meters} m'**
  String evUnusualDistance(int meters);

  /// No description provided for @evDistanceExceeded.
  ///
  /// In en, this message translates to:
  /// **'Bag distance {meters} m · exceeded {limit} m limit'**
  String evDistanceExceeded(int meters, int limit);

  /// No description provided for @evBagGpsFix.
  ///
  /// In en, this message translates to:
  /// **'Bag GPS fix · ±{accuracy} m'**
  String evBagGpsFix(String accuracy);

  /// No description provided for @evBagGpsFixPanic.
  ///
  /// In en, this message translates to:
  /// **'Bag GPS fix · ±{accuracy} m · high-frequency'**
  String evBagGpsFixPanic(String accuracy);

  /// No description provided for @evLinkLost.
  ///
  /// In en, this message translates to:
  /// **'ESP32 radio link lost · retrying…'**
  String get evLinkLost;

  /// No description provided for @evLinkReestablished.
  ///
  /// In en, this message translates to:
  /// **'Radio link re-established · ESP32 handshake OK'**
  String get evLinkReestablished;

  /// No description provided for @evLinkRestored.
  ///
  /// In en, this message translates to:
  /// **'Radio link restored at {meters} m · fused fix accuracy ±{accuracy} m'**
  String evLinkRestored(int meters, String accuracy);

  /// No description provided for @evPanicPacket.
  ///
  /// In en, this message translates to:
  /// **'Panic packet → bag module · 1 Hz fix request'**
  String get evPanicPacket;

  /// No description provided for @evPanicPacketN.
  ///
  /// In en, this message translates to:
  /// **'Panic packet #{n} · requesting immediate fix'**
  String evPanicPacketN(int n);

  /// No description provided for @evRecoveryStarted.
  ///
  /// In en, this message translates to:
  /// **'Recovery started · navigating to last fused fix'**
  String get evRecoveryStarted;

  /// No description provided for @evRecoveryConfirmed.
  ///
  /// In en, this message translates to:
  /// **'User confirmed recovery at {meters} m'**
  String evRecoveryConfirmed(int meters);

  /// No description provided for @evMotionChanged.
  ///
  /// In en, this message translates to:
  /// **'Bag motion pattern changed · stationary'**
  String get evMotionChanged;

  /// No description provided for @capIntro.
  ///
  /// In en, this message translates to:
  /// **'Live tracking · bag within radio range'**
  String get capIntro;

  /// No description provided for @capDrifting.
  ///
  /// In en, this message translates to:
  /// **'Bag left behind · you are walking away'**
  String get capDrifting;

  /// No description provided for @capLeftBehind.
  ///
  /// In en, this message translates to:
  /// **'You walked on… the bag stayed at the café'**
  String get capLeftBehind;

  /// No description provided for @capWarning.
  ///
  /// In en, this message translates to:
  /// **'Distance growing · monitoring for loss'**
  String get capWarning;

  /// No description provided for @capLost.
  ///
  /// In en, this message translates to:
  /// **'Loss detected · panic mode initiating'**
  String get capLost;

  /// No description provided for @capPanic.
  ///
  /// In en, this message translates to:
  /// **'PANIC MODE · high-frequency pings every second'**
  String get capPanic;

  /// No description provided for @capReconnected.
  ///
  /// In en, this message translates to:
  /// **'Signal re-established · confirm your bag to end panic mode'**
  String get capReconnected;

  /// No description provided for @capNear.
  ///
  /// In en, this message translates to:
  /// **'You are within {meters} m of your bag'**
  String capNear(int meters);

  /// No description provided for @capRecovering.
  ///
  /// In en, this message translates to:
  /// **'Recovery route active · guiding you back'**
  String get capRecovering;

  /// No description provided for @capFound.
  ///
  /// In en, this message translates to:
  /// **'Bag recovered'**
  String get capFound;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
