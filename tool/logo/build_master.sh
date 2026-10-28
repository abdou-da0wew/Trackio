#!/bin/bash
# Trackio master icon builder (ImageMagick, no SVG rasterizer available)
set -e
S=${1:-1024}; OUT=${2:-master.png}; BG=${3:-yes}; SCALE=${4:-1.0}; MONO=${5:-no}
N=$S
T=$(python3 -c "print($S/1024*$SCALE)")
ox=$(python3 -c "print($S*(1-$SCALE)/2)"); oy=$ox
X(){ python3 -c "print(round($ox+$1*$T))"; }
Y(){ python3 -c "print(round($oy+$1*$T))"; }
R(){ python3 -c "print(round($1*$T))"; }

if [ "$BG" = yes ]; then
  convert -size ${N}x${N} radial-gradient:'#0B2C82'-'#001233' base.png
  convert -size ${N}x${N} xc:transparent -fill 'rgba(15,133,250,0.30)' \
    -draw "circle $(X 512),$(Y 470) $(X 512),$(Y 700)" -blur 0x$(R 70) glow.png
  convert base.png glow.png -compose over -composite base.png
else
  convert -size ${N}x${N} xc:transparent base.png
fi

CX=$(X 512); CY=$(Y 468)
if [ "$MONO" = yes ]; then R1=white; R2=white; R3=white; else R1='rgba(90,170,255,0.95)'; R2='rgba(90,170,255,0.60)'; R3='rgba(90,170,255,0.34)'; fi
convert -size ${N}x${N} xc:transparent \
  -stroke "$R3" -strokewidth $(R 5)  -fill none -draw "circle $CX,$CY $(X 900),$CY" \
  -stroke "$R2" -strokewidth $(R 6)  -draw "circle $CX,$CY $(X 792),$CY" \
  -stroke "$R1" -strokewidth $(R 7)  -draw "circle $CX,$CY $(X 682),$CY" rings.png
CH="$([ "$MONO" = yes ] && echo white || echo 'rgba(150,200,255,0.22)')"
convert rings.png -stroke "$CH" -strokewidth $(R 4) \
  -draw "line $CX,$(Y 60) $CX,$(Y 876)" -draw "line $(X 100),$CY $(X 924),$CY" rings.png

if [ "$MONO" = no ]; then
  convert -size ${N}x${N} xc:transparent -fill 'rgba(40,150,255,0.55)' \
    -draw "path 'M $CX,$CY L $(X 512),$(Y 80) A $(R 388),$(R 388) 0 0,1 $(X 887),$(Y 568) Z'" wedge_solid.png
  convert -size ${N}x${N} radial-gradient:'rgba(60,160,255,0.85)'-'rgba(60,160,255,0)' grad.png
  convert wedge_solid.png -alpha extract wmask.png
  convert grad.png wmask.png -alpha off -compose CopyOpacity -composite -blur 0x$(R 14) wedge.png
else
  convert -size ${N}x${N} xc:transparent wedge.png
fi

BX=$(X 336); BY=$(Y 500); BW=$(R 352); BH=$(R 288); BR=$(R 80)
convert -size ${N}x${N} xc:transparent -fill 'rgba(0,8,28,0.45)' \
  -draw "roundrectangle $BX,$(Y 522) $((BX+BW)),$((BY+BH+18)) $BR,$BR" -blur 0x$(R 22) bagshadow.png
if [ "$MONO" = yes ]; then
  convert -size ${N}x${N} xc:transparent -fill white \
    -draw "roundrectangle $BX,$BY $((BX+BW-1)),$((BY+BH-1)) $BR,$BR" body.png
else
  convert -size ${BW}x${BH} gradient:'#F5FAFF'-'#A9C8FB' bodygrad.png
  convert -size ${BW}x${BH} xc:none -fill black -draw "roundrectangle 0,0 $((BW-1)),$((BH-1)) $BR,$BR" -alpha extract bodymask.png
  convert bodygrad.png bodymask.png -alpha off -compose CopyOpacity -composite body.png
  convert -size ${N}x${N} xc:none body.png -geometry +${BX}+${BY} -composite body_layer.png && mv body_layer.png body.png
fi
convert -size ${N}x${N} xc:transparent \
  -stroke "$([ "$MONO" = yes ] && echo white || echo '#DCEAFF')" -strokewidth $(R 44) -fill none \
  -draw "stroke-linecap Round path 'M $(X 418),$(Y 516) C $(X 418),$(Y 404) $(X 606),$(Y 404) $(X 606),$(Y 516)'" handle.png

MX=$(X 512); MY=$(Y 646)
if [ "$MONO" = no ]; then
  convert -size ${N}x${N} xc:transparent -fill none \
    -stroke 'rgba(15,133,250,0.45)' -strokewidth $(R 7)  -draw "circle $MX,$MY $(X 578),$MY" \
    -stroke '#0F85FA'                 -strokewidth $(R 10) -draw "circle $MX,$MY $(X 554),$MY" \
    -fill '#0F85FA' -draw "circle $MX,$MY $(X 532),$MY" \
    -fill white -draw "circle $MX,$MY $(X 520),$MY" motif.png
else
  convert -size ${N}x${N} xc:transparent motif.png
fi

convert base.png glow.png -compose over -composite \
  rings.png -compose over -composite \
  wedge.png -compose over -composite \
  bagshadow.png -compose over -composite \
  handle.png -compose over -composite \
  \( body.png \) -compose over -composite \
  motif.png -compose over -composite "$OUT"
identify "$OUT"
