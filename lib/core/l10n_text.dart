import 'package:flutter/material.dart';
import 'package:trackio/l10n/app_localizations.dart';

import '../models/models.dart';
import '../services/settings_service.dart';
import '../services/simulation_engine.dart';

export 'package:trackio/l10n/app_localizations.dart' show AppLocalizations;

/// Rendering helpers that turn locale-free engine/model state into
/// localized strings. The simulation layer never touches AppLocalizations —
/// every user-visible sentence is resolved here, in the UI layer.
extension AppLocalizationsX on AppLocalizations {
  /// Localized distance: "12 m" / "1.4 km" (locale-aware units).
  String dist(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      final n = km >= 100
          ? km.round().toString()
          : km.toStringAsFixed(km >= 10 ? 1 : 2);
      return '$n $unitKm';
    }
    return '${meters.round()} $unitMeters';
  }

  /// Localized relative time: "now", "12s ago", "3m ago", "2h ago".
  String ago(DateTime t, DateTime now) {
    final d = now.difference(t);
    if (d.inSeconds < 5) return agoNow;
    if (d.inSeconds < 60) return agoSeconds(d.inSeconds);
    if (d.inMinutes < 60) return agoMinutes(d.inMinutes);
    return agoHours(d.inHours);
  }

  /// Localized status-pill label.
  String statusLabel(TrackStatus s) => switch (s) {
        TrackStatus.tracking => statusTracking,
        TrackStatus.warning => statusWarning,
        TrackStatus.lost => statusLost,
        TrackStatus.panic => statusPanic,
        TrackStatus.recovering => statusRecovering,
        TrackStatus.found => statusRecovered,
      };

  /// Localized event-tile title.
  String eventTypeLabel(TrackEventType t) => switch (t) {
        TrackEventType.locationUpdate => eventLocationUpdate,
        TrackEventType.warning => eventWarning,
        TrackEventType.lost => eventLost,
        TrackEventType.panicSent => eventPanicSent,
        TrackEventType.connectionLost => eventConnectionLost,
        TrackEventType.reconnect => eventReconnect,
        TrackEventType.recovered => eventRecovered,
        TrackEventType.found => eventFound,
      };

  /// Localized alert-sound name.
  String soundLabel(AlertSound s) => switch (s) {
        AlertSound.sonarPing => soundSonarPing,
        AlertSound.alarmPulse => soundAlarmPulse,
        AlertSound.gentleChime => soundGentleChime,
      };

  /// Localized event-log detail line from the structured (code, params) pair.
  String eventDetail(TrackEvent e) => switch (e.code) {
        'sessionStarted' => evSessionStarted,
        'unusualDistance' => evUnusualDistance(e.params['meters']! as int),
        'distanceExceeded' =>
          evDistanceExceeded(e.params['meters']! as int, e.params['limit']! as int),
        'bagGpsFix' => evBagGpsFix(e.params['accuracy']! as String),
        'bagGpsFixPanic' => evBagGpsFixPanic(e.params['accuracy']! as String),
        'linkLost' => evLinkLost,
        'linkReestablished' => evLinkReestablished,
        'linkRestored' =>
          evLinkRestored(e.params['meters']! as int, e.params['accuracy']! as String),
        'panicPacket' => evPanicPacket,
        'panicPacketN' => evPanicPacketN(e.params['n']! as int),
        'recoveryStarted' => evRecoveryStarted,
        'recoveryConfirmed' => evRecoveryConfirmed(e.params['meters']! as int),
        'motionChanged' => evMotionChanged,
        _ => e.code,
      };

  /// Localized demo "movie mode" caption, resolved from the machine-readable
  /// [SimulationEngine.scenarioPhase] (with live parameters where needed).
  String scenarioCaption(SimulationEngine e) => switch (e.scenarioPhase) {
        'intro' => capIntro,
        'drifting' => capDrifting,
        'leftBehind' => capLeftBehind,
        'warning' => capWarning,
        'lost' => capLost,
        'panic' => capPanic,
        'reconnected' => capReconnected,
        'near' => capNear(e.distance.round()),
        'recovering' => capRecovering,
        'found' => capFound,
        _ => '',
      };
}

/// Convenience lookup used across screens.
AppLocalizations l10nOf(BuildContext context) => AppLocalizations.of(context);
