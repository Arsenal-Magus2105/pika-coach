# Architecture

Pika Coach is an offline-first Flutter application. Pikafish determines the
chess truth; the app only presents, compares and explains engine evidence.

## Runtime layers

| Layer | Responsibility |
|---|---|
| `lib/cchess` | Xiangqi board state, legal moves, history, FEN and notation |
| `lib/engine` | Native transport, UCI parsing, MultiPV and engine lifecycle |
| `lib/analysis` | Candidate comparison, move grading and safe PV replay |
| `lib/board` | Programmatic mobile board renderer and input mapping |
| `lib/screens` | Coach workflow and user-facing analysis |
| `packages/pikafish_engine` | Flutter FFI bridge to the pinned C++ engine |

## Analysis flow

1. `CoachController` serializes the current position as FEN.
2. `PikafishService` sets `MultiPV`, starts a bounded `go movetime` search and
   publishes progressive UCI `info` lines.
3. `UciInfoParser` preserves centipawn and mate scores as distinct types.
4. The UI shows up to three candidate moves and their principal variations.
5. After a human move, `MoveGrader` compares the played score with the best
   engine score using centipawn-loss buckets.
6. `PvReplay` validates every engine move against the Xiangqi rules and stops
   on the first invalid move instead of fabricating a position.

## Native iOS integration

The local plugin redirects stdin/stdout through pipes and invokes Pikafish in
two Dart isolates. The official engine is compiled with `UNIVERSAL_BINARY`, so
its entry point lives in the `Stockfish` namespace and does not collide with
the iOS runner's global `main` symbol.

The repository does not vendor generated engine source or the NNUE network.
Run `scripts/bootstrap.sh` to fetch both pinned inputs before an iOS build.

## Future coach layer

A future LLM integration must consume structured engine evidence. It may
explain a candidate or comparison, but it must not invent moves, evaluations,
or tactical claims that are absent from a validated PV.
