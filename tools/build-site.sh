#!/bin/bash
set -euo pipefail
GAME=$(cd "$(dirname "$0")/.." && pwd)
SRC=${1:?usage: bash tools/build-site.sh /path/to/your-lovable-repo}
SRC=$(cd "$SRC" && pwd)
[ -f "$SRC/package.json" ] || { echo "No package.json in $SRC" >&2; exit 1; }

cd "$SRC"
cat > vite.phonegame.config.ts <<'CFG'
import { defineConfig } from "@lovable.dev/vite-tanstack-config";
export default defineConfig({
  tanstackStart: { server: { entry: "server" }, spa: { enabled: true } },
  nitro: false,
});
CFG
trap 'rm -f "$SRC/vite.phonegame.config.ts"' EXIT

if command -v bun >/dev/null; then bun install; else npm install --no-audit --no-fund; fi
rm -rf dist
npx vite build --config vite.phonegame.config.ts
[ -f dist/client/_shell.html ] || { echo "Build did not produce dist/client/_shell.html" >&2; exit 1; }

find "$GAME/site" -mindepth 1 ! -name README.md -delete
cp -r dist/client/. "$GAME/site/"
cp "$GAME/site/_shell.html" "$GAME/site/index.html"

for meta in "$SRC"/src/assets/*.asset.json; do
  [ -e "$meta" ] || continue
  url=$(sed -n 's/.*"url": *"\([^"]*\)".*/\1/p' "$meta")
  name=$(sed -n 's/.*"original_filename": *"\([^"]*\)".*/\1/p' "$meta")
  case "$url" in /__l5e/*) ;; *) continue ;; esac
  if [ -f "$GAME/site-assets/$name" ]; then
    install -D -m 644 "$GAME/site-assets/$name" "$GAME/site$url"
  else
    echo "Warning: $name is only on Lovable's server. Download it and put it into site-assets/, then build again." >&2
  fi
done
echo "Website built into $GAME/site ($(find "$GAME/site" -type f | wc -l) files). Now run: sudo bash install.sh"
