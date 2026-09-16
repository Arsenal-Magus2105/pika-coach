import '../cchess/cc_base.dart';
import '../cchess/position.dart';
import 'vietnamese_notation.dart';

class PvFrame {
  const PvFrame({
    required this.ply,
    required this.move,
    required this.notation,
    required this.fenBefore,
    required this.fenAfter,
  });

  final int ply;
  final String move;
  final String notation;
  final String fenBefore;
  final String fenAfter;
}

class PvReplayResult {
  const PvReplayResult({required this.frames, this.rejectedMove});
  final List<PvFrame> frames;
  final String? rejectedMove;
  bool get isComplete => rejectedMove == null;
}

class PvReplay {
  const PvReplay._();

  static PvReplayResult replay(Position initial, Iterable<String> pv) {
    final position = Position.clone(initial);
    final frames = <PvFrame>[];
    var ply = 0;
    for (final rawMove in pv) {
      ply++;
      if (!Move.isOK(rawMove)) {
        return PvReplayResult(
          frames: List.unmodifiable(frames),
          rejectedMove: rawMove,
        );
      }
      final move = Move.fromEngineMove(rawMove);
      final before = position.fen;
      final notation = VietnameseNotation.translate(position, move);
      if (!position.move(move)) {
        return PvReplayResult(
          frames: List.unmodifiable(frames),
          rejectedMove: rawMove,
        );
      }
      frames.add(
        PvFrame(
          ply: ply,
          move: rawMove,
          notation: notation,
          fenBefore: before,
          fenAfter: position.fen,
        ),
      );
    }
    return PvReplayResult(frames: List.unmodifiable(frames));
  }
}
