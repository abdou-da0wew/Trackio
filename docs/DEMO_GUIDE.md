<div align="center">

# Trackio — Demo Guide

**Present Trackio convincingly in five minutes — with a two-minute fallback and a URL for every state.**

[![← README](https://img.shields.io/badge/%E2%86%90_README-home-001233?style=flat-square)](../README.md)
[![PRD](https://img.shields.io/badge/docs-PRD-4c5769?style=flat-square)](PRD.md)
[![Architecture](https://img.shields.io/badge/docs-architecture-4c5769?style=flat-square)](ARCHITECTURE.md)
[![MIT license](https://img.shields.io/badge/license-MIT-0052eb?style=flat-square)](../LICENSE)

</div>

---

Everything you need to present Trackio convincingly in five minutes — with a
fallback two-minute version and a URL trick for every state.

---

## Before you present

```bash
flutter pub get
flutter run -d chrome     # web demo (fastest, no phone needed)
# or
flutter run               # pick Android/iOS device or emulator
```

No API keys, no accounts, no network beyond map tiles. Turn the sound ON —
the alarm is part of the show. If the browser mutes autoplay, click the app
once before the loss beat so audio is unlocked.

## The five-minute script

**Act 1 — the product (≈90 s)**

1. Splash and onboarding play (tap through the three cards).
2. Sign up with any name/e-mail; the OTP screen shows a demo hint banner —
   enter any six digits (the banner suggests one). Point out this exact flow
   maps 1:1 to Supabase OTP in production.
3. Dashboard: walk the room through the four numbers — **distance (3 m),
   link, battery, last sync** — and the radar. Mention thresholds: warn at
   30 m, declare loss at 80 m.
4. Map tab: phone and bag markers, connector line with the live distance,
   accuracy circle. History tab: yesterday's timeline is already populated.
   Settings: flip the theme, preview the three alarms, show the interval
   sliders (change one — the engine obeys live).

**Act 2 — the loss (≈2 min) — the money shot**

5. Back on the dashboard, tap the **🧪 demo lab** button → *Play scripted
   scenario* (1× speed).
6. Let the captions narrate: the bag drifts to ~35 m → **warning banner**
   appears (non-intrusive, dismisses by itself if distance normalises).
7. The link drops at >80 m → **full-screen alert + alarm sound**. Let it
   ring for two seconds before speaking. Point at the panic counter climbing
   — the module is now reporting at 1 Hz.
8. Switch to the **Map** tab: the bag is pinned at its last-known position,
   pulsing on every panic packet. The connector now shows the distance from
   you to that point.

**Act 3 — the recovery (≈90 s)**

9. Tap **Start recovery**. The app switches to recovery view — walk toward
   the bag (the scenario drives it) and the distance falls live.
10. Below 2 m the **"I found my bag"** button lands; confirm it. Panic mode
    ends, the celebration state fires, and the event log records the full
    timeline — open **History** to show the loss band on the distance chart
    and the recovered event.
11. Close in Settings → Account → Logout if you want to re-run the whole
    journey, or use the demo lab's **Reset**.

## The two-minute version (elevator)

Splash → sign-up/OTP (hint banner) → dashboard → open demo lab → scripted
scenario at **4×** speed → alert → map in panic → recovery → found →
history. The speed control exists exactly for this.

## Manual controls (improvise your own story)

The 🧪 demo lab exposes the engine's commands directly:

| Control | Effect |
|---|---|
| Drift bag | Distance starts growing while you "walk away" |
| Cut radio link | Instant loss event + alert + panic mode |
| Send panic packets | High-frequency fixes + counter + map pulses |
| Re-detect / Recover | Return journey with live shrinking distance |
| Reset | Back to Safe · 3 m |
| Speed 1× / 4× / 8× | Time multiplier for engine + scenario |

## Deep links (stage any state in one URL)

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

Example: `flutter run -d chrome` then open the printed URL with
`?shot=home&state=alert&panel=1`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| No alarm sound | Browsers block autoplay audio until first interaction — click the app once before Act 2 |
| Grey map tiles | Tile server needs internet; wait a beat or switch themes to force a reload |
| Scenario feels slow in a short meeting | Use 4× speed |
| Want a clean start for screenshots | Demo lab → Reset, or run with `?shot=splash` |

## FAQ for stakeholders

**Is this live GPS?** Not yet — this build simulates the fused
phone-GPS/bag-GPS/radio pipeline deterministically (that's what makes demos
repeatable). The phase machine, thresholds, alert flow and every screen are
production-intent; see `docs/ARCHITECTURE.md` §6 for the swap plan.

**How far from production?** The UI layer is production-intent. M1 is real
sensing (platform channels + ESP32 firmware), M2 is the self-hosted
Supabase/Tigris cloud. Roadmap in `docs/PRD.md` §12.

**What happens to the alarm if the app is killed?** In production the
foreground service keeps monitoring and the OS notification channel fires
(M3 hardening). The demo keeps monitoring in-session.

**Why panic packets at 1 Hz?** It's the highest sustainable cadence for the
module's battery budget, and accuracy tightens to ±3 m — enough to guide a
human to the bag in a crowded place.
