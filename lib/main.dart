import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/ble/esp32_ble_service.dart';
import 'services/mock_auth_service.dart';
import 'services/scenario_director.dart';
import 'services/settings_service.dart';
import 'services/simulation_engine.dart';
import 'services/sound_service.dart';
import 'services/tracking/ble_tracking_engine.dart';
import 'services/tracking/tracking_controller.dart';
import 'services/tracking/tracking_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // All three typefaces (Rubik / Jaro / Zain) are bundled under
  // assets/google_fonts/ — never fetch over the network at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;

  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsService(prefs);
  final auth = AuthService(prefs);
  final sound = SoundService();

  // Real ESP32 BLE link + the live tracking engine it feeds.
  final ble = Esp32BleService(prefs);
  unawaited(ble.bootstrap());
  final bleEngine = BleTrackingEngine(ble, settings);

  // Deterministic simulation kept as an explicit offline / QA source.
  final simEngine = SimulationEngine(settings);
  simEngine.start();

  final controller = TrackingController(
    ble: bleEngine,
    simulation: simEngine,
    initial: TrackingSource.ble,
  );
  final director = ScenarioDirector(simEngine);

  // demo/QA URL flags: ?theme=light|dark forces the theme for a session
  final q = Uri.base.queryParameters;
  if (q['theme'] == 'light') await settings.setThemeDark(false);
  if (q['theme'] == 'dark') await settings.setThemeDark(true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<Esp32BleService>.value(value: ble),
        // Single source of truth: the controller exposes the active engine
        // (live BLE by default, simulation when explicitly chosen).
        ChangeNotifierProvider<TrackingController>.value(value: controller),
        // Concrete simulator remains available to the demo lab / director.
        ChangeNotifierProvider<SimulationEngine>.value(value: simEngine),
        Provider<SoundService>.value(value: sound),
        Provider<ScenarioDirector>.value(value: director),
      ],
      child: const TrackioApp(),
    ),
  );
}
