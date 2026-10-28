<div align="center">

# Trackio — PRD

**Product requirements for smart bag tracking: features, bag module, backend, design tokens, roadmap.**

[![← README](https://img.shields.io/badge/%E2%86%90_README-home-001233?style=flat-square)](../README.md)
[![Architecture](https://img.shields.io/badge/docs-architecture-4c5769?style=flat-square)](ARCHITECTURE.md)
[![Demo guide](https://img.shields.io/badge/docs-demo_guide-4c5769?style=flat-square)](DEMO_GUIDE.md)
[![MIT license](https://img.shields.io/badge/license-MIT-0052eb?style=flat-square)](../LICENSE)

</div>

---

| | |
|---|---|
| **Product** | Trackio — smart bag tracking |
| **Document status** | v1.1 — product spec with live BLE implementation status |
| **Platforms** | Android & iOS (Flutter client), web via Web Bluetooth (Chrome/Edge) |
| **Repo** | `git@github.com:abdou-da0wew/Trackio.git` (branch `main`) |
| **Current build** | v1.1.0 — real ESP32 GATT link drives tracking; deterministic simulation retained as an explicit offline/QA source |

---

## 1. Overview

Bags get lost in the most ordinary ways: left at a café table, pulled from a
carousel by mistake, set down for thirty seconds and forgotten. Existing
trackers answer the question *"where was it last?"* hours too late. Trackio
answers a different question, continuously: **how far is my bag from me, right
now — and is something wrong?**

Trackio pairs a phone app with a small ESP32-based module that lives in the
bag. The phone fuses three location sources — its own GPS, the bag module's
GPS, and the short-range radio link between phone and bag — to maintain a
continuous distance estimate. When that distance behaves abnormally, the app
escalates instantly: a loud alert, a full-screen takeover, and a switch to
high-frequency "panic packets" so the bag reports where it is as often as it
can, for as long as it can, until the user confirms the bag is physically back
in hand.

The product is deliberately simple to live with: one bag, one screen, one
number (the distance), and a handful of smart thresholds doing the watching
so the user doesn't have to.

## 2. Goals

1. **Zero-attention monitoring.** After pairing, tracking runs continuously
   in the background with no user interaction, resuming automatically after
   app restarts, connectivity interruptions, or system kills.
2. **Seconds, not hours, to a loss event.** Abnormal distance is detected and
   surfaced within one recheck interval (user-configurable), not on the next
   time the user thinks to open the app.
3. **Actionable recovery.** During a loss event the app does not just notify
   — it switches the bag module into panic mode and walks the user through
   recovery until they explicitly confirm the bag is found.
4. **Calm by default.** One glanceable dashboard (distance, status, battery),
   dark-first design, no feeds, no gamification, no noise.

### Non-goals (v1)

- Multi-bag management (single paired bag).
- Social features, sharing, web dashboard for end users.
- Cellular fallback in the bag module (Wi-Fi/BLE/FM-class radio link only).
- Crowd-sourced finding networks.

## 3. Target users & personas

| Persona | Context | What wins them |
|---|---|---|
| **The commuter** | Daily metro/bus rides with a laptop bag | Passive monitoring; the 30-second forget at the coffee shop |
| **The traveller** | Airports, carousels, taxis | Bag-GPS last-known position on a map, panic mode when the bag leaves the area |
| **The student / café worker** | Long sessions in shared spaces | Silent drift warnings before the bag is actually gone |
| **The parent** | School bags, crowded events | A loud, unmistakable alert; simple recovery flow |

## 4. System overview

```
┌────────────────────┐        radio link (BLE/FM-class)       ┌────────────────────┐
│   Phone — app      │ ◄────────────────────────────────────► │  Bag — ESP32 module│
│  • fused tracking  │   beacons · GPS fixes · panic packets  │  • radio beacon    │
│  • map, history    │                                        │  • GPS receiver    │
│  • alerts & sound  │                                        │  • panic mode      │
└─────────┬──────────┘                                        └────────────────────┘
          │ HTTPS (auth, sync, history, tile/config)
┌─────────▼──────────────────────────────────────────────────────────────────────────┐
│  Backend — self-hosted on a private VDS: Supabase (auth/DB/realtime) + Tigris (S3) │
└────────────────────────────────────────────────────────────────────────────────────┘
```

Three subsystems:

1. **The bag module** — ESP32 + GPS + radio beacon + battery. See §7.
2. **The mobile app** — Flutter client, the focus of this repository. See §5.
3. **The backend** — self-hosted Supabase and Tigris storage on a private
   VDS. See §8.

## 5. Functional requirements — mobile app

### 5.1 Continuous tracking

| ID | Requirement |
|---|---|
| FR-T1 | The app detects the bag module's radio signal using the phone's receiver hardware (FM-chip / BLE-class detection as available on the platform) and reports live link status (connected / weak / lost) with signal strength. |
| FR-T2 | The app fuses **phone GPS** and **bag-module GPS** (received over the radio link) into a single distance estimate, shown continuously in metres. |
| FR-T3 | Distance monitoring runs continuously in the background; the app re-checks the distance at a user-configurable interval (default: 10 s). |
| FR-T4 | GPS position refresh runs at a user-configurable interval (default: 5 s); higher-frequency GPS is used automatically in panic mode. |
| FR-T5 | Tracking state survives interruptions: after app restart, system kill, or temporary connectivity loss, tracking is **restored automatically** to the same bag and thresholds. |
| FR-T6 | The dashboard shows, at all times: current distance, link status, bag battery, last-sync time, and the active tracking phase (safe / drifting / weak / lost / recovering). |

### 5.2 Lost-bag flow

| ID | Requirement |
|---|---|
| FR-L1 | A **warning** is raised when the fused distance exceeds the drift threshold (default 30 m): non-intrusive banner + subtle sound, auto-dismisses when the distance normalises. |
| FR-L2 | A **loss event** is declared when the distance exceeds the loss threshold (default 80 m) **or** the radio link drops: immediate full-screen alert takeover with the user's chosen notification sound, regardless of which screen is open. |
| FR-L3 | On loss, the app commands the bag module into **panic mode**: the module switches to high-frequency reporting (panic packets — 1 Hz GPS fixes plus radio beacons, for as long as battery allows) and the app displays a live panic-packet counter. |
| FR-L4 | The alert remains active and the bag keeps reporting **until the user explicitly confirms the bag is found** ("I found my bag"). Silencing the sound never ends the tracking state; only confirmation does. |
| FR-L5 | Recovery assistance: when the bag is re-detected, the app switches to a recovery view — live distance to the bag's live position, direction on the map — and celebrates confirmation. |
| FR-L6 | The chosen notification sound is selectable from at least three bundled alarms, with preview playback (Settings → Sound). |

### 5.3 Maps

| ID | Requirement |
|---|---|
| FR-M1 | The map shows **phone position** and **bag position** simultaneously, with the live distance displayed on the connector. |
| FR-M2 | Map tiles: OpenStreetMap-class (keyless) tiles in v1; Google Maps as an alternative provider. Dark styling to match the app theme. |
| FR-M3 | The phone's and bag's **movement routes** are drawn as trails for the current session. |
| FR-M4 | Bag accuracy is shown as a circle around the bag marker; in panic mode the marker pulses on each incoming panic packet. |
| FR-M5 | If the radio link is lost, the bag marker stays pinned at its **last-known position** with a visual "last known" state. |

### 5.4 History

| ID | Requirement |
|---|---|
| FR-H1 | History records: locations, movement routes, **historical distance values** (timeline), connection interruptions, lost-bag events, and recovery activity. |
| FR-H2 | The distance timeline renders as a chart with the loss event visibly banded; events are listed with severity colouring. |
| FR-H3 | Summary stats per day: peak distance, alerts raised, time tracked. |

### 5.5 Settings

| ID | Requirement |
|---|---|
| FR-S1 | Dark / light theme (dark is the default). |
| FR-S2 | Lost-bag notification **sound picker** with preview playback. |
| FR-S3 | Configurable recheck intervals: GPS refresh, distance re-check, and (advanced) panic-mode reporting cadence. |
| FR-S4 | Account section: signed-in identity, logout. |

### 5.6 Accounts & auth

| ID | Requirement |
|---|---|
| FR-A1 | Sign-up with name, e-mail, password; **OTP verification** of the e-mail address before first entry. |
| FR-A2 | Login with remembered session; logout from Settings. |
| FR-A3 | Auth backend is Supabase (self-hosted). The current build implements the identical contract over an in-memory mock service so the production swap is a drop-in replacement; the BLE tracking pipeline does not depend on it and works fully offline. |

## 6. User journey (happy path → loss → recovery)

```
Install → Sign up → OTP → Connect screen → scan ESP32-FollowCar → pair (passkey 246810)
   │
   ├─ RSSI weakens past -82 dBm / 30 m fence ──► warning banner
   │
   ├─ link drops / RSSI ≤ -94 dBm sustained ──► FULL-SCREEN ALERT + alarm sound
   │        └─► panic mode ON (each 2 Hz telemetry frame counts as a live fix)
   │
   ├─ user approaches the module ──► link re-detected ──► recovery view
   │
   └─ "I found my bag" ──► panic mode OFF ──► celebration ──► Safe
```

The connect screen also offers *Explore without hardware*, which runs the
deterministic simulation engine behind the same `TrackingEngine` interface
(the path used by the `?shot=…` staging deep links).

## 7. Bag module (ESP32) requirements

The current firmware (`esp32-follow-car`, ESP-IDF v5.5, ESP-WROOM-32)
implements the GATT server, secure pairing, 10 Hz link-RSSI polling with
the median-3/EMA filter and log-distance path-loss model, a servo-driven
radar sweep for bearing, and 2 Hz telemetry notifications. Field-by-field
mapping lives in [`BLE_INTEGRATION.md`](BLE_INTEGRATION.md).

| ID | Requirement | Firmware status |
|---|---|---|
| HW-1 | Radio beacon/link so the phone can measure presence and strength (10 Hz RSSI polling, 2 Hz telemetry) | ✅ shipped |
| HW-2 | GPS receiver reporting fixes over the radio link (bag GPS used in fusion; ~±5 m outdoors) | ⏳ not on current board — app uses RSSI distance + radar bearing meanwhile |
| HW-3 | **Panic mode**: high-cadence reporting with tight accuracy, persistent until cancelled | 🔶 partial — app counts every live frame during a loss; 1 Hz panic cadence + persistence pending |
| HW-4 | Battery: ≥ 8 h active tracking, battery % in every frame | ⏳ current board is wired-powered; app shows "wired power" rather than a fake percentage |
| HW-5 | Store-and-forward of the last fix across link drops | ⏳ firmware learns the bonded phone address and rescans after disconnects |
| HW-6 | Secure pairing channel | ✅ shipped — LE Secure Connections + MITM + bond, static passkey `246810` |

## 8. Backend requirements

| ID | Requirement |
|---|---|
| BE-1 | **Self-hosted Supabase** on a private VDS: e-mail + OTP auth, Postgres tables (`users`, `bags`, `pairings`, `events`, `distance_samples`, `sessions`), Realtime channel for panic-packet relay when the phone is offline. |
| BE-2 | **Tigris object storage** (S3-compatible) on the same VDS for larger artifacts (route exports, future firmware OTA payloads). |
| BE-3 | Row-level security: a user reads/writes only their own bag's data. |
| BE-4 | The mobile app must degrade gracefully to full offline operation (local history, queued sync) — the bag link, not the cloud, is the source of truth for live tracking. |

## 9. Design system

Dark-first. The complete palette is codified in `lib/core/palette.dart` and
**locked by a unit test** (`test/palette_test.dart`). Semantic amber/red/green
are reserved for alert severities only.

### Colour scales (exact values from the specification)

**Smart Blue** — default `#0466C8`

| 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|
| `#011428` | `#022950` | `#023D78` | `#0352A0` | `#0466C8` | `#0F85FA` | `#4BA3FB` | `#87C2FD` | `#C3E0FE` |

**Sapphire** — default `#0353A4`

| 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|
| `#011121` | `#012242` | `#023263` | `#034384` | `#0353A4` | `#0576E8` | `#3698FB` | `#79BBFC` | `#BCDDFE` |

**Regal Navy** — default `#023E7D`

| 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|
| `#000C19` | `#011932` | `#01254B` | `#023164` | `#023E7D` | `#0363C9` | `#1D89FC` | `#68B0FD` | `#B4D8FE` |

**Prussian Blue v1** — default `#002855`

| 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|
| `#000811` | `#001023` | `#001834` | `#002045` | `#002855` | `#0050AB` | `#0178FF` | `#56A5FF` | `#AAD2FF` |

**Prussian Blue v2** — default `#001845`

| 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|
| `#00050E` | `#000A1D` | `#000F2B` | `#001439` | `#001845` | `#00389F` | `#0056F7` | `#508DFF` | `#A7C6FF` |

**Prussian Blue v3** — default `#001233`

| 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|
| `#00040A` | `#000714` | `#000B1F` | `#000E29` | `#001233` | `#00328F` | `#0052EB` | `#4788FF` | `#A3C3FF` |

**Twilight Indigo** — default `#33415C`

| 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|
| `#0A0D12` | `#141A25` | `#1E2737` | `#29344A` | `#33415C` | `#4D628B` | `#7186B1` | `#A0AECB` | `#D0D7E5` |

**Blue Slate** — default `#5C677D`

| 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|
| `#131519` | `#252A32` | `#383F4C` | `#4B5365` | `#5C677D` | `#79859C` | `#9BA3B5` | `#BCC2CE` | `#DEE0E6` |

**Slate Grey** — default `#7D8597`

| 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|
| `#191A1F` | `#31353D` | `#4A4F5C` | `#62697A` | `#7D8597` | `#979DAB` | `#B1B6C0` | `#CBCED5` | `#E5E7EA` |

**Lavender Grey** — default `#979DAC`

| 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|
| `#1D1F24` | `#393D47` | `#565C6B` | `#737A8E` | `#979DAC` | `#ABB0BC` | `#C0C4CD` | `#D5D7DD` | `#EAEBEE` |

### Typography

Loaded through the `google_fonts` package — the plan is locked in
`lib/core/fonts.dart`:

- **English UI (all text):** Rubik — variable 300–900, so headings, body and
  numerals render with true weights.
- **Logo / stylised brand moments only:** Jaro — single-weight (400) display
  face reserved for the wordmark and branded surfaces; never for body copy,
  buttons or data.
- **Arabic UI only:** Zain — applied automatically by the app-level builder
  in `lib/app.dart` whenever the resolved locale is `ar`.
- Tabular numerals for the distance readout; no text smaller than 12 px.

### Localisation

- **Languages:** English (`en`) and Arabic (`ar`) — official `gen_l10n`
  pipeline, `.arb` bundles under `lib/l10n/`, iOS `CFBundleLocalizations`
  declared.
- **Detection & override:** the platform locale resolves against
  `supportedLocales` per the Flutter docs; the in-app
  *Settings → Language* control (System / English / العربية) persists and
  overrides instantly.
- **RTL:** full right-to-left mirroring for Arabic, including navigation and
  map chrome; Zain replaces Rubik automatically when the locale is `ar`.
- **Locale-free engines:** both the BLE and simulation engines emit
  message codes + params; localized rendering lives in
  `lib/core/l10n_text.dart`, so every event and caption is translatable.

## 10. Implementation status (this repository)

The app runs two interchangeable tracking sources behind one
`TrackingEngine` interface; the live BLE source is the default.

**Real, working code — live BLE source:**

- GATT central transport (`flutter_blue_plus`): service-UUID scan, LE
  Secure Connections pairing with the static passkey, encrypted telemetry
  and response subscriptions, command writes, MTU negotiation, persisted
  last-device and exponential-backoff reconnect (FR-T1, FR-T5, HW-6).
- Firmware-identical RSSI filter and path-loss distance math, unit-tested
  against the firmware's own host tests; live telemetry frames feed the
  full phase machine, thresholds, loss/panic flow and recovery (FR-L1–L5).
- Connect/pair screen, device control panel with the firmware command
  interpreter, relative polar radar (distance + radar-sweep bearing),
  wired-power indicator and live history/event log.
- Android 12+ BLE runtime permissions (legacy location fallback), iOS
  usage strings, Web Bluetooth support.

**Real, working code — shared by both sources:** every screen and
interaction, the tracking phase machine, alarm playback with three bundled
sounds and previews (FR-L6), dark/light themes, English + Arabic with full
RTL, settings persistence, history chart and event log (FR-H1–H3, FR-S1–S4).

**Deterministic simulation source (offline/QA):** the Cairo walking-loop
engine, scripted scenario with manual triggers and speed control, keyless
Esri geographic map, and `?shot=…` staging deep links — all behind the same
interface the live engine implements.

**Mocked behind interfaces:** auth (in-memory service with the Supabase
OTP contract and persisted session; FR-A1–A3) and the Supabase/Tigris
backend. Swap instructions live in [`ARCHITECTURE.md`](ARCHITECTURE.md)
and [`BLE_INTEGRATION.md`](BLE_INTEGRATION.md).

## 11. Repository conventions

- Remote: `git@github.com:abdou-da0wew/Trackio.git`, primary branch `main`.
- The v1.0 demo build introduced the UI, phase machine and deterministic
  simulation; v1.1 replaced the demo default with the real ESP32 BLE link
  described in [`BLE_INTEGRATION.md`](BLE_INTEGRATION.md).
- Commit style and code rules: see `CONTRIBUTING.md`.

## 12. Roadmap

| Milestone | Contents | Status |
|---|---|---|
| **M1 — Real sensing** | BLE GATT link, secure pairing, RSSI distance + radar bearing, reconnect, six-state machine on real link events | ✅ shipped (GPS fusion still pending — module currently has no GPS) |
| **M2 — Cloud** | Self-hosted Supabase on VDS; swap mock auth for `supabase_flutter`; history sync; Tigris for exports | ⏳ next |
| **M3 — Panic hardening & background** | Foreground service + OS notification channel, 1 Hz panic cadence on the module, store-and-forward last fix, panic persistence across module restarts | ⏳ planned |
| **M4 — Module hardware** | GPS receiver and battery telemetry on the ESP32 board, enabling the geographic map and HW-2/HW-4 requirements | ⏳ planned |
| **M5 — Ship** | Play Store / TestFlight polish, battery whitelisting UX, onboarding analytics | ⏳ planned |
