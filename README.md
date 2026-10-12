# Trackio

**Smart bag tracking — Android & iOS client (demonstration build).**

Trackio keeps a continuous lock on your bag by fusing three location sources —
the phone's GPS, the bag module's GPS, and the ESP32 radio link — and reacts
the moment something feels wrong: distance warnings, instant loss alerts,
panic-packet tracking at 1 Hz, and a guided recovery flow until you confirm
your bag is back in your hand.

> This repository currently contains the **stakeholder demonstration build**:
> the full product vision, workflows and UI, driven by a deterministic
> simulation engine with mock data, scripted demo mode and manual event
> injection. Production integrations (platform GPS/BLE channels, Supabase,
> Tigris) plug into the same interfaces — see *Architecture* below.

## Feature tour

| Area | What the demo shows |
|---|---|
| Live tracking | Fused phone-GPS + bag-GPS + radio fixes, distance meter, radar view, battery/RSSI/accuracy telemetry |
| Loss detection | Warning threshold (30 m) and loss threshold (80 m), full-screen alert, alarm sound |
| Panic mode | 1 Hz high-frequency fixes, panic-packet counter, accuracy tightening (±3 m), pulsing map rings |
| Recovery | Guided return route, automatic reconnection, "I found my bag" confirmation |
| Map | Dark/light vector-style tiles (Esri canvas, keyless), phone & bag routes, connector line, distance pill |
| History | Distance timeline chart with loss band, event log, summary stats |
| Settings | Dark/Light theme, 3 alarm sounds with preview, GPS/recheck intervals |
| Accounts | Signup → OTP verification → app, login/logout (mock backend, Supabase-ready contract) |
| Demo tooling | Scripted movie-mode scenario, manual trigger panel, 1×/4×/8× speed, URL deep-links |

## Screenshots

| | | |
|---|---|---|
| ![Splash](docs/screenshots/01-splash.png) | ![Home — tracking](docs/screenshots/05-home-tracking.png) | ![Map](docs/screenshots/08-map.png) |
| *Splash & radar identity* | *Dashboard — safe, 3 m* | *Live map with connector & distance* |
| ![Alert — panic](docs/screenshots/07-alert-panic.png) | ![Map — panic](docs/screenshots/09-map-panic.png) | ![History](docs/screenshots/10-history.png) |
| *Lost-bag alert + panic mode* | *Panic pulses on last-known pin* | *Distance timeline & event log* |
| ![Home — found](docs/screenshots/12-home-found.png) | ![Settings](docs/screenshots/11-settings.png) | ![Home — light](docs/screenshots/15-home-light.png) |
| *Recovered & confirmed* | *Sounds, intervals, account* | *Light theme* |

Full gallery (15 shots, both themes): [`docs/screenshots/`](docs/screenshots).

## Documentation

| Doc | Contents |
|---|---|
| [`docs/PRD.md`](docs/PRD.md) | Full product requirements: features, bag module, backend, complete colour-spec tables, roadmap |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Layers, simulation pipeline, data model, ESP32 packet protocol, mock→production swap table |
| [`docs/DEMO_GUIDE.md`](docs/DEMO_GUIDE.md) | 5-minute stakeholder script, manual controls, deep links, FAQ |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Ground rules (palette tokens, service boundaries), commit style |
| [`CHANGELOG.md`](CHANGELOG.md) | Release notes |

## Running the demo

```bash
flutter pub get
flutter run                 # pick your device/emulator
flutter run -d chrome       # or straight to web
```

### Stage shortcuts (deep links)

| URL fragment | Effect |
|---|---|
| `?shot=home&state=tracking` | Dashboard, live tracking |
| `?shot=home&state=warning` | Distance-warning state |
| `?shot=home&state=alert` | Panic overlay + alarm |
| `?shot=map&state=alert` | Recovery map in panic mode |
| `?shot=home&state=found` | Recovered state |
| `?panel=1` | Auto-open the demo control panel |
| `?theme=light` / `?theme=dark` | Force a theme for the session |
| `?shot=splash/onboarding/login/otp` | Any entry screen |

The demo lab (`🧪` button, bottom-right) opens manual controls: drift the bag,
cut the radio link, send panic packets, recover, reset — plus the scripted
scenario one-tap playback and simulation speed.

## Architecture

```
lib/
├── core/            palette (exact spec tokens) · theme (dark+light) · formatters
├── models/          TrackStatus · GpsFix · TrackEvent · BagDevice · AppUser
├── services/
│   ├── simulation_engine.dart   fused tracking pipeline, thresholds, panic mode,
│   │                            history records (demo stand-in for platform channels)
│   ├── scenario_director.dart   scripted movie-mode + timed phase captions
│   ├── mock_auth_service.dart   signup → OTP → session (swap for supabase_flutter)
│   ├── settings_service.dart    persisted prefs (theme, sound, intervals)
│   └── sound_service.dart       alarm playback (audioplayers, fail-safe on web)
└── ui/
    ├── screens/     splash · onboarding · dashboard · map · history · settings · shell
    ├── auth/        login · signup · OTP
    └── widgets/     radar view · map markers · alert overlay · demo panel · kit
```

**Swapping in production:**
- `SimulationEngine` → platform channels for phone GPS + BLE/FM radio + ESP32
  packet protocol; bag GPS arrives over the radio link. The UI only consumes
  `ChangeNotifier` state, so nothing above the service layer changes.
- `AuthService` → `supabase_flutter` (OTP sign-in is a drop-in replacement).
- Tile layer → self-hosted tiles or Google Maps; one `urlTemplate` string.
- Backend: self-hosted Supabase + Tigris on your VDS, as specified.

## Design system

The ten colour scales from the product specification (Smart Blue, Sapphire,
Regal Navy, three Prussian Blue variants, Twilight Indigo, Blue Slate,
Slate Grey, Lavender Grey) are codified in `lib/core/palette.dart` and locked
by a unit test (`test/palette_test.dart`). Dark and light themes are built
exclusively from these tokens; semantic amber/red/green appear only for alert
severities. Typography: Space Grotesk (display) + Inter (body), bundled
locally. App icon: radar + bag motif generated from the same palette.

## Repository setup (per project spec)

The project lives at **github.com/abdou-da0wew/Trackio** (branch `main`,
history starting with the `first commit`). To work on it from a machine with
deploy keys:

```bash
git clone git@github.com:abdou-da0wew/Trackio.git
cd Trackio
flutter pub get
```

## Status

Demo build 1.0.0 — Flutter 3.47 · Dart 3.13 · MIT-licensed. All artwork and
alarm sounds are generated originals for this project. See the roadmap in
[`docs/PRD.md`](docs/PRD.md) for the path from this demo to production.
