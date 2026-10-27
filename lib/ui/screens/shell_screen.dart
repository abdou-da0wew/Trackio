import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n_text.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/scenario_director.dart';
import '../../services/settings_service.dart';
import '../../services/simulation_engine.dart';
import '../../services/sound_service.dart';
import '../../services/tracking/tracking_controller.dart';
import '../../services/tracking/tracking_engine.dart';
import '../widgets/alert_overlay.dart';
import '../widgets/demo_panel.dart';
import '../widgets/device_panel.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

/// App shell: 4 tabs + alert overlay + scenario caption HUD + lab/device panel.
///
/// Perf note: the shell does NOT rebuild on engine ticks. Sound edge-triggers
/// and the "found" confirmation live in an engine listener; the two widgets
/// that need live data (caption HUD, alert overlay) listen to the engine
/// themselves, so tab content stays steady while telemetry flows.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;
  bool _readArgs = false;
  bool _wasDanger = false;
  TrackStatus _prevStatus = TrackStatus.tracking;
  TrackingEngine? _engine;

  @override
  void initState() {
    super.initState();
    // demo/QA flag: ?panel=1 opens the control sheet automatically
    if (Uri.base.queryParameters['panel'] == '1') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openPanel();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final engine = context.read<TrackingController>().engine;
    if (_engine != engine) {
      _engine?.removeListener(_onEngineTick);
      _engine = engine..addListener(_onEngineTick);
    }
    if (!_readArgs) {
      _readArgs = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is int && arg >= 0 && arg <= 3) _index = arg;
    }
  }

  @override
  void dispose() {
    _engine?.removeListener(_onEngineTick);
    super.dispose();
  }

  /// Edge-triggered sound hooks + recovery confirmation toast.
  void _onEngineTick() {
    if (!mounted) return;
    final engine = _engine!;
    final sound = context.read<SoundService>();
    final settings = context.read<SettingsService>();
    if (engine.inDanger && !_wasDanger) {
      sound.playAlert(settings.sound);
    }
    if (engine.status == TrackStatus.found && _prevStatus != TrackStatus.found) {
      sound.playSuccess();
      final l = l10nOf(context);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.verified_rounded, size: 18, color: Semantic.success),
                const SizedBox(width: 10),
                Expanded(child: Text(l.foundToast)),
              ],
            ),
          ),
        );
    }
    _wasDanger = engine.inDanger;
    _prevStatus = engine.status;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrackingController>();
    final engine = controller.engine;
    final l = l10nOf(context);
    final tk = tkOf(context);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: [
              DashboardScreen(onGoMap: () => setState(() => _index = 1), onDemo: _openPanel),
              MapScreen(onDemo: _openPanel),
              const HistoryScreen(),
              const SettingsScreen(),
            ],
          ),
          // scenario caption HUD — listens to the engine in isolation
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 18,
            right: 18,
            child: IgnorePointer(
              child: ListenableBuilder(
                listenable: engine,
                builder: (context, _) {
                  final text = engine.scenarioRunning ? l.scenarioCaption(engine) : '';
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    child: text.isNotEmpty
                        ? _CaptionHud(key: ValueKey(text), text: text)
                        : const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),
          // alert overlay
          AlertOverlay(
            engine: engine,
            onOpenMap: () {
              engine.clearAlertFlag();
              setState(() => _index = 1);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'device-lab',
        elevation: 0,
        backgroundColor: tk.card,
        foregroundColor: tk.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: tk.stroke),
        ),
        onPressed: _openPanel,
        child: Icon(
          controller.isLive ? Icons.bluetooth_rounded : Icons.science_rounded,
          size: 20,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.space_dashboard_outlined), selectedIcon: const Icon(Icons.space_dashboard_rounded), label: l.tabHome),
          NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map_rounded), label: l.tabMap),
          NavigationDestination(icon: const Icon(Icons.history_outlined), selectedIcon: const Icon(Icons.history_rounded), label: l.tabHistory),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings_rounded), label: l.tabSettings),
        ],
      ),
    );
  }

  /// BLE source → the real device panel; simulation source → the demo lab.
  void _openPanel() {
    final controller = context.read<TrackingController>();
    if (controller.isLive) {
      DevicePanel.show(context, ble: context.read());
    } else {
      DemoPanel.show(
        context,
        engine: context.read<SimulationEngine>(),
        director: context.read<ScenarioDirector>(),
      );
    }
  }
}

class _CaptionHud extends StatelessWidget {
  final String text;
  const _CaptionHud({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: tk.card.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tk.accent.withValues(alpha: .5)),
        boxShadow: [BoxShadow(color: tk.accent.withValues(alpha: .18), blurRadius: 22)],
      ),
      child: Row(
        children: [
          Icon(Icons.theaters_rounded, size: 16, color: tk.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: tk.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
