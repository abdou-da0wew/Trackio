# Changelog

All notable changes to Trackio are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/) and the project adheres to
semantic versioning.

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
