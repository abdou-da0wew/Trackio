import 'package:flutter_test/flutter_test.dart';
import 'package:trackio/core/palette.dart';

void main() {
  test('brand palette tokens match the product specification exactly', () {
    // Smart Blue
    expect(SmartBlue.c500.toARGB32(), 0xFF0466C8);
    expect(SmartBlue.c600.toARGB32(), 0xFF0F85FA);
    expect(SmartBlue.c900.toARGB32(), 0xFFC3E0FE);
    // Sapphire
    expect(Sapphire.c500.toARGB32(), 0xFF0353A4);
    // Regal Navy
    expect(RegalNavy.c500.toARGB32(), 0xFF023E7D);
    // Prussian variants
    expect(Prussian1.c500.toARGB32(), 0xFF002855);
    expect(Prussian2.c500.toARGB32(), 0xFF001845);
    expect(Prussian3.c500.toARGB32(), 0xFF001233);
    expect(Prussian3.c700.toARGB32(), 0xFF0052EB);
    // Greys
    expect(TwilightIndigo.c500.toARGB32(), 0xFF33415C);
    expect(BlueSlate.c500.toARGB32(), 0xFF5C677D);
    expect(SlateGrey.c500.toARGB32(), 0xFF7D8597);
    expect(LavenderGrey.c900.toARGB32(), 0xFFEAEBEE);
  });
}
