// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Trackio brand palette — EXACT values from the product specification.
/// Ten scales, each token 100–900 plus DEFAULT(500).
/// Do not invent intermediate shades; derive opacity from tokens instead.
/// ─────────────────────────────────────────────────────────────────────────

class SmartBlue {
  static const DEFAULT = Color(0xFF0466C8);
  static const c100 = Color(0xFF011428);
  static const c200 = Color(0xFF022950);
  static const c300 = Color(0xFF023D78);
  static const c400 = Color(0xFF0352A0);
  static const c500 = DEFAULT;
  static const c600 = Color(0xFF0F85FA);
  static const c700 = Color(0xFF4BA3FB);
  static const c800 = Color(0xFF87C2FD);
  static const c900 = Color(0xFFC3E0FE);
}

class Sapphire {
  static const DEFAULT = Color(0xFF0353A4);
  static const c100 = Color(0xFF011121);
  static const c200 = Color(0xFF012242);
  static const c300 = Color(0xFF023263);
  static const c400 = Color(0xFF034384);
  static const c500 = DEFAULT;
  static const c600 = Color(0xFF0576E8);
  static const c700 = Color(0xFF3698FB);
  static const c800 = Color(0xFF79BBFC);
  static const c900 = Color(0xFFBCDDFE);
}

class RegalNavy {
  static const DEFAULT = Color(0xFF023E7D);
  static const c100 = Color(0xFF000C19);
  static const c200 = Color(0xFF011932);
  static const c300 = Color(0xFF01254B);
  static const c400 = Color(0xFF023164);
  static const c500 = DEFAULT;
  static const c600 = Color(0xFF0363C9);
  static const c700 = Color(0xFF1D89FC);
  static const c800 = Color(0xFF68B0FD);
  static const c900 = Color(0xFFB4D8FE);
}

/// Prussian Blue — Variant 1 (base #002855)
class Prussian1 {
  static const DEFAULT = Color(0xFF002855);
  static const c100 = Color(0xFF000811);
  static const c200 = Color(0xFF001023);
  static const c300 = Color(0xFF001834);
  static const c400 = Color(0xFF002045);
  static const c500 = DEFAULT;
  static const c600 = Color(0xFF0050AB);
  static const c700 = Color(0xFF0178FF);
  static const c800 = Color(0xFF56A5FF);
  static const c900 = Color(0xFFAAD2FF);
}

/// Prussian Blue — Variant 2 (base #001845)
class Prussian2 {
  static const DEFAULT = Color(0xFF001845);
  static const c100 = Color(0xFF00050E);
  static const c200 = Color(0xFF000A1D);
  static const c300 = Color(0xFF000F2B);
  static const c400 = Color(0xFF001439);
  static const c500 = DEFAULT;
  static const c600 = Color(0xFF00389F);
  static const c700 = Color(0xFF0056F7);
  static const c800 = Color(0xFF508DFF);
  static const c900 = Color(0xFFA7C6FF);
}

/// Prussian Blue — Variant 3 (base #001233)
class Prussian3 {
  static const DEFAULT = Color(0xFF001233);
  static const c100 = Color(0xFF00040A);
  static const c200 = Color(0xFF000714);
  static const c300 = Color(0xFF000B1F);
  static const c400 = Color(0xFF000E29);
  static const c500 = DEFAULT;
  static const c600 = Color(0xFF00328F);
  static const c700 = Color(0xFF0052EB);
  static const c800 = Color(0xFF4788FF);
  static const c900 = Color(0xFFA3C3FF);
}

class TwilightIndigo {
  static const DEFAULT = Color(0xFF33415C);
  static const c100 = Color(0xFF0A0D12);
  static const c200 = Color(0xFF141A25);
  static const c300 = Color(0xFF1E2737);
  static const c400 = Color(0xFF29344A);
  static const c500 = DEFAULT;
  static const c600 = Color(0xFF4D628B);
  static const c700 = Color(0xFF7186B1);
  static const c800 = Color(0xFFA0AECB);
  static const c900 = Color(0xFFD0D7E5);
}

class BlueSlate {
  static const DEFAULT = Color(0xFF5C677D);
  static const c100 = Color(0xFF131519);
  static const c200 = Color(0xFF252A32);
  static const c300 = Color(0xFF383F4C);
  static const c400 = Color(0xFF4B5365);
  static const c500 = DEFAULT;
  static const c600 = Color(0xFF79859C);
  static const c700 = Color(0xFF9BA3B5);
  static const c800 = Color(0xFFBCC2CE);
  static const c900 = Color(0xFFDEE0E6);
}

class SlateGrey {
  static const DEFAULT = Color(0xFF7D8597);
  static const c100 = Color(0xFF191A1F);
  static const c200 = Color(0xFF31353D);
  static const c300 = Color(0xFF4A4F5C);
  static const c400 = Color(0xFF62697A);
  static const c500 = DEFAULT;
  static const c600 = Color(0xFF979DAB);
  static const c700 = Color(0xFFB1B6C0);
  static const c800 = Color(0xFFCBCED5);
  static const c900 = Color(0xFFE5E7EA);
}

class LavenderGrey {
  static const DEFAULT = Color(0xFF979DAC);
  static const c100 = Color(0xFF1D1F24);
  static const c200 = Color(0xFF393D47);
  static const c300 = Color(0xFF565C6B);
  static const c400 = Color(0xFF737A8E);
  static const c500 = DEFAULT;
  static const c600 = Color(0xFFABB0BC);
  static const c700 = Color(0xFFC0C4CD);
  static const c800 = Color(0xFFD5D7DD);
  static const c900 = Color(0xFFEAEBEE);
}

/// Semantic accents — kept OUTSIDE the brand palette and used sparingly,
/// only for alert severities (warning / lost) where blue cannot communicate.
class Semantic {
  static const warning = Color(0xFFFFB454);
  static const danger = Color(0xFFFF4D5E);
  static const success = Color(0xFF3DDC97);
}
