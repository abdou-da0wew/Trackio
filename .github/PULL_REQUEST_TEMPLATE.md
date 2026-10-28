<!--
Thanks for the PR! Quick checklist before you open it:
- flutter analyze passes with zero findings
- flutter test passes (palette-lock + RSSI/firmware-parity tests)
- no hardcoded colour literals in UI code — use palette tokens
- BLE changes must match the firmware contract in docs/BLE_INTEGRATION.md
- UI changes: attach a before/after screenshot (deep links help stage states)
-->

## What

<!-- One or two sentences: what does this PR do? -->

## Why

<!-- Link the issue, or explain the motivation. -->

## Checklist

- [ ] `flutter analyze` — clean
- [ ] `flutter test` — passing
- [ ] Palette tokens only (no `Color(0x...)` literals in UI code)
- [ ] BLE changes follow `docs/BLE_INTEGRATION.md` and never fabricate measurements
- [ ] Simulation source stays offline & deterministic
- [ ] New user-facing strings added to both `app_en.arb` and `app_ar.arb`
- [ ] Screenshots attached for visual changes

## Evidence

<!-- Screenshots / deep links / output. -->
