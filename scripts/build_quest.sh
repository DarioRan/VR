#!/usr/bin/env bash
# Build the Quest APK and optionally install it (ticket A-09). Owner: A.
#
# Usage:
#   scripts/build_quest.sh                 # debug APK
#   scripts/build_quest.sh debug --install # debug APK, install and launch on the Quest
#   scripts/build_quest.sh release         # release APK (needs the release keystore, see below)
#
# Godot binary: set GODOT, for example
#   export GODOT=/Applications/Godot.app/Contents/MacOS/Godot
#
# Release signing: Godot reads these environment variables
#   GODOT_ANDROID_KEYSTORE_RELEASE_PATH, GODOT_ANDROID_KEYSTORE_RELEASE_USER,
#   GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
#
# Final build (M4):  scripts/build_quest.sh release  then  git tag v1.0 && git push origin v1.0
set -euo pipefail

MODE="${1:-debug}"
INSTALL="${2:-}"
GODOT="${GODOT:-godot}"
PRESET="MetaHeadset"
PACKAGE="fr.ubx.impossiblespaces"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/impossible-spaces"
OUT="$ROOT/exports"
mkdir -p "$OUT"

case "$MODE" in
  debug)   FLAG="--export-debug" ;;
  release)
    FLAG="--export-release"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Set the release keystore variables (see the top of this script)}"
    ;;
  *) echo "Usage: $0 [debug|release] [--install]" >&2; exit 1 ;;
esac

if ! command -v "$GODOT" >/dev/null 2>&1 && [[ ! -x "$GODOT" ]]; then
  echo "Godot not found. Set GODOT to the Godot 4.7.2 binary." >&2
  exit 1
fi

VERSION="$(git -C "$ROOT" describe --tags --always --dirty 2>/dev/null || echo dev)"
APK="$OUT/impossible-spaces-$MODE-$VERSION.apk"

echo "Exporting $MODE build to $APK"
"$GODOT" --headless --path "$PROJECT" "$FLAG" "$PRESET" "$APK"
echo "Built $APK"

if [[ "$INSTALL" == "--install" ]]; then
  adb install -r "$APK"
  adb shell am start -n "$PACKAGE/com.godot.game.GodotApp"
fi
