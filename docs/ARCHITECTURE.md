<div align="center">

# Trackio — Architecture

**How the demo build is wired: layers, the tracking pipeline, and the mock→production swap.**

[![← README](https://img.shields.io/badge/%E2%86%90_README-home-001233?style=flat-square)](../README.md)
[![PRD](https://img.shields.io/badge/docs-PRD-4c5769?style=flat-square)](PRD.md)
[![Demo guide](https://img.shields.io/badge/docs-demo_guide-4c5769?style=flat-square)](DEMO_GUIDE.md)
[![MIT license](https://img.shields.io/badge/license-MIT-0052eb?style=flat-square)](../LICENSE)

</div>

---

This document explains how the demo build is put together, how data flows
through the tracking pipeline, and exactly how production integrations
replace the simulation without touching UI code.

<img src="assets/architecture.png" alt="System architecture: Trackio app and ESP32 bag module over a radio link, syncing to self-hosted Supabase and Tigris" width="820" />

---

## 1. Stack

| Layer | Choice | Notes |
|---|---|---|
| Framework | Flutter 3.x / Dart 3.x | Single codebase for Android, iOS, web demo |
| State management | `provider` (ChangeNotifier) | Services are notifiers provided app-wide; UI only watches |
| Map | `flutter_map` + `latlong2` | Keyless Esri canvas tiles (dark/light); OSM/Google swap is a URL string |
| Charts | `fl_chart` | Distance timeline with loss band |
| Audio | `audioplayers` | Bundled alarm WAVs, preview + alert playback, fail-safe on web |
| Persistence | `shared_preferences` | Session, settings, onboarding flag |
| i18n/format | `intl` | Timestamps, durations |

## 2. Layers

```
┌───────────────────────────── ui/ ─────────────────────────────┐
│ screens/   splash · onboarding · dashboard · map · history ·  │
│            settings · shell (4 tabs + alert overlay + HUD)    │
│ auth/      login · signup · otp                               │
│ widgets/   radar_view · map_markers · alert_overlay ·         │
│            demo_panel · common kit                            │
└──────────────────────────┬────────────────────────────────────┘
                           │ watches ChangeNotifier state only
┌──────────────────────────▼────────────────────────────────────┐
│ services/                                                     │
│  SimulationEngine    fused tracking pipeline, thresholds,     │
│                      panic mode, event + history records      │
│  ScenarioDirector    scripted movie-mode, captions, speed     │
│  AuthService (mock)  signup → OTP → session persistence       │
│  SettingsService     theme · sound · intervals (persisted)    │
│  SoundService        alarm playback                           │
└──────────────────────────┬────────────────────────────────────┘
                           │
┌──────────────────────────▼────────────────────────────────────┐
│ models/   TrackStatus · GpsFix · TrackEvent · BagDevice ·     │
│           AppUser                                             │
│ core/     palette (spec tokens, unit-locked) · theme ·        │
│           formatters                                          │
└───────────────────────────────────────────────────────────────┘
```

**The one rule that makes the demo→production swap cheap:** UI code never
touches hardware, network, or storage. It observes notifiers. Every mock
lives behind a service with a production-shaped surface (§6).

## 3. The tracking pipeline (`SimulationEngine`)

A single wall-clock tick drives the whole simulation. Three noisy signals in,
one honest distance number out, checked against the thresholds every tick:

<img src="assets/fusion.png" alt="Data flow: phone GPS, radio RSSI and bag GPS feed the fusion engine; its distance passes the 30 m and 80 m threshold check driving UI and event log" width="820" />

```
tick (sim time × speed)
  ├─ 1. phone pose        walks a loop in Zamalek, Cairo (demo stage)
  ├─ 2. bag pose          attached: phone + 2–6 m noise
  │                       drifting: pinned while the phone walks away
  │                       lost: frozen at last-known fix
  │                       recovering: user walks back toward the fix
  ├─ 3. radio model       RSSI ≈ f(distance, noise); drops to null on loss
  ├─ 4. fusion            bag-GPS + phone-GPS blend → fused distance (m)
  ├─ 5. thresholds        ≥ 30 m → warning phase
  │                       ≥ 80 m or link drop → LOST → panic mode ON
  │                       re-detected → recovering
  │                       < 2 m during recovery → FOUND (awaits confirmation)
  ├─ 6. panic mode        1 Hz fixes, ±3 m accuracy, panic-packet counter,
  │                       faster battery drain, map pulse events
  └─ 7. records           TrackEvent log + distance history samples
```

Phases: `safe → drifting → weak → lost → recovering → found`, each with its
own dashboard treatment, radar rendering, and alert behaviour:

<img src="assets/lifecycle.png" alt="State machine from Safe through Warning and Lost with panic packets to Recovering and Found" width="820" />

The engine is
deterministic given the same inputs — demo playback is repeatable, and
`poseForShot(...)` lets QA stage exact poses for screenshots.

Thresholds and intervals (warning 30 m, loss 80 m, GPS refresh, recheck
cadence) read from `SettingsService` at every tick, so changing a slider
changes engine behaviour live.

## 4. Demo direction (`ScenarioDirector`)

`ScenarioDirector` plays the scripted loss-and-recovery story as a timeline
of engine commands with caption strings:

1. *Calm* — "Bag connected · 3 m"
2. *Drift* — engine injects drift; caption explains the walk-away
3. *Weak signal* — RSSI decays
4. *Lost* — link cut, full-screen alert + alarm, panic packets begin
5. *Recovery* — link re-detected, guided return
6. *Found* — distance < 2 m, confirmation, celebration

Speed control (1×/4×/8×) multiplies the engine tick and timeline clock.
The manual panel exposes the same engine commands individually (drift, cut
link, panic, recover, reset) so presenters can improvise.

## 5. Data model

| Model | Shape |
|---|---|
| `GpsFix` | lat, lng, accuracy (m), timestamp, source (phone / bag / fused) |
| `TrackStatus` | phase, fused distance, RSSI, battery, last sync, panic flag, packet counter |
| `TrackEvent` | type (sync, drift, weak, lost, panic, recover, found…), severity, timestamp, message, distance snapshot |
| `BagDevice` | id, name, battery, firmware, RSSI, link state, last-seen |
| `AppUser` | id, name, e-mail, verified |

History (events + samples) is generated for past days at first run so the
History screen tells a complete story from minute one; the current session
appends to it live.

## 6. Swapping mocks for production

| Mock (today) | Production (roadmap) | Swap cost |
|---|---|---|
| `SimulationEngine` | Platform channels: phone GPS + radio RSSI stream; bag GPS + telemetry arrive over the radio link. Engine's phase machine and thresholds survive unchanged — only the pose/radio inputs become real. | UI: zero |
| `AuthService` (mock) | `supabase_flutter` — `signInWithOtp` / `verifyOTP` / `signInWithPassword` match the same `signup → otp → session` contract | Re-implement one interface |
| Keyless Esri tiles | Self-hosted tile server or Google Maps | One `urlTemplate` string |
| Local history | Postgres `events` / `distance_samples` + Realtime relay when phone offline | Repository layer |
| Bundled sounds | Same (already real) | — |

The backend itself is specified as **self-hosted Supabase + Tigris on a
private VDS** (see `docs/PRD.md` §8). The app must keep full offline
operation — the radio link, not the cloud, is the source of truth for live
tracking.

## 7. ESP32 packet protocol (sketch for firmware work)

```
BEACON          every 1 s (connected)     { seq, battery %, rssi hint }
GPS_FIX         every GPS interval        { lat, lng, acc, ts, speed }
PANIC_PACKET    panic mode (1 Hz)         { seq, lat, lng, acc, battery %, flags }
CMD             app → module              { ENTER_PANIC | EXIT_PANIC | RING | PING }
LAST_KNOWN      on reconnect (store-and-forward) { cached fix + drop duration }
```

Design constraints carried from the PRD: panic mode must persist across
module restarts until cancelled; the module caches the last fix during link
drops; every packet carries battery level.

## 8. QA hooks

- **Stage deep links** — `?shot=<screen>&state=<pose>&theme=<light|dark>&panel=1`
  stage any screen/pose for screenshots and demos (table in the README).
- **Palette lock test** — `test/palette_test.dart` fails the build if any
  spec token drifts from the values in `docs/PRD.md` §9.
- **Deterministic simulation** — same script, same result; demos never
  surprise a presenter.
