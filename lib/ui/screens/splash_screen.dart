import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/l10n_text.dart';
import '../widgets/common.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final l = l10nOf(context);
    return Scaffold(
      backgroundColor: tk.bgDeep,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                painter: _SplashRings(progress: _c.value),
                child: Container(
                  width: 122,
                  height: 122,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: tk.stroke),
                    boxShadow: [
                      BoxShadow(
                        color: tk.accent.withValues(alpha: .35),
                        blurRadius: 44,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(33),
                    child: Image.asset(
                      'assets/brand/trackio_icon.png',
                      width: 122,
                      height: 122,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 34),
            const TkWordmark(size: 38),
            const SizedBox(height: 12),
            Text(
              l.tagline,
              style: TextStyle(fontSize: 13.5, color: tk.textTertiary, letterSpacing: .2),
            ),
            const SizedBox(height: 46),
            _LoadingDots(color: tk.accent),
          ],
        ),
      ),
    );
  }
}

class _SplashRings extends CustomPainter {
  final double progress;
  _SplashRings({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (final off in const [0.0, 0.4, 0.7]) {
      final t = (progress + off) % 1;
      canvas.drawCircle(
        c,
        70 + t * 90,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * (1 - t)
          ..color = SmartBlue.c600.withValues(alpha: .4 * (1 - t)),
      );
    }
  }
  @override
  bool shouldRepaint(_SplashRings old) => old.progress != progress;
}

class _LoadingDots extends StatefulWidget {
  final Color color;
  const _LoadingDots({required this.color});
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final t = (_c.value * 3 - i).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Transform.translate(
              offset: Offset(0, -6 * t),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: .35 + .65 * t),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
