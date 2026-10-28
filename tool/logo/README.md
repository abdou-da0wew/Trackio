# Trackio logo pipeline

The brand mark is a **radar sweep locking onto a bag** — concentric range
rings and a sweep wedge behind a rounded bag whose face carries a tracking
target. It mirrors the product: BLE RSSI distance, radar bearing and
lost-bag alerts over a live ESP32 link.

## Sources of truth

- `../../assets/brand/trackio_mark.svg` — transparent brand mark (vector)
- `../../assets/brand/trackio_icon.svg` — full-bleed app-icon variant (vector)

The sandbox that produced the shipped PNGs had no SVG rasterizer, so the
PNG pipeline is built from ImageMagick primitives that match the SVG
geometry exactly (shared 1024×1024 design space):

- `build_master.sh` renders one master PNG.
  Usage: `./build_master.sh <size> <out.png> <bg yes|no> <scale> <mono yes|no>`
- `emit_icons.sh` renders every platform size from the four masters:
  - full-bleed icon — web PWA, iOS catalog, Android legacy `ic_launcher`
  - 0.80-scaled maskable — `web/icons/Icon-maskable-*.png`
  - 0.86-scaled transparent foreground — Android adaptive icon
  - white monochrome — Android themed-icon `ic_launcher_monochrome`

Requirements: ImageMagick 6 (`convert`) and Python 3. Run from this
directory; outputs land directly in `web/`, `android/`, `ios/` and
`assets/brand/`. In-app copies are downscaled to 512 px to keep the bundle
lean; platform icons are emitted at their exact required dimensions.

## Colours

Navy field `#001233 → #0B2C82`, accent blue `#0F85FA`, rings `#5AAAFF`,
bag gradient `#F5FAFF → #A9C8FB` — all drawn from `lib/core/palette.dart`
tokens, so the icon matches the in-app design system.
