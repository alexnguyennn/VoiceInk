#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_SRC="$PROJECT_DIR/.local-build/Build/Products/Debug/VoiceInk.app"
APP_DEST="/Applications/VoiceInk.app"

if [ ! -d "$APP_SRC" ]; then
  echo "ERROR: Local build not found at $APP_SRC." >&2
  echo "Run 'make local' first, then rerun ./move.sh." >&2
  exit 1
fi

echo "==> Installing $APP_SRC to $APP_DEST..."
rm -rf "$APP_DEST"
ditto "$APP_SRC" "$APP_DEST"
xattr -cr "$APP_DEST"
echo "==> Done. Launch: open $APP_DEST"
