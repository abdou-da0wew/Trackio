import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/fonts.dart';
import 'core/theme.dart';
import 'services/mock_auth_service.dart';
import 'services/settings_service.dart';
import 'services/simulation_engine.dart';
import 'ui/auth/login_signup.dart';
import 'ui/auth/otp_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/shell_screen.dart';
import 'ui/screens/splash_screen.dart';

class TrackioApp extends StatelessWidget {
  const TrackioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return MaterialApp(
      title: 'Trackio',
      debugShowCheckedModeBanner: false,
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: Tk.theme(Brightness.light),
      darkTheme: Tk.theme(Brightness.dark),
      themeMode: settings.themeMode,
      // Typeface plan (core/fonts.dart): Rubik = English · Jaro = logo only ·
      // Zain = Arabic only. When the platform/browser locale resolves to `ar`,
      // this builder re-themes the tree with the Zain text theme so every
      // widget — including AppBar titles — renders in Zain without per-widget
      // changes. English and other locales keep Rubik untouched.
      builder: (context, child) {
        final locale = Localizations.localeOf(context);
        if (locale.languageCode != 'ar') return child!;
        final base = Theme.of(context);
        final zain = AppFonts.arabic(base.textTheme);
        return Theme(
          data: base.copyWith(
            textTheme: zain,
            appBarTheme: base.appBarTheme.copyWith(
              titleTextStyle: zain.titleLarge?.copyWith(
                color: base.appBarTheme.foregroundColor,
              ),
            ),
          ),
          child: child!,
        );
      },
      home: _EntryGate(),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/otp': (_) => const OtpScreen(),
        '/shell': (_) => const ShellScreen(),
      },
    );
  }
}

/// Decides the first screen: splash (normal) or a deep-linked demo screen
/// (`?shot=<target>&state=<pose>` — used for QA walkthroughs and stage setups).
class _EntryGate extends StatefulWidget {
  @override
  State<_EntryGate> createState() => _EntryGateState();
}

class _EntryGateState extends State<_EntryGate> {
  String? _shot;
  String _state = 'tracking';

  @override
  void initState() {
    super.initState();
    final uri = Uri.base;
    _shot = uri.queryParameters['shot'];
    _state = uri.queryParameters['state'] ?? 'tracking';
  }

  @override
  Widget build(BuildContext context) {
    if (_shot == null || _shot == 'splash') {
      return const _SplashRouter();
    }
    return _ShotLauncher(target: _shot!, state: _state);
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();
  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2300), _route);
  }

  void _route() {
    if (!mounted) return;
    final auth = context.read<AuthService>();
    final settings = context.read<SettingsService>();
    if (auth.user != null) {
      Navigator.pushReplacementNamed(context, '/shell');
    } else {
      Navigator.pushReplacementNamed(
        context,
        settings.onboardingSeen ? '/login' : '/onboarding',
      );
    }
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}

/// Jumps straight to a screen with a deterministic engine pose.
class _ShotLauncher extends StatefulWidget {
  final String target;
  final String state;
  const _ShotLauncher({required this.target, required this.state});
  @override
  State<_ShotLauncher> createState() => _ShotLauncherState();
}

class _ShotLauncherState extends State<_ShotLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthService>();
      if (auth.user == null) {
        await auth.login(email: 'demo@trackio.app');
      }
      if (!mounted) return;
      final engine = context.read<SimulationEngine>();
      engine.poseForShot(widget.state);
      if (!mounted) return;
      const tabByTarget = {
        'home': 0, 'map': 1, 'history': 2, 'settings': 3,
      };
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/shell',
        (_) => false,
        arguments: tabByTarget[widget.target] ?? 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
