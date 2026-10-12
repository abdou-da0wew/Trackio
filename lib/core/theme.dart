import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'fonts.dart';
import 'palette.dart';

/// Design tokens that change per brightness, resolved via ThemeExtension.
@immutable
class TkColors extends ThemeExtension<TkColors> {
  final Color bg;            // scaffold background
  final Color bgDeep;        // deeper wells (map chrome, overlays)
  final Color card;          // elevated surfaces
  final Color cardAlt;       // inputs / secondary surfaces
  final Color stroke;        // hairline borders
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;        // primary interactive blue
  final Color accentDeep;    // pressed / gradient end
  final Color accentSoft;    // tint fills
  final Color onAccent;
  final List<Color> ctaGradient;

  const TkColors({
    required this.bg,
    required this.bgDeep,
    required this.card,
    required this.cardAlt,
    required this.stroke,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentDeep,
    required this.accentSoft,
    required this.onAccent,
    required this.ctaGradient,
  });

  static const dark = TkColors(
    bg: Prussian2.c100,          // #00050E
    bgDeep: Prussian3.c100,      // #00040A
    card: TwilightIndigo.c200,   // #141A25
    cardAlt: Prussian2.c300,     // #000F2B
    stroke: TwilightIndigo.c400, // #29344A
    textPrimary: LavenderGrey.c900,
    textSecondary: SlateGrey.c600,
    textTertiary: BlueSlate.c500,
    accent: SmartBlue.c600,      // #0F85FA
    accentDeep: Prussian3.c700,  // #0052EB
    accentSoft: Prussian3.c800,
    onAccent: Colors.white,
    ctaGradient: [SmartBlue.c600, Prussian3.c700],
  );

  static const light = TkColors(
    bg: LavenderGrey.c900,       // #EAEBEE
    bgDeep: BlueSlate.c900,      // #DEE0E6
    card: Colors.white,
    cardAlt: LavenderGrey.c800,  // #D5D7DD
    stroke: BlueSlate.c800,      // #BCC2CE
    textPrimary: SmartBlue.c100, // #011428
    textSecondary: BlueSlate.c500,
    textTertiary: SlateGrey.c500,
    accent: SmartBlue.c500,      // #0466C8
    accentDeep: RegalNavy.c600,  // #0363C9
    accentSoft: SmartBlue.c700,
    onAccent: Colors.white,
    ctaGradient: [SmartBlue.c500, RegalNavy.c600],
  );

  @override
  TkColors copyWith({Color? bg, Color? bgDeep, Color? card, Color? cardAlt,
      Color? stroke, Color? textPrimary, Color? textSecondary, Color? textTertiary,
      Color? accent, Color? accentDeep, Color? accentSoft, Color? onAccent,
      List<Color>? ctaGradient}) {
    return TkColors(
      bg: bg ?? this.bg, bgDeep: bgDeep ?? this.bgDeep,
      card: card ?? this.card, cardAlt: cardAlt ?? this.cardAlt,
      stroke: stroke ?? this.stroke,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent, accentDeep: accentDeep ?? this.accentDeep,
      accentSoft: accentSoft ?? this.accentSoft, onAccent: onAccent ?? this.onAccent,
      ctaGradient: ctaGradient ?? this.ctaGradient,
    );
  }

  @override
  TkColors lerp(TkColors? other, double t) {
    if (other == null) return this;
    return TkColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bgDeep: Color.lerp(bgDeep, other.bgDeep, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardAlt: Color.lerp(cardAlt, other.cardAlt, t)!,
      stroke: Color.lerp(stroke, other.stroke, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      ctaGradient: List.generate(2, (i) => Color.lerp(ctaGradient[i], other.ctaGradient[i], t)!),
    );
  }
}

class Tk {
  // Typeface plan lives in core/fonts.dart:
  //   Rubik = all English UI text · Jaro = logo/stylised only · Zain = Arabic (ar locale)

  static ThemeData theme(Brightness brightness) {
    const dark = TkColors.dark;
    const light = TkColors.light;
    final c = brightness == Brightness.dark ? dark : light;
    final scheme = ColorScheme.fromSeed(
      seedColor: SmartBlue.c500,
      brightness: brightness,
    ).copyWith(
      primary: c.accent,
      secondary: c.accentDeep,
      surface: c.card,
      error: Semantic.danger,
    );

    final baseText = Typography.material2021(platform: TargetPlatform.iOS)
        .englishLike
        .apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);

    // Rubik carries all English UI text (see core/fonts.dart); the app-level
    // builder in app.dart swaps this for Zain when the locale is Arabic.
    final rubik = AppFonts.english(baseText);
    TextTheme textTheme = rubik.copyWith(
      displayLarge: rubik.displayLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.5),
      displayMedium: rubik.displayMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.2),
      displaySmall: rubik.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1),
      headlineLarge: rubik.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8),
      headlineMedium: rubik.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6),
      headlineSmall: rubik.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleLarge: rubik.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleMedium: rubik.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: rubik.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: rubik.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: rubik.bodyMedium?.copyWith(height: 1.45),
      bodySmall: rubik.bodySmall?.copyWith(height: 1.35),
      labelLarge: rubik.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
      labelMedium: rubik.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3),
      labelSmall: rubik.labelSmall?.copyWith(letterSpacing: 0.4),
    );

    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[c],
      dividerTheme: DividerThemeData(color: c.stroke, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge!.copyWith(color: c.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: c.stroke.withValues(alpha: isDark ? .6 : .8)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? c.cardAlt : c.card,
        hintStyle: textTheme.bodyLarge?.copyWith(color: c.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Semantic.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Semantic.danger, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          minimumSize: const Size.fromHeight(54),
          textStyle: textTheme.labelLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: c.stroke, width: 1.2),
          textStyle: textTheme.labelLarge!.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: isDark ? c.cardAlt : c.bgDeep,
        thumbColor: Colors.white,
        overlayColor: c.accent.withValues(alpha: .15),
        trackHeight: 5,
        valueIndicatorColor: c.accentDeep,
        valueIndicatorTextStyle: GoogleFonts.rubik(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : (isDark ? SlateGrey.c500 : BlueSlate.c800)),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.accent : (isDark ? TwilightIndigo.c400 : BlueSlate.c800)),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: c.stroke)),
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? c.accent : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? c.onAccent : c.textSecondary),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? TwilightIndigo.c300 : SmartBlue.c100,
        contentTextStyle: textTheme.bodyMedium!.copyWith(color: isDark ? LavenderGrey.c900 : SmartBlue.c100),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? Prussian3.c200.withValues(alpha: .96) : Colors.white,
        indicatorColor: c.accent.withValues(alpha: isDark ? .22 : .12),
        height: 68,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium!.copyWith(color: c.textSecondary)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? c.accent : c.textTertiary,
            )),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? c.cardAlt : c.card,
        side: BorderSide(color: c.stroke),
        labelStyle: textTheme.labelMedium!.copyWith(color: c.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

/// Convenience lookups
TkColors tkOf(BuildContext context) => Theme.of(context).extension<TkColors>()!;
