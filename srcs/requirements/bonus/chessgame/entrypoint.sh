#!/bin/sh
set -e

DEST="/var/www/html/chessgame"
mkdir -p "$DEST"

URL=$(curl -s https://api.github.com/repos/LeMuffinMan/ChessGame/releases/latest \
      | jq -r '.assets[] | select(.name == "chessgame-wasm.zip") | .browser_download_url')

curl -L "$URL" -o /tmp/chessgame.zip
unzip -o /tmp/chessgame.zip -d /tmp/chessgame_extracted

# trunk génère un sous-dossier dist/
cp -r /tmp/chessgame_extracted/dist/. "$DEST/"

echo "ChessGame deployed to $DEST"
