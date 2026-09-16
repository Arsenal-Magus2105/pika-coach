#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/fetch_pikafish_source.sh"
"$SCRIPT_DIR/fetch_nnue.sh"

echo "Pika Coach native dependencies are ready."
