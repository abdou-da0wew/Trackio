import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:trackio/services/ble/rssi_model.dart';
import 'package:trackio/services/ble/telemetry.dart';

/// Dart mirror of the firmware host test (`tools/host_test_radar.c`).
/// The phone-side DSP must agree with the ESP32 implementation.
void main() {
  group('RssiFilter — port of rm_rssi_filt_update', () {
    test('converges to the mean of a calm sample window', () {
      final f = RssiFilter();
      f.update(-60);
      f.update(-62);
      final v = f.update(-61);
      expect((v - (-61.0)).abs(), lessThan(2.0));
    });

    test('rejects a single >15 dB spike and keeps the estimate', () {
      final f = RssiFilter();
      f.update(-60);
      f.update(-62);
      f.update(-61);
      final before = f.ema;
      final v = f.update(-20); // +41 dB multipath spike
      expect(v, before);
      expect(f.ema, before);
    });

    test('ignores physically impossible RSSI values', () {
      final f = RssiFilter();
      f.update(-60);
      final before = f.ema;
      expect(f.update(5), before);
      expect(f.update(-130), before);
    });

    test('follows slow drift', () {
      final f = RssiFilter();
      f.update(-60);
      f.update(-62);
      f.update(-61);
      for (var i = 0; i < 50; i++) {
        f.update(-70);
      }
      expect((f.ema - (-70.0)).abs(), lessThan(2.0));
    });
  });

  group('rssiToDistanceM — port of rm_rssi_to_dist_m', () {
    test('RSSI at the 1 m reference yields 1.0 m', () {
      final d = RssiModel.rssiToDistanceM(-59, rssiAt1m: -59, pathN: 2.6);
      expect((d - 1.0).abs(), lessThan(0.05));
    });

    test('-7 dB at n=2.6 yields ~1.86 m', () {
      final d = RssiModel.rssiToDistanceM(-66, rssiAt1m: -59, pathN: 2.6);
      final expected = math.pow(10.0, 7.0 / 26.0).toDouble();
      expect((d - expected).abs(), lessThan(0.05));
    });

    test('monotonic: weaker RSSI maps farther', () {
      final near = RssiModel.rssiToDistanceM(-66);
      final far = RssiModel.rssiToDistanceM(-71);
      expect(far, greaterThan(near));
    });

    test('clamps to the 0.15–25 m firmware range', () {
      expect(RssiModel.rssiToDistanceM(-99), RssiModel.maxDistanceM);
      expect(RssiModel.rssiToDistanceM(-40), RssiModel.minDistanceM);
    });

    test('returns -1 for impossible RSSI', () {
      expect(RssiModel.rssiToDistanceM(10), -1.0);
      expect(RssiModel.rssiToDistanceM(-150), -1.0);
    });
  });

  group('TelemetryFrame.parse', () {
    test('decodes a full T-frame exactly as telemetry_build emits it', () {
      const line = 'T,D,1.86,-66,97,82,240,512,90,0,0,184';
      final f = TelemetryFrame.parse(line);
      expect(f, isNotNull);
      expect(f!.navState, CarNavState.drive);
      expect(f.distanceM, closeTo(1.86, 0.001));
      expect(f.rssi, -66);
      expect(f.bearingDeg, 97);
      expect(f.confidence, 82);
      expect(f.frontCm, 240);
      expect(f.rearCm, 512);
      expect(f.servoDeg, 90);
      expect(f.motorLPct, 0);
      expect(f.motorRPct, 0);
      expect(f.freeHeapKb, 184);
    });

    test('bearing 999 means invalid', () {
      final f = TelemetryFrame.parse('T,W,0.40,-58,999,0,120,300,90,0,0,200');
      expect(f, isNotNull);
      expect(f!.bearingDeg, isNull);
      expect(f.confidence, 0);
    });

    test('rejects non-telemetry and malformed lines', () {
      expect(TelemetryFrame.parse('OK PONG'), isNull);
      expect(TelemetryFrame.parse('T,D,1.8'), isNull);
      expect(TelemetryFrame.parse(''), isNull);
    });
  });

  group('StatResponse.parse', () {
    test('decodes the STAT key=value line', () {
      const line =
          'OK st=D mode=FOLLOW arm=1 conn=1 enc=1 adv=0 rssi=-66 dist=1.86 '
          'brg=97 conf=82 f=240cm r=512cm ang=90 L=0% R=0% bonds=1 heap=184kB';
      final s = StatResponse.parse(line);
      expect(s, isNotNull);
      expect(s!.mode, 'FOLLOW');
      expect(s.armed, true);
      expect(s.connected, true);
      expect(s.encrypted, true);
      expect(s.rssi, -66);
      expect(s.distanceM, closeTo(1.86, 0.001));
      expect(s.bonds, 1);
    });
  });

  group('DeviceSettingsDump.parse', () {
    test('extracts the RSSI model parameters', () {
      const dump =
          'name=ESP32-FollowCar passkey=246810 rssi1m=-59.0 pathn=2.60 antoff=90.0';
      final s = DeviceSettingsDump.parse(dump);
      expect(s, isNotNull);
      expect(s!.name, 'ESP32-FollowCar');
      expect(s.passkey, 246810);
      expect(s.rssiAt1m, -59.0);
      expect(s.pathN, 2.60);
    });
  });
}
