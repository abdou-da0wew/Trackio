<div align="center">

<img src="assets/brand/trackio_icon.png" alt="Trackio logo — radar sweep locking onto a bag" width="128" />

# Trackio

### A live Bluetooth lock on your bag — ESP32 radio distance, radar bearing and instant lost-bag alerts.

**Range warnings at −82 dBm. A full-screen alarm when the link drops. Radar-guided recovery that only ends when you're holding the bag again.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/platform-Android_%7C_iOS_%7C_Web-001233?style=flat-square)](#quick-start)
[![Languages](https://img.shields.io/badge/languages-English_%7C_%D8%A7%D9%84%D8%B9%D8%B1%D8%A8%D9%8A%D8%A9-0052eb?style=flat-square)](#languages)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-2da78f?style=flat-square)](CONTRIBUTING.md)
[![MIT license](https://img.shields.io/badge/license-MIT-0052eb?style=flat-square)](LICENSE)
[![Live BLE](https://img.shields.io/badge/live-ESP32_BLE-2da78f?style=flat-square)](docs/BLE_INTEGRATION.md)
[![Demo mode](https://img.shields.io/badge/offline-movie_mode-5C677D?style=flat-square)](docs/DEMO_GUIDE.md)

**[Demo guide](docs/DEMO_GUIDE.md) · [Architecture](docs/ARCHITECTURE.md) · [Product spec](docs/PRD.md) · [Gallery](docs/screenshots)**

[Quick start](#quick-start) · [How Trackio works](#how-trackio-works) · [The lost-bag flow](#the-lost-bag-flow) · [What's real vs simulated](#whats-real-vs-simulated) · [Screenshots](#screenshots) · [FAQ](#faq) · [Documentation](#documentation)

<code>flutter run -d chrome</code>

<br />

<img src="docs/assets/hero.png" alt="Trackio dashboard with radar, live map with connector line, and the panic-mode alert" width="1200" />

<br /><br />

</div>

---

Bags get lost in ordinary ways — left at a café table, pulled from a carousel
by mistake, set down for thirty seconds and forgotten. Existing trackers tell
you where the bag *was*, hours later. Trackio answers a different question,
continuously: **how far is my bag from me right now, and is something wrong?**

The product vision fuses three signals — the phone's GPS, a future bag
module GPS, and the short-range ESP32 radio link — into one distance
estimate. The shipping follow-car module delivers that radio link today:
the app measures live RSSI, converts it with a log-distance path-loss model
identical to the firmware's, and reads the module's radar-sweep bearing.
When the distance behaves abnormally or the link drops, the app escalates
on its own: a warning banner, then a full-screen alarm, then panic mode
where every incoming telemetry frame is counted as a live fix. The alert
never expires on its own; only **"I found my bag"** ends it.

> The tracking pipeline now runs on a **real BLE link** to the ESP32
> follow-car/bag-module firmware: scan, secure pairing (passkey `246810`),
> live RSSI/telemetry, reconnect and the full loss state machine. The
> deterministic simulation remains available as an explicit offline/QA
> mode behind the same `TrackingEngine` interface. See
> [BLE integration](docs/BLE_INTEGRATION.md) and
> [What's real vs simulated](#whats-real-vs-simulated).

## How Trackio works

One phone, one bag module, one self-hosted cloud — and a radio link that is
the source of truth for everything live.

<img src="docs/assets/architecture.png" alt="System architecture: Trackio app and ESP32 bag module over a radio link, syncing to self-hosted Supabase and Tigris on a private VDS" width="1000" />

<br /><br />

The fused distance is computed on every recheck tick from three noisy inputs.
Thresholds turn that number into behaviour — no feeds, no dashboards, no
noise:

<img src="docs/assets/fusion.png" alt="Data flow: phone GPS, radio RSSI and bag GPS feed a fusion engine whose distance passes a 30 m and 80 m threshold check driving the UI and event log" width="1000" />

## The lost-bag flow

The tracking engine is a five-state machine with configurable thresholds.
It watches so you don't have to — and it never forgets a bag:

<img src="docs/assets/lifecycle.png" alt="State machine: Safe to Warning at 30 metres, Lost with panic packets at 80 metres or link drop, Recovering after reacquisition, Found on confirmation under 2 metres" width="1000" />

| Phase | Trigger | What you see |
|---|---|---|
| **Safe** | distance < 30 m, link healthy | Quiet dashboard: distance, radar, battery, RSSI |
| **Warning** | distance ≥ 30 m | Non-intrusive banner + soft chime; self-dismisses on re-attach |
| **Lost · Panic** | distance ≥ 80 m **or** radio link drop | Full-screen alert + chosen alarm; bag reports at 1 Hz; packet counter climbs; map pins last-known position with pulsing rings |
| **Recovering** | link re-detected | Live shrinking distance, return route on the map |
| **Found** | distance < 2 m + your confirmation | Celebration, panic mode off, event logged |

Silencing the alarm never ends the state. The live module is wired-powered,
so BLE mode shows a "wired power" indicator; the offline simulation models
battery drain during panic mode on the bag card.

## Quick start

```bash
git clone git@github.com:abdou-da0wew/Trackio.git
cd Trackio
flutter pub get
flutter run               # Android phone gives the full BLE experience
flutter run -d chrome     # Web Bluetooth (Chrome/Edge, HTTPS) also works
```

**To track a real bag:** power the ESP32 module (firmware and GATT contract
in [BLE integration](docs/BLE_INTEGRATION.md)), sign in, tap **Scan for
devices**, choose `ESP32-FollowCar`, and enter passkey **246810** in the
system pairing dialog. The dashboard then runs on live 2 Hz telemetry.

No API keys. No accounts. The map tiles are keyless. After sign-in the app
opens the **connect screen**: power on an ESP32 module running the
[follow-car firmware](docs/BLE_INTEGRATION.md), scan, pair with passkey
`246810`, and live RSSI telemetry drives the dashboard. *Explore without
hardware* falls back to the deterministic simulation engine.

### Stage shortcuts (deep links, simulation source)

Deep links force the deterministic simulation engine so QA and screenshots
are repeatable; they never touch Bluetooth.


| URL fragment | Stage |
|---|---|
| `?shot=home&state=tracking` | Dashboard, live tracking |
| `?shot=home&state=warning` | Distance-warning state |
| `?shot=home&state=alert` | Panic overlay + alarm |
| `?shot=map&state=alert` | Recovery map in panic mode |
| `?shot=home&state=found` | Recovered state |
| `?shot=splash/onboarding/login/otp` | Entry screens |
| `?panel=1` | Auto-open the demo control panel |
| `?theme=light` / `?theme=dark` | Force a theme |

In simulation mode the **🧪 demo lab** (bottom-right in-app) opens manual
controls — drift the bag, cut the radio link, send panic packets, recover,
reset — plus the scripted loss-and-recovery scenario with 1×/4×/8× speed.
On the live BLE source the same button opens the **device panel** (link
status, `PING`/`STAT`/`MODE` commands, response log). The full
five-minute presentation script lives in the
[demo guide](docs/DEMO_GUIDE.md).

## What's real vs simulated

Honest about the seams — the radio link is real, and the boundaries are
stated plainly:

| Component | In this build | In production |
|---|---|---|
| Every screen & interaction | ✅ real, working code | same |
| BLE transport: scan, secure pair/bond, GATT notify/write, reconnect | ✅ real (`flutter_blue_plus`, Android/iOS/web) | same |
| RSSI filtering + path-loss distance | ✅ real, Dart port of the firmware DSP, fed by the module's 2 Hz telemetry | same |
| Tracking phase machine, thresholds, panic/loss flow | ✅ real logic on real link events (RSSI, disconnect, reconnect) | same |
| Relative radar (distance + radar-sweep bearing) | ✅ real telemetry, polar view (module has no GPS) | add GPS module for geographic map |
| Map (simulation mode) | ✅ real keyless Esri canvas tiles (dark/light) | self-hosted tiles or Google Maps — one URL string |
| Alarm sounds, themes, settings persistence | ✅ real | same |
| Offline simulation engine | ✅ deterministic Cairo-walk source behind the same interface | QA / demos only |
| Auth (signup → OTP → session) | 🔶 mock service, identical contract | `supabase_flutter` drop-in |
| Cloud sync (Supabase + Tigris on VDS) | 🔶 represented in UI | self-hosted stack per the [PRD](docs/PRD.md) |

## Languages

**English and Arabic, end to end.** Localization follows Flutter's official
`gen_l10n` pipeline (`l10n.yaml` + `.arb` bundles in [`lib/l10n/`](lib/l10n)):

- **Language detection** — the platform/browser locale list resolves against
  the supported locales (`en`, `ar`), exactly as documented in the Flutter
  internationalization guide.
- **In-app switch** — *Settings → Language* offers **System / English /
  العربية**; the choice persists and overrides the system instantly.
- **Full RTL** — the whole layout mirrors automatically for Arabic, including
  navigation, cards, charts and the map chrome.
- **Typeface plan** — Rubik for English, Zain for Arabic (applied
  automatically when the resolved locale is `ar`), Jaro reserved for the
  logo. All three are **bundled as assets**, so nothing is fetched from the
  network at runtime — the app renders identically offline.
- **Even the engines speak in codes** — both BLE and simulation events use
  locale-free message codes resolved to localized text in the UI layer
  (`lib/core/l10n_text.dart`), so the event log, device panel and movie-mode
  captions are fully translated.

## Screenshots

> The gallery below shows the simulation source (used for repeatable
> staging). The live BLE build adds a scan/pair connect screen, a device
> control panel and a polar relative-radar map; the dashboard, alert and
> history surfaces are otherwise identical.

| | | |
|---|---|---|
| ![Splash](docs/screenshots/01-splash.png) | ![Home — tracking](docs/screenshots/05-home-tracking.png) | ![Map](docs/screenshots/08-map.png) |
| *Splash & radar identity* | *Dashboard — safe, 8 m* | *Live map with connector & distance* |
| ![Alert — panic](docs/screenshots/07-alert-panic.png) | ![Map — panic](docs/screenshots/09-map-panic.png) | ![History](docs/screenshots/10-history.png) |
| *Lost-bag alert + panic mode* | *Panic pulses on last-known pin* | *Distance timeline & event log* |
| ![Home — found](docs/screenshots/12-home-found.png) | ![Settings](docs/screenshots/11-settings.png) | ![Home — light](docs/screenshots/15-home-light.png) |
| *Recovered & confirmed* | *Language, sounds, intervals* | *Light theme* |
| ![Arabic — RTL](docs/screenshots/16-arabic-dashboard.png) | | |
| *Arabic UI — full RTL, Zain typeface* | | |

Full gallery (16 shots, both themes + Arabic RTL): [`docs/screenshots/`](docs/screenshots).

## FAQ

<details>
<summary><strong>Is this a real Bluetooth connection?</strong></summary>

Yes. The app scans for the ESP32 GATT service, pairs using LE Secure
Connections (static passkey `246810`), subscribes to the encrypted telemetry
characteristic and feeds real 2 Hz RSSI/distance/bearing frames through the
state machine. Reconnect after a dropped link is automatic with exponential
backoff. The full protocol is documented in
[docs/BLE_INTEGRATION.md](docs/BLE_INTEGRATION.md). The current follow-car
firmware has no GPS receiver, so position is rendered as a polar
distance/bearing radar rather than map coordinates; the deterministic
simulation source remains available for offline work and staged
screenshots.

</details>

<details>
<summary><strong>What happens if I kill the app?</strong></summary>

The bonded module id is persisted, so on relaunch the app auto-reconnects
and resumes tracking with the same thresholds (FR-T5 in the
[PRD](docs/PRD.md)). A foreground service plus OS notification channel for
background alarms while the app is closed is roadmap milestone M3.

</details>

<details>
<summary><strong>Why does the alarm keep ringing until I confirm?</strong></summary>

Because "silence" is not "found". The state machine only leaves
<em>Lost · Panic</em> through <strong>"I found my bag"</strong> — on real
link drops and on simulated ones alike, so the rule is enforced by the
product, not by the presentation.

</details>

<details>
<summary><strong>Why panic packets at 1 Hz?</strong></summary>

It's the highest sustainable cadence for the module's battery budget, with
accuracy tightening to ±3 m — enough to guide a human to a bag in a crowded
place. The follow-car firmware currently streams telemetry at 2 Hz, and the
app counts every frame received during a loss as a live fix packet in the
panic counter; the product firmware target adds 1 Hz panic cadence, battery
level per packet and store-and-forward of the last fix across link drops.

</details>

<details>
<summary><strong>Which map provider does it use?</strong></summary>

The live BLE source has no GPS coordinates, so it renders a polar radar
(distance + radar-sweep bearing). The simulation source uses keyless Esri
canvas tiles styled to the theme — no API key, no watermark.
OpenStreetMap-class or Google Maps are one <code>urlTemplate</code> change;
a GPS-equipped module would unlock the geographic map in live mode.

</details>

<details>
<summary><strong>Does the app need a backend or internet connection?</strong></summary>

No. The BLE link, tracking state machine, history, alarms and settings all
run on-device; the radio link — not the cloud — is the source of truth.
Auth is currently an in-memory mock with a persisted session, and only the
optional simulation map tiles need internet. The self-hosted Supabase +
Tigris backend described in the [PRD](docs/PRD.md) is the production story,
not a runtime dependency.

</details>

<details>
<summary><strong>I hit a bug</strong></summary>

For simulation issues, open an [issue](https://github.com/abdou-da0wew/Trackio/issues)
with the reproducing deep link (e.g. <code>?shot=home&state=alert&panel=1</code>).
For BLE issues, include the platform, Android/iOS version, module firmware
output, and the device panel's response log.

</details>

## Brand assets

The logo is a **radar sweep locking onto a bag**: range rings and a sweep
wedge behind a rounded bag with a tracking target on its face — a visual
summary of RSSI distance + radar bearing over the live BLE link. Vector
sources (`trackio_mark.svg` / `trackio_icon.svg`) and in-app PNGs live in
[`assets/brand/`](assets/brand/); the reproducible ImageMagick render
pipeline and per-platform sizing rules are in [`tool/logo/`](tool/logo/).
Adaptive/monochrome/maskable variants ship for Android, iOS and web.

## Documentation

| Doc | Contents |
|---|---|
| [`docs/BLE_INTEGRATION.md`](docs/BLE_INTEGRATION.md) | Live GATT link: UUIDs, pairing, telemetry frame, RSSI math, loss rules, platform notes |
| [`docs/PRD.md`](docs/PRD.md) | Full product requirements: features, bag module (ESP32), backend, complete colour-spec tables, roadmap |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Layers, BLE + simulation engines, data model, ESP32 packet protocol, mock→production swap table |
| [`docs/DEMO_GUIDE.md`](docs/DEMO_GUIDE.md) | 5-minute stakeholder script, manual controls, deep links, FAQ |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Ground rules (palette tokens, service boundaries), commit style |
| [`CHANGELOG.md`](CHANGELOG.md) | Release notes |
| [`SECURITY.md`](SECURITY.md) | Responsible disclosure |

## Contributing

We'd love your help — GPS-bearing hardware for the module, `supabase_flutter`
wiring, ESP32 firmware features, background tracking, localisation and
widget tests. Open an [issue](https://github.com/abdou-da0wew/Trackio/issues)
or a [pull request](https://github.com/abdou-da0wew/Trackio/pulls);
[CONTRIBUTING.md](CONTRIBUTING.md) has the ground rules. Every change is gated
by `flutter analyze` and `flutter test` — the palette-lock and RSSI-parity
tests mean design tokens and firmware-matching DSP cannot silently drift.

## Disclaimer

Trackio's BLE distance comes from an RSSI path-loss model whose accuracy
depends on hardware, antennas, radio conditions and the environment
(expect roughly ±20–40 % distance error indoors); it is an assistance tool,
not a safety device. The offline simulation is provided for development and
presentations. Keep an eye on your bag regardless.

## License

[MIT](LICENSE) — alarm sounds and artwork are generated originals for this
project.
