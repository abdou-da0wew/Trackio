import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/fonts.dart';
import '../../core/l10n_text.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

/// Status → color / icon mapping used everywhere.
/// (Labels are localized — see `AppLocalizationsX.statusLabel`.)
class StatusTheme {
  final Color color;
  final IconData icon;
  const StatusTheme(this.color, this.icon);

  static StatusTheme of(TrackStatus s) => switch (s) {
        TrackStatus.tracking => const StatusTheme(SmartBlue.c600, Icons.radar_rounded),
        TrackStatus.warning => const StatusTheme(Semantic.warning, Icons.warning_amber_rounded),
        TrackStatus.lost => const StatusTheme(Semantic.danger, Icons.location_off_rounded),
        TrackStatus.panic => const StatusTheme(Semantic.danger, Icons.crisis_alert_rounded),
        TrackStatus.recovering => const StatusTheme(Sapphire.c700, Icons.navigation_rounded),
        TrackStatus.found => const StatusTheme(Semantic.success, Icons.verified_rounded),
      };
}

/// Trackio wordmark: rendered brand mark + Jaro display type (logo face only).
class TkWordmark extends StatelessWidget {
  final double size;
  final Color? color;
  const TkWordmark({super.key, this.size = 26, this.color});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final c = color ?? tk.textPrimary;
    final tile = size + 8;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tile,
          height: tile,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * .38),
            boxShadow: [
              BoxShadow(
                color: tk.accent.withValues(alpha: .28),
                blurRadius: size * .45,
                offset: Offset(0, size * .14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * .38),
            child: Image.asset(
              'assets/brand/trackio_icon.png',
              width: tile,
              height: tile,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        SizedBox(width: size * .34),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Track',
                style: AppFonts.logo(fontSize: size, color: c, letterSpacing: -.5),
              ),
              TextSpan(
                text: 'io',
                style: AppFonts.logo(fontSize: size, color: tk.accent, letterSpacing: -.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  final TrackStatus status;
  final bool pulse;
  const StatusPill({super.key, required this.status, this.pulse = false});

  @override
  Widget build(BuildContext context) {
    final st = StatusTheme.of(status);
    return _Pulsing(
      active: pulse,
      color: st.color,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: st.color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: st.color.withValues(alpha: .45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: st.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              l10nOf(context).statusLabel(status),
              style: GoogleFonts.rubik(fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
                color: st.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pulsing extends StatefulWidget {
  final bool active;
  final Color color;
  final Widget child;
  const _Pulsing({required this.active, required this.color, required this.child});
  @override
  State<_Pulsing> createState() => _PulsingState();
}

class _PulsingState extends State<_Pulsing> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: .35 * _c.value),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? tint;
  const MetricChip({super.key, required this.icon, required this.label, this.tint});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tk.bgDeep.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint ?? tk.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.rubik(fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tk.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: GoogleFonts.rubik(fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: tk.textTertiary,
            ),
          ),
          const Spacer(),
          ?trailing
        ],
      ),
    );
  }
}

/// Soft-elevation card used across screens.
class TkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  const TkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.gradient,
    this.color,
    this.radius = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return Material(
      color: color ?? tk.card,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? (color ?? tk.card) : null,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: tk.stroke.withValues(alpha: .7)),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Solid gradient CTA button.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double height;
  const GradientButton({super.key, required this.label, this.icon, this.onTap, this.height = 54});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    return _PressScale(
      child: Opacity(
        opacity: onTap == null ? .55 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: tk.ctaGradient),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: tk.accent.withValues(alpha: .35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            height: height,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: tk.onAccent),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        label,
                        style: GoogleFonts.rubik(fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: tk.onAccent,
                          letterSpacing: .2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Squared icon action button (map controls, quick actions).
class IconButton2 extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? bg;
  final Color? fg;
  final String? tooltip;
  const IconButton2({super.key, required this.icon, this.onTap, this.bg, this.fg, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final tk = tkOf(context);
    final b = _PressScale(
      child: Material(
        color: bg ?? tk.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, size: 21, color: fg ?? tk.textPrimary),
          ),
        ),
      ),
    );
    if (tooltip == null) return b;
    return Tooltip(message: tooltip!, child: b);
  }
}

/// Subtle press-down scale feedback shared by buttons and icon buttons.
class _PressScale extends StatefulWidget {
  final Widget child;
  const _PressScale({required this.child});
  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? .96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
