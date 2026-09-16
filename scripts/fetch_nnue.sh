#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TARGET="$REPO_DIR/app/assets/pikafish.nnue"
URL="https://github.com/official-pikafish/Networks/releases/download/master-net/pikafish.nnue"
EXPECTED_SHA256="7d13d73569a9b571ba0eb20cf1596247bc2a42738967e61afef6482b231e900e"

checksum() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

if [[ -f "$TARGET" ]] && [[ "$(checksum "$TARGET")" == "$EXPECTED_SHA256" ]]; then
  echo "NNUE is already installed and verified."
  exit 0
fi

mkdir -p -- "$(dirname -- "$TARGET")"
TEMP_FILE="$(mktemp)"
trap 'rm -f -- "$TEMP_FILE"' EXIT
curl --fail --location --retry 3 --output "$TEMP_FILE" "$URL"

ACTUAL_SHA256="$(checksum "$TEMP_FILE")"
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
  echo "NNUE checksum mismatch: expected $EXPECTED_SHA256, got $ACTUAL_SHA256" >&2
  exit 1
fi

mv -- "$TEMP_FILE" "$TARGET"
trap - EXIT
echo "Installed verified NNUE at $TARGET"
