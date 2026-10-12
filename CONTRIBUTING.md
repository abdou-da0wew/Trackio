# Contributing to Trackio

Thanks for helping build Trackio. This document covers the rules of the road
for code, design tokens and commits.

## Getting started

```bash
git clone git@github.com:abdou-da0wew/Trackio.git
cd Trackio
flutter pub get
flutter run -d chrome   # fastest way to iterate; Android/iOS work identically
```

Requirements: Flutter 3.x stable, Dart 3.x. No API keys are needed to run the
demo — map tiles and the simulation are keyless by design.

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
They watch services exposed through `MultiProvider` in `lib/app.dart`
(`SimulationEngine`, `AuthService`, `SettingsService`, `ScenarioDirector`).
This is what keeps the demo→production swap a one-file change.

### 3. Analyze and test before you push

```bash
flutter analyze   # zero warnings expected
flutter test      # palette lock test must pass
```

### 4. Commit style

Use short, imperative subjects, e.g.:

```
map: add panic-pulse rings around bag marker
auth: persist session across restarts
docs: expand ESP32 packet protocol notes
```

### 5. Keep the demo honest

The demo build must always run offline, deterministically, with no keys.
When you add a feature, wire it into the simulation engine (or add a mock)
rather than stubbing UI with dead buttons. If a feature truly can't be
simulated, mark it clearly as coming soon in the UI.

## Project layout

See `docs/ARCHITECTURE.md` for the full breakdown of layers, the simulation
pipeline, and how production integrations (platform GPS/BLE channels,
Supabase, self-hosted tiles) replace the mocks without touching UI code.

## Where help is wanted

- Real platform channels for phone GPS + radio RSSI (Android/iOS)
- `supabase_flutter` auth + session sync against a self-hosted Supabase
- ESP32 firmware for the bag module (see `docs/ARCHITECTURE.md` § Packet protocol)
- Localisation beyond English
- Widget tests for dashboard phase transitions

## Reporting issues

Open a GitHub issue with: Flutter version, platform, steps to reproduce, and
the deep link (e.g. `?shot=home&state=alert&panel=1`) that exposes the state
— the demo's stage shortcuts make most states reproducible in one URL.
