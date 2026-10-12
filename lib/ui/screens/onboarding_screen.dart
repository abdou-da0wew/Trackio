import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../services/settings_service.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      Icons.radar_rounded,
      'See your bag, always',
      'Trackio fuses your phone GPS, the bag\'s own GPS and the ESP32 radio link into one live, continuous fix on your bag.',
    ),
    (
      Icons.crisis_alert_rounded,
      'Know the moment it leaves',
      'Abnormal distance triggers an instant alert. Panic packets ask the bag module for high-frequency, high-accuracy fixes.',
    ),
    (
      Icons.map_rounded,
      'Get it back, fast',
      'A guided recovery route reconciles every location source until you\'re reunited — then you confirm it with one tap.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<SettingsService>().setOnboardingSeen();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: TextButton(onPressed: _finish, child: const Text('Skip')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final (icon, title, body) = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Illustration(icon: icon, index: i),
                        const SizedBox(height: 46),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: tk.textPrimary,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.6,
                            color: tk.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 0, 34, 26),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? tk.accent : tk.stroke,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 26),
                  GradientButton(
                    label: _page == 2 ? 'Get started' : 'Next',
                    icon: _page == 2 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                    onTap: () {
                      if (_page == 2) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final IconData icon;
  final int index;
  const _Illustration({required this.icon, required this.index});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [tk.accent.withValues(alpha: .16), tk.bg.withValues(alpha: 0)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tk.card,
              border: Border.all(color: tk.stroke),
              boxShadow: [
                BoxShadow(color: tk.accent.withValues(alpha: .18), blurRadius: 40),
              ],
            ),
          ),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: tk.ctaGradient),
            ),
            child: Icon(icon, size: 46, color: Colors.white),
          ),
          // orbiting dots for motion
          for (final (a, r) in const [(0.6, 88.0), (2.6, 88.0), (4.4, 88.0)])
            Positioned(
              left: 110 + r * math.cos(a) - 4,
              top: 110 + r * math.sin(a) - 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index.isEven ? SmartBlue.c700 : Sapphire.c700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
