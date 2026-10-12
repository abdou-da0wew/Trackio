import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/scenario_director.dart';
import '../../services/settings_service.dart';
import '../../services/simulation_engine.dart';
import '../../services/sound_service.dart';
import '../widgets/alert_overlay.dart';
import '../widgets/demo_panel.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

/// App shell: 4 tabs + alert overlay + scenario caption HUD + demo lab.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;
  bool _readArgs = false;

  @override
  void initState() {
    super.initState();
    // demo/QA flag: ?panel=1 opens the demo control sheet automatically
    if (Uri.base.queryParameters['panel'] == '1') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openDemo();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_readArgs) {
      _readArgs = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is int && arg >= 0 && arg <= 3) _index = arg;
    }
  }
  bool _wasDanger = false;
  TrackStatus _prevStatus = TrackStatus.tracking;

  @override
  Widget build(BuildContext context) {
    final engine = context.read<SimulationEngine>();
    final sound = context.read<SoundService>();
    final settings = context.read<SettingsService>();

    return Scaffold(
      body: AnimatedBuilder(
        animation: engine,
        builder: (context, _) {
          // alert sound hooks (edge-triggered)
          if (engine.inDanger && !_wasDanger) {
            sound.playAlert(settings.sound);
          }
          if (engine.status == TrackStatus.found && _prevStatus != TrackStatus.found) {
            sound.playSuccess();
          }
          _wasDanger = engine.inDanger;
          _prevStatus = engine.status;

          return Stack(
            children: [
              IndexedStack(
                index: _index,
                children: [
                  DashboardScreen(onGoMap: () => setState(() => _index = 1), onDemo: _openDemo),
                  MapScreen(onDemo: _openDemo),
                  const HistoryScreen(),
                  const SettingsScreen(),
                ],
              ),
              // scenario caption HUD
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 18,
                right: 18,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    child: engine.scenarioRunning && engine.scenarioCaption != null
                        ? _CaptionHud(key: ValueKey(engine.scenarioCaption), engine: engine)
                        : const SizedBox.shrink(),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'demo-lab',
        elevation: 0,
        backgroundColor: tkOf(context).card,
        foregroundColor: tkOf(context).accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: tkOf(context).stroke),
        ),
        onPressed: _openDemo,
        child: const Icon(Icons.science_rounded, size: 20),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }

  void _openDemo() {
    final engine = context.read<SimulationEngine>();
    final director = context.read<ScenarioDirector>();
    DemoPanel.show(context, engine: engine, director: director);
  }
}

class _CaptionHud extends StatelessWidget {
  final SimulationEngine engine;
  const _CaptionHud({super.key, required this.engine});

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
              engine.scenarioCaption!,
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
