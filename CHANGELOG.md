<div align="center">

# Changelog

**All notable changes, following [Keep a Changelog](https://keepachangelog.com/) and semver.**

[![← README](https://img.shields.io/badge/%E2%86%90_README-home-001233?style=flat-square)](README.md)
[![MIT license](https://img.shields.io/badge/license-MIT-0052eb?style=flat-square)](LICENSE)

</div>

---

All notable changes to Trackio are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/) and the project adheres to
semantic versioning.

## [Unreleased]

### Added

- **Full Arabic localization (RTL)** via Flutter's official `gen_l10n`
  pipeline: `l10n.yaml`, `.arb` bundles in `lib/l10n/`, generated
  `AppLocalizations` wired into `MaterialApp` with `supportedLocales: [en, ar]`
  and iOS `CFBundleLocalizations`. Every screen, setting, event-log entry and
  demo caption is translated; the layout mirrors automatically in RTL.
- **In-app language switcher** — *Settings → Language* (System / English /
  العربية), persisted and applied instantly; `system` follows the platform
  locale per the Flutter internationalization docs.
- **New Arabic dashboard screenshot** (`16-arabic-dashboard.png`) in the
  gallery.

### Changed

- **Typefaces moved to Google Fonts** via the `google_fonts` package, with a
  locked three-face plan (`lib/core/fonts.dart`): **Rubik** for all English
  UI text (headings, body, numerals — variable 300–900, true weights),
  **Jaro** reserved for the logo wordmark and stylised brand moments, and
  **Zain** applied automatically when the locale is Arabic (`ar`).
- **Fonts bundled as assets** — the exact pinned TTFs (Rubik ×4, Zain ×6,
  Jaro ×1) live under `assets/google_fonts/` and
  `GoogleFonts.config.allowRuntimeFetching = false`, so the app renders
  identically offline with zero font flash.
- **Simulation layer made locale-free** — `TrackEvent` now carries a message
  code + typed params (rendered by `core/l10n_text.dart`); scenario captions
  resolve from the machine-readable phase, keeping the engine reusable for
  future locales.

### Performance & polish

- Shell no longer rebuilds the whole tab tree on every engine tick — sound
  hooks moved to an engine listener; only the caption HUD and alert overlay
  listen to the simulation.
- Dashboard narrowed: the hero radar card and recent-activity list rebuild
  per tick, the rest of the screen is static; `RepaintBoundary` around the
  radar sweep, mini-map and panic rings.
- Micro-interactions: press-scale on buttons, animated distance readout,
  animated status pill, OTP shake on wrong code.
- New states: sign-out confirmation dialog, "bag recovered" toast, map
  connection-lost banner, localized empty/error states.

## [1.0.0] — Stakeholder demonstration build

### Added

- **Tracking simulation engine** — fused phone-GPS / bag-GPS / radio pipeline
  over a walking loop in Zamalek (Cairo), 30 m warning and 80 m loss
  thresholds, RSSI modelling, battery drain, automatic reconnection retries.
- **Lost-bag flow** — distance warning → full-screen alert with alarm sound →
  panic mode (1 Hz fixes, ±3 m accuracy, panic-packet counter, pulsing map
  rings) → guided recovery → "I found my bag" confirmation with celebration
  state.
- **Scripted demo mode** (`ScenarioDirector`) — one-tap loss-and-recovery
  "movie" with timed phase captions, plus a manual trigger panel (drift, cut
  link, panic packets, recover, reset) and 1×/4×/8× simulation speed.
- **Map screen** — keyless Esri canvas tiles (dark/light), phone and bag
  routes, connector line, distance pill, accuracy circle, panic pulses,
  glass status bar and bag card.
- **History** — summary stats, distance-timeline chart with loss band, event
  log with severity colouring.
- **Auth (mock, Supabase-ready)** — signup → 6-digit OTP with demo hint
  banner → session persistence; login and logout.
- **Settings** — dark/light theme, three alarm sounds with preview playback,
  GPS/recheck interval sliders, backend status panel, account section.
- **QA stage shortcuts** — URL deep links (`?shot=…&state=…&theme=…&panel=1`)
  that stage any screen and tracking state for screenshots and demos.
- **Design system** — the ten colour scales from the product spec codified in
  `lib/core/palette.dart` and locked by `test/palette_test.dart`; dark and
  light themes built exclusively from those tokens; Space Grotesk display +
  Inter body typography bundled locally; generated radar-and-bag app icon and
  synthesized alarm sounds (original assets).
