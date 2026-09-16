#!/bin/bash
# Usage: ./preview.sh <proposal-dir> <out.png>: run a 2nd waybar instance at the BOTTOM
# edge (non-exclusive, laptop screen only) so the real bar stays untouched,
# screenshot that strip, kill the instance.
set -u
P="$1"; OUT="$2"; S=$(dirname "$OUT")
sed -e 's/"position": *"top"/"position": "bottom"/' \
    -e 's/"exclusive": *true/"exclusive": false/' \
    -e 's/"margin-top"/"margin-bottom"/' \
    -e 's/"output":\[.*\]/"output":["eDP-1"]/' \
    "$P/config" > "$S/preview-config"
waybar -c "$S/preview-config" -s "$P/style.css" -l warning > "$S/preview.log" 2>&1 &
PID=$!
sleep 3
H=$(grep -o '"height": *[0-9]*' "$P/config" | grep -o '[0-9]*$')
grim -o eDP-1 "$S/preview-full.png"
kill $PID 2>/dev/null; wait $PID 2>/dev/null
python3 - "$S/preview-full.png" "$OUT" "$H" <<'PY'
import sys
from PIL import Image
src, out, h = sys.argv[1], sys.argv[2], int(sys.argv[3])
im = Image.open(src); W, Hh = im.size
strip = im.crop((0, Hh - h - 10, W, Hh))
strip.save(out)
# zoomed thirds for reading detail
for name, box in {"l": (0, 0, 560, strip.size[1]), "c": (680, 0, 1240, strip.size[1]), "r": (1360, 0, W, strip.size[1])}.items():
    c = strip.crop(box); c = c.resize((c.size[0]*2, c.size[1]*2), Image.LANCZOS); c.save(out.replace(".png", f"-{name}.png"))
PY
grep -v '^$' "$S/preview.log" | head -20
