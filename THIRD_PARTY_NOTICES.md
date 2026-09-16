# Third-party notices

Pika Coach combines code and data with different licenses. This file is a
practical inventory, not legal advice.

## chessroad-lite

The Xiangqi position model, rules and notation were adapted from
[`hezhaoyun/chessroad-lite`](https://github.com/hezhaoyun/chessroad-lite),
revision `95be9f07c05e6f93bab861d2886c0c24b1c33138`, licensed under GPL-3.0.

## flutter_pikafish

The iOS FFI bridge was adapted from
[`hezhaoyun/flutter_pikafish`](https://github.com/hezhaoyun/flutter_pikafish),
revision `6bf477725cef5da577d0f85f2ea111b1a8d0a103`, licensed under MIT. Its MIT
notice is preserved in `app/packages/pikafish_engine/LICENSE`.

## Pikafish

The native engine is fetched from
[`official-pikafish/Pikafish`](https://github.com/official-pikafish/Pikafish)
at revision `964f9bf0b90fc539ba00fd8740f329963e2920c6`. Pikafish is GPL-3.0-or-later.
The source is fetched by `scripts/fetch_pikafish_source.sh` and is not copied
into this repository.

## Pikafish NNUE network

The official NNUE weights have a separate license maintained by the Pikafish
project. The binary is deliberately not committed. `scripts/fetch_nnue.sh`
downloads a pinned network and verifies its checksum. Review the current
upstream network license before redistribution or commercial use.

## Reckoning

The evidence-first coach separation and PV replay design were informed by
[`enzohuang98-crypto/Reckoning`](https://github.com/enzohuang98-crypto/Reckoning),
which is licensed under MIT. No Electron UI is included.
