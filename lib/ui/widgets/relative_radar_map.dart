import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';

/// Polar "where is the module" view for the live BLE source.
///
/// The ESP32 firmware has no GPS: it reports a path-loss distance and a
/// radar-sweep bearing (servo space 0–180°, 90° = straight ahead). This
/// widget plots exactly those measurements — rings in meters, the phone
/// at center, the module blip at the live bearing — instead of inventing
/// geographic coordinates.
class RelativeRadarMap extends StatefulWidget {
  final double distanceM;
  final double? bearingDeg;
  final int confidence; // 0..100
  final Color statusColor;
  final bool panic;
  final double maxRangeM;

  const RelativeRadarMap({
    super.key,
    required this.distanceM,
    required this.statusColor,
    this.bearingDeg,
    this.confidence = 0,
    this.panic = false,
    this.maxRangeM = 25,
  });

  @override
  State<RelativeRadarMap> createState() => _RelativeRadarMapState();
}

class _RelativeRadarMapState extends State<RelativeRadarMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return ColoredBox(
      color: tk.bgDeep,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                painter: _RadarPainter(
                  progress: _c.value,
                  distanceM: widget.distanceM,
                  bearingDeg: widget.bearingDeg,
                  confidence: widget.confidence,
                  statusColor: widget.statusColor,
                  panic: widget.panic,
                  maxRangeM: widget.maxRangeM,
                  dark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: _Legend(tk: tk, rings: const [1, 5, 10, 25]),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final TkColors tk;
  final List<int> rings;
  const _Legend({required this.tk, required this.rings});
  @override
  Widget build(BuildContext context) {
    return Text(
      rings.map((m) => '${m}m').join('  ·  '),
      style: TextStyle(fontSize: 10, color: tk.textTertiary, letterSpacing: .8),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  final double distanceM;
  final double? bearingDeg;
  final int confidence;
  final Color statusColor;
  final bool panic;
  final double maxRangeM;
  final bool dark;

  _RadarPainter({
    required this.progress,
    required this.distanceM,
    required this.bearingDeg,
    required this.confidence,
    required this.statusColor,
    required this.panic,
    required this.maxRangeM,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rMax = math.min(size.width, size.height) / 2 - 18;
    final accent = dark ? SmartBlue.c600 : SmartBlue.c500;
    final grid = dark ? Colors.white : SmartBlue.c100;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = grid.withValues(alpha: .14);
    for (final f in const [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawCircle(c, rMax * f, ringPaint);
    }

    // crosshair + forward marker
    final cross = Paint()
      ..strokeWidth = 1
      ..color = grid.withValues(alpha: .08);
    canvas.drawLine(Offset(c.dx - rMax, c.dy), Offset(c.dx + rMax, c.dy), cross);
    canvas.drawLine(Offset(c.dx, c.dy - rMax), Offset(c.dx, c.dy + rMax), cross);
    final fwd = Offset(c.dx, c.dy - rMax - 2);
    TextPainter(
      text: TextSpan(text: 'F', style: TextStyle(color: grid.withValues(alpha: .55), fontSize: 10, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(fwd, const Offset(-4, -10));

    // sweep
    final rect = Rect.fromCircle(center: c, radius: rMax);
    final start = -math.pi / 2 + progress * 2 * math.pi;
    const span = math.pi / 2.6;
    for (var i = 0; i < 36; i++) {
      final t = i / 36;
      final a0 = start - span + span * t;
      final a1 = a0 + span / 36 + 0.02;
      canvas.drawArc(rect, a0, a1 - a0, true,
          Paint()..color = accent.withValues(alpha: .22 * math.pow(1 - t, 1.8).toDouble()));
    }

    // module blip: linear distance mapping, live bearing (90° = up)
    final t = (distanceM / maxRangeM).clamp(0.0, 1.0).toDouble();
    final blipR = rMax * (0.12 + 0.88 * t);
    final bearing = bearingDeg;
    final angle = bearing == null ? -0.9 : (bearing - 90) * math.pi / 180;
    final blip = Offset(c.dx + blipR * math.sin(angle), c.dy - blipR * math.cos(angle));

    if (panic) {
      final pulse = (math.sin(progress * 2 * math.pi * 3) + 1) / 2;
      canvas.drawCircle(blip, 9 + pulse * 14,
          Paint()..color = Semantic.danger.withValues(alpha: .18 * (1 - pulse)));
    }

    // bearing confidence as halo strength
    final confAlpha = confidence > 0 ? 0.14 + 0.22 * confidence / 100 : 0.18;
    canvas.drawCircle(blip, 11, Paint()..color = statusColor.withValues(alpha: confAlpha));
    canvas.drawCircle(blip, 5.5, Paint()..color = statusColor);
    canvas.drawCircle(
      blip,
      5.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = (dark ? Colors.white : SmartBlue.c100).withValues(alpha: .95),
    );
    // connector line
    canvas.drawLine(
      c,
      blip,
      Paint()
        ..color = statusColor.withValues(alpha: .5)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // phone at center
    canvas.drawCircle(c, 7, Paint()..color = accent);
    canvas.drawCircle(
      c,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = (dark ? Colors.white : SmartBlue.c100),
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.progress != progress ||
      old.distanceM != distanceM ||
      old.bearingDeg != bearingDeg ||
      old.confidence != confidence ||
      old.panic != panic;
}
