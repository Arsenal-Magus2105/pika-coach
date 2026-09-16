# pikafish_engine

Private Flutter bridge that runs Pikafish in-process on iOS. It is based on
[`hezhaoyun/flutter_pikafish`](https://github.com/hezhaoyun/flutter_pikafish)
and kept inside this repository so the native engine can be pinned and audited.

Run `scripts/fetch_pikafish_source.sh` from the repository root to populate
`ios/Pikafish/src` before building for iOS.
