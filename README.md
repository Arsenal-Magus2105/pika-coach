# Pika Coach

Pika Coach is an offline-first Xiangqi training app for iPhone. Pikafish is the
chess authority; the app turns its MultiPV output into hints, candidate
comparisons, move grading, and replayable principal variations.

> Current milestone: source MVP. The board, legal move validation, local
> Pikafish transport, MultiPV parser, move grader, PV replay, Vietnamese UI,
> and automated tests are present. GitHub Actions builds an unsigned iPhone IPA;
> physical-device installation and engine runtime still need testing.

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

## Try it from Windows 11 without a Mac

The GitHub Actions macOS runner compiles iOS code and uploads an **unsigned**
`PikaCoach-unsigned.ipa` for personal device testing. An unsigned IPA cannot be
installed directly: a sideloading tool must sign it with your own Apple ID.

1. On GitHub, open **Actions → Flutter checks → latest successful run →
   Artifacts → PikaCoach-unsigned-iPhone**. Unzip the downloaded artifact to get
   `PikaCoach-unsigned.ipa`. Artifacts expire after 7 days; rerun the workflow
   from Actions when a fresh build is needed.
2. On Windows, [set up AltStore Classic and AltServer](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows.md)
   with a cable, iTunes and iCloud from Apple's direct downloads. Unlock and
   trust the connected iPhone, then enable Developer Mode in iOS settings.
3. Transfer the IPA to the iPhone's Files app (for example through iCloud
   Drive). In AltStore Classic, open **My Apps → +** and select the IPA to sign
   and install it. Keep AltServer reachable for installation and refreshes.
4. Open Pika Coach and verify that the board loads and an **Analyze** request
   returns Pikafish lines. Report any crash or blank analysis with a screenshot.

A free Apple ID can be used for testing. AltStore's free-account installs
expire after 7 days and count toward its 3 sideloaded-app limit; it can refresh
apps while AltServer is available. Sign in only inside the official AltStore
setup on your own devices; do not add Apple credentials to GitHub Actions.
The CI build and exported IPA check packaging and native symbols, but do not
prove that Pikafish runs on a physical iPhone until step 4 succeeds.

## Prepare the project

Requirements for building locally on macOS:

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
