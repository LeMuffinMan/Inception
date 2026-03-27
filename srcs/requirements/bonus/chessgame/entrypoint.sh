#!/bin/sh
set -e

DEST="/var/www/html/chessgame"
mkdir -p "$DEST"

URL=$(curl -s https://api.github.com/repos/LeMuffinMan/ChessGame/releases/latest \
      | jq -r '.assets[] | select(.name == "chessgame-wasm.zip") | .browser_download_url')

curl -L "$URL" -o /tmp/chessgame.zip
unzip -o /tmp/chessgame.zip -d /tmp/chessgame_extracted

cp -r /tmp/chessgame_extracted/dist/. "$DEST/"


sed -i \
  -e 's|href="/chess_game-|href="./chess_game-|g' \
  -e 's|from '"'"'/chess_game-|from '"'"'./chess_game-|g' \
  -e 's|module_or_path: '"'"'/chess_game-|module_or_path: '"'"'./chess_game-|g' \
  "$DEST/index.html"

sed -i 's|<script type="module">[^<]*import init from "./pkg/chessgame.js"[^<]*</script>||' "$DEST/index.html"

echo "ChessGame deployed to $DEST"
