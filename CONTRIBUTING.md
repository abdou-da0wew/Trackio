<div align="center">

# Contributing to Trackio

**Ground rules for code, design tokens and commits.**

[![← README](https://img.shields.io/badge/%E2%86%90_README-home-001233?style=flat-square)](README.md)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-2da78f?style=flat-square)](#pull-requests)
[![MIT license](https://img.shields.io/badge/license-MIT-0052eb?style=flat-square)](LICENSE)

</div>

---

Thanks for helping build Trackio. This document covers the rules of the road
for code, design tokens and commits.

## Getting started

```bash
git clone git@github.com:abdou-da0wew/Trackio.git
cd Trackio
flutter pub get
flutter run -d chrome   # fastest way to iterate; Android/iOS work identically
```

Requirements: Flutter 3.x stable, Dart 3.x. No API keys are needed: the
live BLE link works peer-to-peer with the ESP32 module, map tiles (used by
the simulation source) are keyless, and *Explore without hardware* runs the
app fully offline.

## Ground rules

### 1. Palette tokens are law

The ten colour scales in `lib/core/palette.dart` come from the product
specification and their hex values are **locked by a unit test**
(`test/palette_test.dart`). Never hardcode a colour literal in UI code:

```dart
// bad
color: const Color(0xFF0052EB)

// good
color: TkColors.prussian.v700   // or a semantic alias from the theme
```

If a new shade is genuinely needed, add it to the palette and extend the test
— never inline it.

### 2. UI consumes ChangeNotifier state only

Screens and widgets must not talk to hardware, networks or storage directly.
They watch services exposed through `MultiProvider` in `lib/main.dart`
(`TrackingController`, `Esp32BleService`, `AuthService`, `SettingsService`,
`ScenarioDirector`). Tracking code depends on the `TrackingEngine`
interface, never on a concrete engine, so the live BLE source and the
offline simulation stay interchangeable. BLE/GATT details stay inside
`lib/services/ble/`; parsing and RSSI math must match the firmware
contract in `docs/BLE_INTEGRATION.md`.

### 3. Analyze and test before you push

```bash
flutter analyze   # zero warnings expected
flutter test      # palette lock + RSSI/firmware-parity tests must pass
```

### 4. Commit style

Use short, imperative subjects, e.g.:

```
map: add panic-pulse rings around bag marker
auth: persist session across restarts
docs: expand ESP32 packet protocol notes
```

### 5. Keep both sources honest

The live BLE source must never invent measurements — every distance, RSSI
or bearing traces to a telemetry frame or a documented derivation. The
simulation source must always run offline, deterministically and with no
keys; when you add a feature, wire it into both engines behind the
`TrackingEngine` interface rather than stubbing UI with dead buttons. If a
feature exists on only one source, say so explicitly in the UI.

## Project layout

See `docs/ARCHITECTURE.md` for the layer breakdown and
`docs/BLE_INTEGRATION.md` for the GATT profile, telemetry frame, RSSI math
and loss rules. Production integrations (Supabase auth, GPS module,
self-hosted tiles) plug in behind the existing interfaces without touching
UI code.

## Where help is wanted

- GPS receiver + battery telemetry on the ESP32 module (unlocks the
  geographic map in live mode; see `docs/PRD.md` §7)
- Background foreground service + OS notification channel (M3)
- `supabase_flutter` auth + session sync against a self-hosted Supabase
- ESP32 firmware: 1 Hz panic cadence, store-and-forward, panic persistence
- Widget tests for engine phase transitions and the connect flow
- Localisation beyond English and Arabic

## Reporting issues

Open a GitHub issue with: Flutter version, platform, steps to reproduce.
For simulation issues include the deep link (e.g.
`?shot=home&state=alert&panel=1`); for BLE issues include the firmware
version (`VER`), the device panel response log, and the adapter/OS version.
