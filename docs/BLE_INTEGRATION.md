# BLE integration — Trackio app ↔ ESP32 follow-car firmware

How the live phone link works, mapped field-by-field to the ESP-IDF
firmware in `esp32-follow-car/main/` (`ble_link.c`, `telemetry.c`,
`commands.c`, `radar_math.c`, `settings.c`).

## 1. GATT profile

The module runs a Bluedroid GATT **server**; the phone is a GATT
**central** (`flutter_blue_plus`). One 128-bit base UUID, stored
little-endian in the firmware:

| Role | UUID | Properties | Firmware |
|---|---|---|---|
| Service | `f7a90001-6b8d-4c3e-a2f1-5d4b9c8e7a10` | primary | `UUID_SVC` |
| Command (phone → module) | `f7a90002-…` | read / write, **encrypted** | `UUID_CMD` |
| Telemetry (module → phone) | `f7a90003-…` | read / **notify**, encrypted | `UUID_TLM` |
| Response (module → phone) | `f7a90004-…` | read / **notify**, encrypted | `UUID_RSP` |

Constants live in `lib/services/ble/ble_profile.dart`.

- Advertised name: **`ESP32-FollowCar`** (`settings_t.name` default)
- Pairing: **LE Secure Connections + MITM + bonding**, static passkey
  **`246810`** (`settings_t.passkey`). Subscribing to the encrypted
  telemetry characteristic triggers the OS pairing dialog; the app
  never sends the passkey over GATT.
- ATT MTU negotiated to **220**, matching `esp_ble_gatt_set_local_mtu(220)`.

## 2. Connection lifecycle (`Esp32BleService`)

```
bootstrap()
  └─ adapter listener (on/off)
  └─ auto-connect to the last saved module id (SharedPreferences)
startScan()                       ScanResult filtered by service UUID / name
connectDevice(candidate)
  ├─ device.connect(mtu: 220)
  ├─ requestMtu(220) (best effort)
  ├─ discoverServices() → service + 3 characteristics
  ├─ setNotify(true) on TLM and RSP   ← triggers secure pairing
  └─ handshake writes: PING · VER · GET ALL · STAT
```

Unexpected GATT disconnects start exponential backoff reconnect
(1 → 2 → 4 → 8 → 12 → 16 s, 8 attempts) using the saved device id.
Manual disconnect, `UNBOND` and "forget module" suppress reconnect.

## 3. Telemetry frame → engine state

The firmware notifies one CSV frame every **500 ms**
(`telemetry_build` in `telemetry.c`):

```
T,<st>,<dist_m>,<rssi>,<bearing>,<conf>,<front_cm>,<rear_cm>,
  <servo_deg>,<L%>,<R%>,<heap_kb>
```

Parsed by `TelemetryFrame.parse` and fed to `BleTrackingEngine`:

| Frame field | App use |
|---|---|
| `st` | module nav state (`CarNavState`: I/W/S/T/D/H/A/M/X/E) |
| `dist_m` | primary distance (firmware path-loss estimate) |
| `rssi` | smoothed again on-device through the same EMA the firmware uses |
| `bearing` / `conf` | radar-sweep direction for `RadarView` / `RelativeRadarMap` (999 = invalid) |
| `front_cm` / `rear_cm` | available on the module; surfaced via STAT |
| `servo_deg`, `L%`, `R%`, `heap_kb` | diagnostics in the device panel |

If `dist_m` is invalid the app recomputes it locally with the identical
log-distance model (`RssiModel.rssiToDistanceM`), using the module's
calibrated `rssi1m` / `pathn` when `GET ALL` has reported them.

## 4. RSSI and distance math — phone/firmware parity

`lib/services/ble/rssi_model.dart` is a 1:1 Dart port of
`radar_math.c`:

- outlier gate: reject samples > **15 dB** from the running estimate
- median-of-3 window, then EMA with α **0.35**
- path loss: `d = 10 ^ ((RSSI@1m − RSSI) / (10·n))`,
  defaults `RSSI@1m = −59 dBm`, `n = 2.6`, clamped **0.15–25 m**

`test/rssi_model_test.dart` mirrors the firmware's
`tools/host_test_radar.c` so the two implementations cannot silently
diverge.

## 5. Loss state machine on real radio data

The firmware clamps distance at 25 m, so link health — not the 80 m
fence — carries the loss decision, exactly as the PRD's
"≥ 80 m **or** link drop" rule intends:

| App state | Real trigger |
|---|---|
| `tracking` | connected, RSSI > −82 dBm |
| `warning` | RSSI ≤ −82 dBm (or distance ≥ 30 m) |
| `lost` | GATT disconnect / stale frames > 4 s, or RSSI ≤ −94 dBm sustained 3 s |
| `panic` | automatically 1.6 s after `lost` while still in danger; each arriving frame counts as a live fix packet |
| `recovering` | reconnect while a loss alert is active (`linkRestored` event) |
| `found` | user confirms — silencing never ends the alert |

## 6. Command channel

Writes to the command characteristic are the firmware interpreter's
text commands (`commands.c`), answered on the response characteristic
with `OK …` / `E <n> <reason>`:

`PING` · `VER` · `STAT` · `GET ALL` · `MODE IDLE|FOLLOW|MANUAL` ·
`ARM ON|OFF` · `SERVO` · `CAL DIST` · `SAVE` · `UNBOND` …

The device panel exposes the safe subset (diagnostics plus MODE/ARM);
responses are shown in a live log.

## 7. Honest capability map

| Firmware provides | App behavior |
|---|---|
| RSSI, path-loss distance, bearing, confidence | real radar + state machine |
| No GPS | polar `RelativeRadarMap`, never invented coordinates |
| No battery telemetry (wired module) | "wired power" indicator instead of a fake percentage |
| No panic-packet stream | frames received during a loss are counted as live fixes |
| Secure bonded GATT | OS passkey dialog with the static 246810 hint |

## 8. Platform notes

- **Android**: `BLUETOOTH_SCAN` (neverForLocation) + `BLUETOOTH_CONNECT`
  at runtime; location fallback for API < 31. `minSdk` 23.
- **iOS**: `NSBluetoothAlwaysUsageDescription`; pairing is system-driven.
- **Web**: Web Bluetooth (Chrome/Edge, HTTPS) via the same
  `flutter_blue_plus` API; service-UUID filter is mandatory. Reconnect
  after reload requires a scan (no `fromId` on web).
