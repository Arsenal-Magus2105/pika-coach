#!/usr/bin/env bash
set -euo pipefail

# Single-threaded Pikafish WebAssembly build and its matching embedded network.
# Pinned to one upstream source commit; verify Git blob IDs before using assets.
revision=bf2677c11901b716f48fbd1bbed62d31694ac7af
source_base="https://raw.githubusercontent.com/iFwu/xiangqi-analysis/$revision"
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$root/vendor"

fetch() {
  local source_path=$1 destination=$2 expected=$3 actual
  curl --fail --location --retry 3 --silent --show-error \
    "$source_base/$source_path" -o "$root/vendor/$destination.tmp"
  actual="$(git hash-object "$root/vendor/$destination.tmp")"
  if [[ "$actual" != "$expected" ]]; then
    rm -f "$root/vendor/$destination.tmp"
    echo "Unexpected hash for $source_path" >&2
    exit 1
  fi
  mv "$root/vendor/$destination.tmp" "$root/vendor/$destination"
}

fetch third_party/pikafish.js pikafish.js 5341f28630c1a0f88a934d40c5f40ad1e155f677
fetch public/wasm/pikafish.wasm pikafish.wasm 876d18b24329a39aeb735880b36eda567b4dc3df
fetch public/wasm/data/pikafish.data pikafish.data 3126d13460c42e4bcfcf97b4b6e4b932d21d0c40
echo 'Pikafish WebAssembly assets verified.'
