import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Trackio typefaces — all loaded through the `google_fonts` package.
///
/// The typeface plan is intentional and locked:
///
///  • **Rubik** — every piece of English UI text: headings, body copy,
///    numerals, labels. Variable weight (300–900), so real font weights
///    render instead of synthesized bolds.
///
///  • **Jaro** — the logo wordmark and stylised brand moments ONLY.
///    It is a single-weight (400) display face: never use it for body
///    copy, buttons or data. If a surface needs to feel "branded", it
///    goes through [logo].
///
///  • **Zain** — Arabic UI text ONLY. It is never hard-referenced from
///    widgets; the app-level builder in `app.dart` swaps the active
///    text theme to [arabic] whenever the resolved locale is `ar`, so
///    an Arabic runtime gets Zain everywhere without per-widget work.
class AppFonts {
  AppFonts._();

  /// Base English text theme — Rubik. Pass a size/color base (usually
  /// `Typography.material2021().englishLike`) to keep metrics consistent.
  static TextTheme english(TextTheme? base) => GoogleFonts.rubikTextTheme(base);

  /// Arabic text theme — Zain. Applied automatically for `ar` locales.
  static TextTheme arabic(TextTheme? base) => GoogleFonts.zainTextTheme(base);

  /// Logo wordmark / stylised brand text — Jaro (weight 400 only).
  ///
  /// Used by [TkWordmark] and any surface that re-creates the brand
  /// moment. Do not use for flowing text.
  static TextStyle logo({
    double? fontSize,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.jaro(
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
      );
}
