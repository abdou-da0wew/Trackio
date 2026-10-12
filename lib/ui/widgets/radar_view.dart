import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/palette.dart';

/// Animated radar sweep for the dashboard hero card.
/// Blip radius maps the phone↔bag distance (log scale, 5–500 m).
class RadarView extends StatefulWidget {
  final double distanceM;
  final Color statusColor;
  final bool panic;
  const RadarView({
    super.key,
    required this.distanceM,
    required this.statusColor,
    this.panic = false,
  });

  @override
  State<RadarView> createState() => _RadarViewState();
}

class _RadarViewState extends State<RadarView> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: _RadarPainter(
          progress: _c.value,
          distanceM: widget.distanceM,
          statusColor: widget.statusColor,
          panic: widget.panic,
          dark: Theme.of(context).brightness == Brightness.dark,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  final double distanceM;
  final Color statusColor;
  final bool panic;
  final bool dark;
  _RadarPainter({
    required this.progress,
    required this.distanceM,
    required this.statusColor,
    required this.panic,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rMax = math.min(size.width, size.height) / 2 - 6;
    final accent = dark ? SmartBlue.c600 : SmartBlue.c500;
    final grid = dark ? Colors.white : SmartBlue.c100;

    // rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = grid.withValues(alpha: .12);
    for (final f in const [0.28, 0.55, 0.82, 1.0]) {
      canvas.drawCircle(c, rMax * f, ringPaint);
    }
    // crosshair
    final crossPaint = Paint()
      ..strokeWidth = 1
      ..color = grid.withValues(alpha: .07);
    canvas.drawLine(Offset(c.dx - rMax, c.dy), Offset(c.dx + rMax, c.dy), crossPaint);
    canvas.drawLine(Offset(c.dx, c.dy - rMax), Offset(c.dx, c.dy + rMax), crossPaint);

    // sweep wedge (gradient by angle)
    final sweepRect = Rect.fromCircle(center: c, radius: rMax);
    final startAngle = -math.pi / 2 + progress * 2 * math.pi;
    const span = math.pi / 2.6;
    final steps = 42;
    for (var i = 0; i < steps; i++) {
      final t = i / steps;
      final a0 = startAngle - span + span * t;
      final a1 = a0 + span / steps + 0.02;
      final alpha = (0.26 * math.pow(1 - t, 1.8)).toDouble();
      canvas.drawArc(sweepRect, a0, a1 - a0, true,
          Paint()..color = accent.withValues(alpha: alpha));
    }
    // leading edge
    final edge = Offset(c.dx + rMax * math.cos(startAngle), c.dy + rMax * math.sin(startAngle));
    canvas.drawLine(c, edge, Paint()..color = accent.withValues(alpha: .8)..strokeWidth = 2);
    final dotStroke = dark ? Colors.white : SmartBlue.c100;

    // blip radius: log mapping 5..500 m → .18..1.0
    final t = ((math.log(distanceM) - math.log(4)) /
            (math.log(500) - math.log(4)))
        .clamp(0.0, 1.0)
        .toDouble();
    final blipR = rMax * (0.2 + 0.8 * t);

    // panic halo
    if (panic) {
      final pulse = (math.sin(progress * 2 * math.pi * 3) + 1) / 2;
      canvas.drawCircle(c, blipR + 10 + pulse * 16,
          Paint()..color = statusColor.withValues(alpha: .16 * (1 - pulse)));
    }

    // target ring + bag blip
    final blip = Offset(c.dx + blipR * math.cos(-0.9), c.dy + blipR * math.sin(-0.9));
    canvas.drawCircle(blip, 11, Paint()..color = statusColor.withValues(alpha: .25));
    canvas.drawCircle(blip, 5.5, Paint()..color = statusColor);
    canvas.drawCircle(blip, 5.5, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = dotStroke.withValues(alpha: .95));

    // center phone dot
    canvas.drawCircle(c, 7, Paint()..color = accent);
    canvas.drawCircle(c, 7, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..color = dotStroke);
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.progress != progress || old.distanceM != distanceM ||
      old.panic != panic || old.dark != dark;
}
