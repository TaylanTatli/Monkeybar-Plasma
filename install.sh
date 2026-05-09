#!/bin/bash

ID=$(jq -r '.KPlugin.Id' metadata.json)

echo "--- Installing MonkeyBar Plasmoid ---"

if [ -d "translate" ]; then
  echo "[1/3] Compiling translations..."
  cd translate && sh ./build.sh && cd ..
fi

echo "[2/3] Checking for old version..."
kpackagetool6 --type Plasma/Applet --remove "$ID" 2>/dev/null

echo "[3/3] Installing Plasmoid..."
kpackagetool6 --type Plasma/Applet --install .

echo "----------------------------------"
echo "Installation complete! You may need to restart"
echo "plasmashell for changes to take effect:"
echo "kquitapp6 plasmashell && kstart6 plasmashell"
