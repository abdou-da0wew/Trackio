import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/l10n_text.dart';
import '../../models/models.dart';
import '../../services/tracking/tracking_engine.dart';
import 'common.dart';

/// Full-screen alert layer shown while a loss event is active.
/// Stays mounted inside the shell stack; visibility is driven by
/// [TrackingEngine.lostAlertActive].
class AlertOverlay extends StatefulWidget {
  final TrackingEngine engine;
  final VoidCallback onOpenMap;
  const AlertOverlay({super.key, required this.engine, required this.onOpenMap});

  @override
  State<AlertOverlay> createState() => _AlertOverlayState();
}

class _AlertOverlayState extends State<AlertOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final e = widget.engine;
        final visible = e.lostAlertActive || e.inDanger;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: visible
              ? _AlertBody(key: const ValueKey('alert'), engine: e, onOpenMap: widget.onOpenMap, anim: _c)
              : const SizedBox.shrink(key: ValueKey('hidden')),
        );
      },
    );
  }
}

class _AlertBody extends StatelessWidget {
  final TrackingEngine engine;
  final VoidCallback onOpenMap;
  final AnimationController anim;
  const _AlertBody({super.key, required this.engine, required this.onOpenMap, required this.anim});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    final e = engine;
    return Container(
      color: Prussian3.c100.withValues(alpha: .885),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const StatusPill(status: TrackStatus.panic, pulse: true),
                  const Spacer(),
                  IconButton2(
                    icon: Icons.close_rounded,
                    onTap: onOpenMap, // collapse overlay, keep panic HUD minimal on map
                    tooltip: l.minimise,
                  ),
                ],
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: anim,
                builder: (context, _) => Center(
                  child: CustomPaint(
                    painter: _AlertRings(progress: anim.value, color: Semantic.danger),
                    child: Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Semantic.danger.withValues(alpha: .14),
                        border: Border.all(color: Semantic.danger, width: 2),
                      ),
                      child: const Icon(Icons.crisis_alert_rounded, size: 52, color: Semantic.danger),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                l.alertTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: tk.textPrimary,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l.alertBody,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.5, color: tk.textSecondary),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _AlertStat(
                      label: l.statLiveDistance,
                      value: l.dist(e.distance),
                      color: Semantic.danger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AlertStat(
                      label: l.statPanicPackets,
                      value: '${e.panicPacketsSent}',
                      color: SmartBlue.c700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AlertStat(
                      label: l.statRadioRetries,
                      value: e.connectionCut ? '${e.radioRetries}' : '—',
                      color: Semantic.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              GradientButton(
                label: l.openRecoveryMap,
                icon: Icons.map_rounded,
                onTap: onOpenMap,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => engine.markFound(),
                icon: const Icon(Icons.verified_rounded, size: 20),
                label: Text(l.iFoundMyBag),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AlertStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: tk.card.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tk.stroke),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: tk.textTertiary),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: GoogleFonts.rubik(fontSize: 21, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _AlertRings extends CustomPainter {
  final double progress;
  final Color color;
  _AlertRings({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (final off in const [0.0, 0.34, 0.67]) {
      final t = (progress + off) % 1;
      canvas.drawCircle(
        c,
        60 + t * 66,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6 * (1 - t)
          ..color = color.withValues(alpha: .5 * (1 - t)),
      );
    }
  }
  @override
  bool shouldRepaint(_AlertRings old) => old.progress != progress;
}
