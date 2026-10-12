// ignore_for_file: prefer_const_constructors_in_immutables
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/palette.dart';
import '../../models/models.dart';
import 'common.dart';

/// Live markers for the tracking map.

class PhoneDotMarker extends Marker {
  PhoneDotMarker(LatLng point)
      : super(
          point: point,
          width: 46,
          height: 46,
          alignment: Alignment.center,
          child: const _PulseDot(),
        );
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
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
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SmartBlue.c600.withValues(alpha: .25 * (1 - _c.value)),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SmartBlue.c600,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: SmartBlue.c600.withValues(alpha: .5), blurRadius: 10)],
            ),
          ),
        ],
      ),
    );
  }
}

class BagPinMarker extends Marker {
  BagPinMarker(LatLng point, TrackStatus status)
      : super(
          point: point,
          width: 52,
          height: 62,
          alignment: Alignment.topCenter,
          child: _BagPin(status: status),
        );
}

class _BagPin extends StatefulWidget {
  final TrackStatus status;
  const _BagPin({required this.status});
  @override
  State<_BagPin> createState() => _BagPinState();
}

class _BagPinState extends State<_BagPin> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = StatusTheme.of(widget.status);
    final pin = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Prussian3.c900],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: st.color, width: 3),
            boxShadow: [
              BoxShadow(color: st.color.withValues(alpha: .45), blurRadius: 12),
            ],
          ),
          child: Icon(Icons.backpack_rounded, size: 20, color: Prussian3.c500),
        ),
        CustomPaint(size: const Size(14, 9), painter: _PinTail(color: st.color)),
      ],
    );
    final danger = widget.status == TrackStatus.lost || widget.status == TrackStatus.panic;
    if (!danger) return pin;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Transform.scale(
        scale: 1 + _c.value * .07,
        child: pin,
      ),
    );
  }
}

class _PinTail extends CustomPainter {
  final Color color;
  _PinTail({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = ui.Path()
      ..moveTo(size.width * .5, size.height)
      ..lineTo(size.width * .12, 0)
      ..lineTo(size.width * .88, 0)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }
  @override
  bool shouldRepaint(_PinTail old) => old.color != color;
}

/// Expanding radar rings emitted around the bag during panic mode.
class PanicPulseMarker extends Marker {
  PanicPulseMarker(LatLng point)
      : super(
          point: point,
          width: 160,
          height: 160,
          alignment: Alignment.center,
          child: const _PanicRings(),
        );
}

class _PanicRings extends StatefulWidget {
  const _PanicRings();
  @override
  State<_PanicRings> createState() => _PanicRingsState();
}

class _PanicRingsState extends State<_PanicRings> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000))
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
      builder: (_, _) => CustomPaint(
        painter: _RingsPainter(progress: _c.value),
        size: const Size(160, 160),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double progress;
  _RingsPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (final off in const [0.0, 0.5]) {
      final t = (progress + off) % 1.0;
      canvas.drawCircle(
        c,
        8 + t * 66,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * (1 - t)
          ..color = Semantic.danger.withValues(alpha: .55 * (1 - t)),
      );
    }
  }
  @override
  bool shouldRepaint(_RingsPainter old) => old.progress != progress;
}

/// Distance pill floating between the two markers.
class DistanceLabelMarker extends Marker {
  DistanceLabelMarker(LatLng point, String text, {Color? color})
      : super(
          point: point,
          width: 96,
          height: 30,
          alignment: Alignment.center,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Prussian3.c100.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color ?? SmartBlue.c600, width: 1.2),
              ),
              child: Text(
                text,
                style: GoogleFonts.rubik(fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
}
