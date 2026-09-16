#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SOURCE_REPO="https://github.com/official-pikafish/Pikafish.git"
SOURCE_COMMIT="964f9bf0b90fc539ba00fd8740f329963e2920c6"
TARGET_DIR="$REPO_DIR/app/packages/pikafish_engine/ios/Pikafish/src"
EXPECTED_DIR="$REPO_DIR/app/packages/pikafish_engine/ios/Pikafish/src"

if [[ "$TARGET_DIR" != "$EXPECTED_DIR" ]]; then
  echo "Refusing to replace an unexpected target: $TARGET_DIR" >&2
  exit 1
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT
git -C "$TEMP_DIR" init --quiet
git -C "$TEMP_DIR" remote add origin "$SOURCE_REPO"
git -C "$TEMP_DIR" fetch --quiet --depth 1 origin "$SOURCE_COMMIT"
git -C "$TEMP_DIR" checkout --quiet --detach FETCH_HEAD

ACTUAL_COMMIT="$(git -C "$TEMP_DIR" rev-parse HEAD)"
if [[ "$ACTUAL_COMMIT" != "$SOURCE_COMMIT" ]]; then
  echo "Pikafish revision mismatch: expected $SOURCE_COMMIT, got $ACTUAL_COMMIT" >&2
  exit 1
fi

rm -rf -- "$TARGET_DIR"
mkdir -p -- "$(dirname -- "$TARGET_DIR")"
cp -R -- "$TEMP_DIR/src" "$TARGET_DIR"
echo "Installed Pikafish source at revision $SOURCE_COMMIT"
