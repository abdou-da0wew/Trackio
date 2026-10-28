#!/bin/bash
set -e
R=$(cd "$(dirname "$0")/../.." && pwd)
resize(){ # src size out [opaque]
  if [ "$4" = opaque ]; then
    convert "$1" -resize "$2x$2" -alpha remove -alpha off -strip "$3"
  else
    convert "$1" -resize "$2x$2" -strip "$3"
  fi
}
# ---- web ----
resize master_full.png     192 "$R/web/icons/Icon-192.png" opaque
resize master_full.png     512 "$R/web/icons/Icon-512.png" opaque
resize master_maskable.png 192 "$R/web/icons/Icon-maskable-192.png" opaque
resize master_maskable.png 512 "$R/web/icons/Icon-maskable-512.png" opaque
resize master_full.png     192 "$R/web/favicon.png" opaque
# ---- android: legacy / foreground / monochrome per density ----
declare -A DENS=( [mdpi]=48 [hdpi]=72 [xhdpi]=96 [xxhdpi]=144 [xxxhdpi]=192 )
declare -A FG=( [mdpi]=108 [hdpi]=162 [xhdpi]=216 [xxhdpi]=324 [xxxhdpi]=432 )
declare -A MONO=( [mdpi]=64 [hdpi]=97 [xhdpi]=129 [xxhdpi]=194 [xxxhdpi]=259 )
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  DIR="$R/android/app/src/main/res/mipmap-$d"
  resize master_full.png "${DENS[$d]}" "$DIR/ic_launcher.png" opaque
  resize master_fg.png   "${FG[$d]}"   "$DIR/ic_launcher_foreground.png"
  resize master_mono.png "${MONO[$d]}" "$DIR/ic_launcher_monochrome.png"
done
# ---- ios: every catalog entry (opaque, no alpha) ----
# globs use the pixel size embedded in each filename (point size x scale),
# except the 83.5pt entry whose name keeps the point size.
for sz in 1024 20 40 60 29 58 87 80 120 180 76 152; do
  for f in "$R"/ios/Runner/Assets.xcassets/AppIcon.appiconset/*"${sz}x${sz}"*.png; do
    [ -e "$f" ] && resize master_full.png "$sz" "$f" opaque
  done
done
resize master_full.png 167 "$R/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png" opaque
resize master_full.png 1024 "$R/ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon.png" opaque
# ---- in-app brand assets ----
mkdir -p "$R/assets/brand"
cp master_full.png        "$R/assets/brand/trackio_icon.png"
cp mark_transparent.png   "$R/assets/brand/trackio_mark.png"
cp master_mono.png        "$R/assets/brand/trackio_mark_mono.png"
echo OK
