# Pika Coach

Pika Coach is an offline-first Xiangqi training app for iPhone. Pikafish is the
chess authority; the app turns its MultiPV output into hints, candidate
comparisons, move grading, and replayable principal variations.

> Current milestone: source MVP. The board, legal move validation, local
> Pikafish transport, MultiPV parser, move grader, PV replay, Vietnamese UI,
> and automated tests are present. An Xcode build is still required before an
> `.ipa` can be installed on a device.

## What works in the MVP

- Full Xiangqi board and move validation inherited from `chessroad-lite`.
- Local Pikafish process embedded through an iOS Flutter FFI plugin.
- MultiPV 1–5 with centipawn and forced-mate scores kept as different types.
- Best-move arrow, candidate list, depth, score, and principal-variation view.
- Automatic comparison between the played move and Pikafish's best move.
- Safe PV replay: invalid engine moves stop replay instead of corrupting state.
- Board-only fallback if the native engine or NNUE file is unavailable.

The LLM explanation layer is deliberately not part of this milestone. Engine
evidence is being made stable first; a coach model can later explain that
evidence without inventing moves.

## Prepare the project

Requirements:

- Flutter stable with Dart 3.3 or newer
- macOS with current Xcode for the iOS build
- CocoaPods

Bootstrap the pinned official Pikafish source and current network (about
50 MB):

```bash
./scripts/bootstrap.sh
```

The scripts verify the exact source commit and the SHA-256 published for the
6 September 2026 master network. Both generated paths are intentionally
ignored by Git. The network license is separate from GPLv3 and limits use to
legal, non-commercial use unless permission is obtained from the Pikafish
team.

Then run:

```bash
cd app
flutter pub get
flutter test
flutter run -d <your-iphone>
```

The provisional iOS bundle identifier is
`com.arsenalmagus.pikacoach`. Change it in Xcode before signing if needed.

## Repository layout

```text
app/
├── lib/
│   ├── analysis/       move grading, PV replay, coach state
│   ├── board/          programmatic Xiangqi board
│   ├── cchess/         rules, FEN, moves, notation
│   ├── engine/         typed UCI/MultiPV and Pikafish service
│   └── screens/        Vietnamese coach UI
├── packages/
│   └── pikafish_engine/  iOS FFI bridge; pinned source is bootstrapped
└── test/
scripts/
├── bootstrap.sh
├── fetch_nnue.sh
└── fetch_pikafish_source.sh
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the evidence boundary and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for provenance.

## License and fair use

This repository is GPLv3 because both `chessroad-lite` and Pikafish are GPLv3.
See [LICENSE](LICENSE). The NNUE network is not covered by that license; read
the official [Pikafish Networks license](https://github.com/official-pikafish/Networks#nnue-license)
before downloading or distributing it.

Pika Coach is intended for study, offline analysis, and play in environments
that explicitly permit engines. Do not use it to obtain engine assistance in
a live human game where assistance is prohibited.
