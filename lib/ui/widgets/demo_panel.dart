import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/l10n_text.dart';
import '../../services/scenario_director.dart';
import '../../services/simulation_engine.dart';
import 'common.dart';

/// Demo control surface: scripted movie mode + manual event injection.
/// Reachable from the small lab icon on the shell — meant for presenters.
class DemoPanel {
  static Future<void> show(
    BuildContext context, {
    required SimulationEngine engine,
    required ScenarioDirector director,
  }) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnimatedBuilder(
        animation: engine,
        builder: (ctx, _) => Container(
          decoration: BoxDecoration(
            color: tk.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: tk.stroke)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: tk.stroke,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      l.demoControls,
                      style: GoogleFonts.rubik(fontSize: 19, fontWeight: FontWeight.w700, color: tk.textPrimary),
                    ),
                    const Spacer(),
                    IconButton2(icon: Icons.close_rounded, onTap: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l.demoSubtitle,
                  style: TextStyle(fontSize: 12.5, color: tk.textSecondary),
                ),
                const SizedBox(height: 16),
                // scripted scenario
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tk.bgDeep,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: tk.stroke),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 17, color: tk.accent),
                          const SizedBox(width: 8),
                          Text(
                            l.scriptedScenario,
                            style: GoogleFonts.rubik(fontWeight: FontWeight.w700, fontSize: 14, color: tk.textPrimary),
                          ),
                          const Spacer(),
                          if (engine.scenarioPhase != null)
                            Flexible(
                              child: Text(
                                l.scenarioCaption(engine),
                                textAlign: TextAlign.start,
                                maxLines: 2,
                                style: TextStyle(fontSize: 10.5, color: tk.textTertiary),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      engine.scenarioRunning
                          ? OutlinedButton(
                              onPressed: () {
                                director.stop();
                                engine.resetSession();
                              },
                              child: Text(l.stopScenario),
                            )
                          : GradientButton(
                              label: l.startScenario,
                              icon: Icons.play_arrow_rounded,
                              onTap: () => director.start(),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l.manualTriggers,
                  style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: tk.textTertiary),
                ),
                const SizedBox(height: 10),
                _Grid(engine: engine),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      l.speed,
                      style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: tk.textTertiary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SegmentedButton<double>(
                        segments: const [
                          ButtonSegment(value: 1.0, label: Text('1×')),
                          ButtonSegment(value: 4.0, label: Text('4×')),
                          ButtonSegment(value: 8.0, label: Text('8×')),
                        ],
                        selected: {engine.speedMultiplier},
                        onSelectionChanged: (s) => engine.setSpeed(s.first),
                        showSelectedIcon: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final SimulationEngine engine;
  const _Grid({required this.engine});

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final items = [
      (l.trigLeftBag, Icons.luggage_rounded, engine.driftAway),
      (l.trigCutLink, Icons.link_off_rounded, engine.cutConnection),
      (l.trigPanicPacket, Icons.crisis_alert_rounded, engine.enterPanic),
      (l.trigRecover, Icons.navigation_rounded, engine.beginRecovery),
      (l.trigMarkFound, Icons.verified_rounded, engine.markFound),
      (l.trigReset, Icons.restart_alt_rounded, () => engine.resetSession()),
    ];
    final tk = tkOf(context);
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.12,
      children: [
        for (final (label, icon, action) in items)
          Material(
            color: tk.bgDeep,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: action,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: tk.accent),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: tk.textSecondary, height: 1.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
