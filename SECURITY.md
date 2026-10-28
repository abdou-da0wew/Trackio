# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 1.1.x (live ESP32 BLE build) | ✅ |
| 1.0.x (simulation-only build) | ⚠️ upgrade to 1.1.x |

## Reporting a vulnerability

Trackio is a young project — please report anything suspicious directly and
responsibly:

1. **Do not open a public issue** for anything you believe is exploitable.
2. Email the maintainer via the contact on the
   [GitHub profile](https://github.com/abdou-da0wew) with:
   - a description of the issue and its impact,
   - reproduction steps or a proof of concept,
   - the deep link (e.g. `?shot=home&state=alert`) if it reproduces in-app.
3. You will get an acknowledgement within 7 days and a fix-or-mitigation plan
   within 30 days for accepted reports.

## Scope notes

- The BLE link uses LE Secure Connections with MITM protection and bonding
  over a static 6-digit passkey (`246810`, defined by the firmware). GATT
  characteristics are encrypted, so unpaired clients cannot read telemetry
  or write commands. Reports covering pairing, bonding, characteristic
  permissions, reconnect behavior and Web Bluetooth exposure are welcome.
- The app remains fully self-contained: no production credentials, no real
  user data, mock auth only. Reports about the auth contract, persistence
  handling and web build are welcome — the same code shapes the production
  client.
- The production roadmap (self-hosted Supabase + Tigris on a private VDS)
  will get its own hardening notes (row-level security, OTP rate limits,
  packet signing) as those components land. See
  [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the integration surface.

## Safe-harbour

Good-faith research against your own instances of the app is welcome and will
not be met with legal action. Stay off other people's deployments and data.
