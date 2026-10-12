// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get tagline => 'Never lose sight of what carries your day.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboarding1Title => 'See your bag, always';

  @override
  String get onboarding1Body =>
      'Trackio fuses your phone GPS, the bag\'s own GPS and the ESP32 radio link into one live, continuous fix on your bag.';

  @override
  String get onboarding2Title => 'Know the moment it leaves';

  @override
  String get onboarding2Body =>
      'Abnormal distance triggers an instant alert. Panic packets ask the bag module for high-frequency, high-accuracy fixes.';

  @override
  String get onboarding3Title => 'Get it back, fast';

  @override
  String get onboarding3Body =>
      'A guided recovery route reconciles every location source until you\'re reunited — then you confirm it with one tap.';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to keep your bag within reach.';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign in';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get newToTrackio => 'New to Trackio?';

  @override
  String get createAccount => 'Create an account';

  @override
  String get demoLoginBanner => 'Demo build — any credentials sign you in.';

  @override
  String get errEnterEmail => 'Enter an email to continue the demo';

  @override
  String get signupTitle => 'Create your account';

  @override
  String get signupSubtitle => 'One account for every bag you track.';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get continueLabel => 'Continue';

  @override
  String get creating => 'Creating…';

  @override
  String get demoSignupBanner =>
      'Demo build — signup generates a mock OTP shown on the next screen.';

  @override
  String get errFillNameEmail => 'Fill your name and email to continue';

  @override
  String get otpTitle => 'Verify your email';

  @override
  String otpSentTo(String email) {
    return 'We sent a 6-digit code to $email.';
  }

  @override
  String get otpFallbackEmail => 'your email';

  @override
  String get otpIncorrect => 'Incorrect code — check the demo hint below.';

  @override
  String get otpVerify => 'Verify & continue';

  @override
  String get otpVerifying => 'Verifying…';

  @override
  String otpResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get otpResend => 'Resend code';

  @override
  String otpDemoHint(String code) {
    return 'Demo OTP: $code — production sends this via Supabase.';
  }

  @override
  String get otpDemoNoCode => 'Demo build — OTP shown here instead of email.';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get tabHome => 'Home';

  @override
  String get tabMap => 'Map';

  @override
  String get tabHistory => 'History';

  @override
  String get tabSettings => 'Settings';

  @override
  String get statusTracking => 'TRACKING';

  @override
  String get statusWarning => 'DISTANCE WARNING';

  @override
  String get statusLost => 'POSSIBLY LOST';

  @override
  String get statusPanic => 'PANIC MODE';

  @override
  String get statusRecovering => 'RECOVERING';

  @override
  String get statusRecovered => 'RECOVERED';

  @override
  String goodMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get demoUser => 'Demo User';

  @override
  String updatedAgo(String ago) {
    return 'updated $ago';
  }

  @override
  String get agoNow => 'now';

  @override
  String agoSeconds(int n) {
    return '${n}s ago';
  }

  @override
  String agoMinutes(int n) {
    return '${n}m ago';
  }

  @override
  String agoHours(int n) {
    return '${n}h ago';
  }

  @override
  String radioLinkDown(int retries) {
    return 'radio link down · retrying ($retries)';
  }

  @override
  String get fromYourBag => 'from your bag · fused GPS + ESP32 radio';

  @override
  String get linkLost => 'link lost';

  @override
  String get noFix => 'no fix';

  @override
  String get locateBag => 'Locate bag';

  @override
  String get ringTag => 'Ring tag';

  @override
  String get demoMode => 'Demo mode';

  @override
  String playingOnBag(String sound) {
    return 'Playing $sound on the bag module';
  }

  @override
  String get livePosition => 'LIVE POSITION';

  @override
  String get openMap => 'Open map';

  @override
  String get recentActivity => 'RECENT ACTIVITY';

  @override
  String get unitMeters => 'm';

  @override
  String get unitKm => 'km';

  @override
  String get mapTooltipDemo => 'Demo controls';

  @override
  String get tooltipFollow => 'Follow me';

  @override
  String get tooltipCenterBag => 'Center on bag';

  @override
  String get tooltipFitBoth => 'Fit both';

  @override
  String mapSignalLost(int retries) {
    return 'signal lost · retry #$retries';
  }

  @override
  String bagFixLine(String accuracy, String rssi, int battery) {
    return '±$accuracy m fix · $rssi · battery $battery%';
  }

  @override
  String get buzzQueued => 'Buzz command queued on ESP32 module';

  @override
  String get alertTitle => 'Your bag may be lost';

  @override
  String get alertBody =>
      'Distance exceeded your safety limit. Trackio is pinging the bag module at 1 Hz and fusing GPS + radio fixes to pinpoint it.';

  @override
  String get statLiveDistance => 'LIVE DISTANCE';

  @override
  String get statPanicPackets => 'PANIC PACKETS';

  @override
  String get statRadioRetries => 'RADIO RETRIES';

  @override
  String get openRecoveryMap => 'Open recovery map';

  @override
  String get iFoundMyBag => 'I found my bag';

  @override
  String get minimise => 'Minimise';

  @override
  String get foundToast => 'Bag recovered — welcome back!';

  @override
  String get demoControls => 'Demo Controls';

  @override
  String get demoSubtitle =>
      'Play the full loss-recovery story, or trigger individual events manually.';

  @override
  String get scriptedScenario => 'Scripted scenario';

  @override
  String get stopScenario => 'Stop scenario';

  @override
  String get startScenario => 'Start demo scenario';

  @override
  String get manualTriggers => 'MANUAL TRIGGERS';

  @override
  String get speed => 'SPEED';

  @override
  String get trigLeftBag => 'Left bag behind';

  @override
  String get trigCutLink => 'Cut radio link';

  @override
  String get trigPanicPacket => 'Panic packet';

  @override
  String get trigRecover => 'Recover';

  @override
  String get trigMarkFound => 'Mark found';

  @override
  String get trigReset => 'Reset session';

  @override
  String get historyTitle => 'History';

  @override
  String get lossAlerts => 'LOSS ALERTS';

  @override
  String get avgDistance => 'AVG DISTANCE';

  @override
  String get dataPoints => 'DATA POINTS';

  @override
  String get distanceTimeline => 'DISTANCE TIMELINE';

  @override
  String get legendSafe => 'safe range';

  @override
  String get legendLoss => 'loss events';

  @override
  String get eventLog => 'EVENT LOG';

  @override
  String get noEventsYet => 'No events yet — start the demo scenario.';

  @override
  String get collectingData => 'Collecting tracking data…';

  @override
  String get lossLimit => 'loss limit';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAppearance => 'APPEARANCE';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get sectionLanguage => 'LANGUAGE';

  @override
  String get langSystem => 'System';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get sectionSound => 'LOST-BAG ALERT SOUND';

  @override
  String get soundSonarPing => 'Sonar Ping';

  @override
  String get soundAlarmPulse => 'Alarm Pulse';

  @override
  String get soundGentleChime => 'Gentle Chime';

  @override
  String get soundPreview => 'Preview';

  @override
  String get sectionIntervals => 'TRACKING & GPS INTERVALS';

  @override
  String get intervalPhoneGps => 'Phone GPS update';

  @override
  String get intervalBagGps => 'Bag GPS update';

  @override
  String get intervalRecheck => 'Distance recheck';

  @override
  String intervalSeconds(int value) {
    return '${value}s';
  }

  @override
  String get intervalsNote =>
      'Panic mode overrides these: the bag module switches to 1 Hz fixes until you confirm recovery.';

  @override
  String get sectionConnection => 'CONNECTION';

  @override
  String get backendSupabase => 'Supabase · self-hosted VDS';

  @override
  String get supabaseSyncing => 'syncing events · demo';

  @override
  String get supabaseAuth => 'auth + tracking sync';

  @override
  String get backendTigris => 'Tigris object storage';

  @override
  String get tigrisSubtitle => 'route archives & exports';

  @override
  String get connected => 'Connected';

  @override
  String get down => 'Down';

  @override
  String get sectionAccount => 'ACCOUNT';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out of Trackio?';

  @override
  String get signOutBody =>
      'Your demo session and local tracking data stay on this device.';

  @override
  String get versionLine =>
      'Trackio 1.0.0 · demo build for stakeholder preview';

  @override
  String get eventLocationUpdate => 'Location update';

  @override
  String get eventWarning => 'Distance warning';

  @override
  String get eventLost => 'Bag lost';

  @override
  String get eventPanicSent => 'Panic packet sent';

  @override
  String get eventConnectionLost => 'Connection lost';

  @override
  String get eventReconnect => 'Connection restored';

  @override
  String get eventRecovered => 'Recovery in progress';

  @override
  String get eventFound => 'Bag found';

  @override
  String get evSessionStarted => 'Tracking session started · fused GPS + radio';

  @override
  String evUnusualDistance(int meters) {
    return 'Unusual distance increase · $meters m';
  }

  @override
  String evDistanceExceeded(int meters, int limit) {
    return 'Bag distance $meters m · exceeded $limit m limit';
  }

  @override
  String evBagGpsFix(String accuracy) {
    return 'Bag GPS fix · ±$accuracy m';
  }

  @override
  String evBagGpsFixPanic(String accuracy) {
    return 'Bag GPS fix · ±$accuracy m · high-frequency';
  }

  @override
  String get evLinkLost => 'ESP32 radio link lost · retrying…';

  @override
  String get evLinkReestablished =>
      'Radio link re-established · ESP32 handshake OK';

  @override
  String evLinkRestored(int meters, String accuracy) {
    return 'Radio link restored at $meters m · fused fix accuracy ±$accuracy m';
  }

  @override
  String get evPanicPacket => 'Panic packet → bag module · 1 Hz fix request';

  @override
  String evPanicPacketN(int n) {
    return 'Panic packet #$n · requesting immediate fix';
  }

  @override
  String get evRecoveryStarted =>
      'Recovery started · navigating to last fused fix';

  @override
  String evRecoveryConfirmed(int meters) {
    return 'User confirmed recovery at $meters m';
  }

  @override
  String get evMotionChanged => 'Bag motion pattern changed · stationary';

  @override
  String get capIntro => 'Live tracking · bag within radio range';

  @override
  String get capDrifting => 'Bag left behind · you are walking away';

  @override
  String get capLeftBehind => 'You walked on… the bag stayed at the café';

  @override
  String get capWarning => 'Distance growing · monitoring for loss';

  @override
  String get capLost => 'Loss detected · panic mode initiating';

  @override
  String get capPanic => 'PANIC MODE · high-frequency pings every second';

  @override
  String get capReconnected =>
      'Signal re-established · confirm your bag to end panic mode';

  @override
  String capNear(int meters) {
    return 'You are within $meters m of your bag';
  }

  @override
  String get capRecovering => 'Recovery route active · guiding you back';

  @override
  String get capFound => 'Bag recovered';
}
