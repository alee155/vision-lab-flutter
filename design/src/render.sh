#!/bin/bash
cd "$(dirname "$0")"
python3 build.py || exit 1
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
for f in 01-detectors 02-face-live 03-face-json 04-options 05-face-dark; do
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=2 --window-size=390,844 \
    --screenshot="../$f.png" "file://$PWD/$f.html" >/dev/null 2>&1
done
echo "rendered"
