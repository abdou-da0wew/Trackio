import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/mock_auth_service.dart';
import 'services/scenario_director.dart';
import 'services/settings_service.dart';
import 'services/simulation_engine.dart';
import 'services/sound_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // All three typefaces (Rubik / Jaro / Zain) are bundled under
  // assets/google_fonts/ — never fetch over the network at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;

  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsService(prefs);
  final auth = AuthService(prefs);
  final engine = SimulationEngine(settings);
  final sound = SoundService();
  final director = ScenarioDirector(engine);

  // demo/QA URL flags: ?theme=light|dark forces the theme for a session
  final q = Uri.base.queryParameters;
  if (q['theme'] == 'light') await settings.setThemeDark(false);
  if (q['theme'] == 'dark') await settings.setThemeDark(true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<SimulationEngine>.value(value: engine),
        Provider<SoundService>.value(value: sound),
        Provider<ScenarioDirector>.value(value: director),
      ],
      child: const TrackioApp(),
    ),
  );
}
