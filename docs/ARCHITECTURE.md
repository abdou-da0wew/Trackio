<div align="center">

# Trackio — Architecture

**How the app is wired: layers, the live BLE and simulation pipelines, and the mock→production swap.**

[![← README](https://img.shields.io/badge/%E2%86%90_README-home-001233?style=flat-square)](../README.md)
[![PRD](https://img.shields.io/badge/docs-PRD-4c5769?style=flat-square)](PRD.md)
[![Demo guide](https://img.shields.io/badge/docs-demo_guide-4c5769?style=flat-square)](DEMO_GUIDE.md)
[![MIT license](https://img.shields.io/badge/license-MIT-0052eb?style=flat-square)](../LICENSE)

</div>

---

This document explains how the app is put together, how data flows
through the live BLE and offline simulation pipelines, and exactly how
the remaining production integrations slot in without touching UI code.
The GATT-level contract is documented separately in
[BLE_INTEGRATION.md](BLE_INTEGRATION.md).

<img src="assets/architecture.png" alt="System architecture: Trackio app and ESP32 bag module over a radio link, syncing to self-hosted Supabase and Tigris" width="820" />

---

## 1. Stack

| Layer | Choice | Notes |
|---|---|---|
| Framework | Flutter 3.x / Dart 3.x | Single codebase for Android, iOS, web (Web Bluetooth) |
| BLE | `flutter_blue_plus` + `permission_handler` | GATT central: scan, secure pair/bond, notify/write, reconnect ([BLE integration](BLE_INTEGRATION.md)) |
| State management | `provider` (ChangeNotifier) | Services are notifiers provided app-wide; UI only watches |
| Map | `flutter_map` + `latlong2` | Keyless Esri canvas tiles (dark/light); simulation source only — live BLE uses a polar relative radar |
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
│  ble/  Esp32BleService  GATT scan/pair/notify/write/reconnect │
│        RssiModel        firmware-identical RSSI DSP + pathloss│
│        telemetry        T-frame / STAT / settings parsers     │
│  tracking/  TrackingEngine interface                          │
│        BleTrackingEngine   real RSSI/link → 6-state machine   │
│        SimulationEngine    deterministic Cairo-walk source    │
│        TrackingController  source switch, notification forward│
│  ScenarioDirector    scripted movie-mode (simulation source)  │
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

**The one rule that keeps the swap cheap:** UI code never touches
hardware, network, or storage. It observes notifiers. Both engines and
every service expose a production-shaped surface (§6), so the
simulation source and the live BLE source are interchangeable.

## 3. The tracking pipelines

Both engines implement `TrackingEngine` and run the same six-state
machine (`tracking → warning → lost → panic → recovering → found`); only
the origin of the measurements differs.

### 3.1 Live BLE pipeline (`BleTrackingEngine` + `Esp32BleService`)

```
ESP32 GATT server (firmware)
  │  notify 500 ms: T,<st>,<dist>,<rssi>,<bearing>,<conf>,…
  ▼
Esp32BleService
  ├─ scan / pair (SC + MITM + bond, passkey 246810) / reconnect backoff
  ├─ characteristic discovery + TLM/RSP subscriptions, CMD writes
  └─ TelemetryFrame.parse → broadcast stream
        ▼
BleTrackingEngine
  ├─ RssiFilter (median-3 + EMA, firmware-identical port)
  ├─ path-loss distance fallback when the frame's distance is invalid
  ├─ thresholds   RSSI ≤ -82 dBm / 30 m → warning
  │               disconnect, stale >4 s, or RSSI ≤ -94 dBm ×3 s → LOST
  │               1.6 s grace → panic; reconnect → recovering
  │               explicit confirmation → FOUND
  ├─ panic        every frame during a loss increments the fix counter
  └─ records      TrackEvent log + distance history samples
```

RSSI math and frame formats are documented field-by-field in
[BLE_INTEGRATION.md](BLE_INTEGRATION.md); the firmware clamps distance at
25 m and reports no GPS, so live mode renders the polar
`RelativeRadarMap` (bearing + distance) rather than geographic markers.

### 3.2 Offline simulation pipeline (`SimulationEngine`)

A single wall-clock tick drives the deterministic Cairo-walk simulation.
Three modelled signals in, one distance number out, checked against the
thresholds every tick:

<img src="assets/fusion.png" alt="Data flow: phone GPS, radio RSSI and bag GPS feed the fusion engine; its distance passes the 30 m and 80 m threshold check driving UI and event log" width="820" />

```
tick (sim time × speed)
  ├─ 1. phone pose        walks a loop in Zamalek, Cairo (offline stage)
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

The engine is deterministic given the same inputs — playback is
repeatable, and `poseForShot(...)` lets QA stage exact poses for
screenshots. Thresholds and intervals read from `SettingsService` at
every tick, so changing a slider changes engine behaviour live.

## 4. Demo direction (`ScenarioDirector`, simulation source only)

`ScenarioDirector` plays the scripted loss-and-recovery story as a timeline
of simulation-engine commands with localized caption strings:

1. *Calm* — "Bag connected · 3 m"
2. *Drift* — engine injects drift; caption explains the walk-away
3. *Weak signal* — RSSI decays
4. *Lost* — link cut, full-screen alert + alarm, panic packets begin
5. *Recovery* — link re-detected, guided return
6. *Found* — distance < 2 m, confirmation, celebration

Speed control (1×/4×/8×) multiplies the engine tick and timeline clock.
The demo lab exposes the same engine commands individually (drift, cut
link, panic, recover, reset) so presenters can improvise. On the live BLE
source the equivalent entry point is the device panel with real firmware
commands instead.

## 5. Data model

| Model | Shape |
|---|---|
| `GpsFix` | lat, lng, accuracy (m), timestamp, source (phone / bag / fused) |
| `TrackStatus` | phase, fused distance, RSSI, battery, last sync, panic flag, packet counter |
| `TrackEvent` | type (sync, drift, weak, lost, panic, recover, found…), severity, timestamp, message, distance snapshot |
| `BagDevice` | id, name, battery, firmware, RSSI, link state, last-seen |
| `AppUser` | id, name, e-mail, verified |

On the simulation source, past days of history are seeded at first run so
the History screen tells a complete story from minute one. On the live BLE
source, history accumulates only from real telemetry frames and events —
nothing is fabricated; the wire-level transport models
(`TelemetryFrame`, `StatResponse`, `DeviceSettingsDump`) live in
`lib/services/ble/telemetry.dart` alongside the firmware's CSV formats.
Both sources append the current session to the same `TrackEvent` /
`DistanceSample` lists, so the History screen is source-agnostic.

## 6. Swapping mocks for production

| Component (today) | Production (roadmap) | Swap cost |
|---|---|---|
| `Esp32BleService` + `BleTrackingEngine` — **real GATT link and RSSI pipeline** | Add GPS-bearing hardware; the `TrackingEngine` phase machine and thresholds survive unchanged — only inputs extend | UI: zero |
| `SimulationEngine` | Offline/QA source retained; no production role | — |
| `AuthService` (mock) | `supabase_flutter` — `signInWithOtp` / `verifyOTP` / `signInWithPassword` match the same `signup → otp → session` contract | Re-implement one interface |
| Keyless Esri tiles | Self-hosted tile server or Google Maps | One `urlTemplate` string |
| Local history | Postgres `events` / `distance_samples` + Realtime relay when phone offline | Repository layer |
| Bundled sounds | Same (already real) | — |

The backend itself is specified as **self-hosted Supabase + Tigris on a
private VDS** (see `docs/PRD.md` §8). The app must keep full offline
operation — the radio link, not the cloud, is the source of truth for live
tracking.

## 7. ESP32 protocols

### 7.1 Shipped firmware (follow-car) — implemented

The running GATT contract is text-based and fully documented in
[BLE_INTEGRATION.md](BLE_INTEGRATION.md):

```
TLM notify  2 Hz   T,<st>,<dist_m>,<rssi>,<bearing>,<conf>,
                       <front_cm>,<rear_cm>,<servo_deg>,<L%>,<R%>,<heap_kb>
CMD write         PING · VER · STAT · MODE · ARM · GET · SET · CAL ·
                  SAVE · UNBOND · …  (firmware commands.c interpreter)
RSP notify        OK …  |  E <n> <reason>
```

### 7.2 Product-vision packet protocol (future GPS module)

The bag-module PRD targets a binary-style protocol once GPS and battery
hardware land:

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
  force the simulation source and stage any screen/pose for screenshots
  (table in the README); the live BLE source is never affected by them.
- **Palette lock test** — `test/palette_test.dart` fails the build if any
  spec token drifts from the values in `docs/PRD.md` §9.
- **RSSI parity test** — `test/rssi_model_test.dart` mirrors the firmware's
  `tools/host_test_radar.c`, locking the Dart RSSI filter, path-loss model
  and telemetry/STAT parsers to the exact firmware behaviour.
- **Deterministic simulation** — same script, same result; demos never
  surprise a presenter.
- **Manual BLE verification** — the device panel's `PING` / `VER` / `STAT` /
  `GET ALL` commands exercise the real GATT link and stream the module's
  responses for field debugging.
