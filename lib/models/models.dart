import 'package:latlong2/latlong.dart';

/// Core domain models for the Trackio demo build.

enum TrackStatus { tracking, warning, lost, panic, recovering, found }

enum FixSource { phoneGps, bagGps, radioRssi, fused }

extension FixSourceX on FixSource {
  String get label => switch (this) {
        FixSource.phoneGps => 'Phone GPS',
        FixSource.bagGps => 'Bag GPS',
        FixSource.radioRssi => 'Radio RSSI',
        FixSource.fused => 'Fused',
      };
}

enum TrackEventType {
  locationUpdate,
  warning,
  lost,
  panicSent,
  connectionLost,
  reconnect,
  recovered,
  found,
}

extension TrackEventTypeX on TrackEventType {
  String get label => switch (this) {
        TrackEventType.locationUpdate => 'Location update',
        TrackEventType.warning => 'Distance warning',
        TrackEventType.lost => 'Bag lost',
        TrackEventType.panicSent => 'Panic packet sent',
        TrackEventType.connectionLost => 'Connection lost',
        TrackEventType.reconnect => 'Connection restored',
        TrackEventType.recovered => 'Recovery in progress',
        TrackEventType.found => 'Bag found',
      };
}

class TrackEvent {
  final DateTime time;
  final TrackEventType type;
  final String detail;
  TrackEvent({required this.time, required this.type, required this.detail});
}

class GpsFix {
  final LatLng point;
  final double accuracyM;
  final DateTime time;
  final FixSource source;
  GpsFix({
    required this.point,
    required this.accuracyM,
    required this.time,
    required this.source,
  });
}

class DistanceSample {
  final DateTime time;
  final double meters;
  final bool wasLost;
  DistanceSample({required this.time, required this.meters, required this.wasLost});
}

class BagDevice {
  final String name;
  final String firmware;
  final double batteryPct;
  final double rssi; // dBm; -100 when radio link is cut
  final bool radioLink;
  BagDevice({
    required this.name,
    required this.firmware,
    required this.batteryPct,
    required this.rssi,
    required this.radioLink,
  });

  BagDevice copyWith({double? batteryPct, double? rssi, bool? radioLink}) => BagDevice(
        name: name,
        firmware: firmware,
        batteryPct: batteryPct ?? this.batteryPct,
        rssi: rssi ?? this.rssi,
        radioLink: radioLink ?? this.radioLink,
      );
}

class AppUser {
  final String name;
  final String email;
  AppUser({required this.name, required this.email});
}
