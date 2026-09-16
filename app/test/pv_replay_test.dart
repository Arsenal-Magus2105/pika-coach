import 'package:flutter_test/flutter_test.dart';
import 'package:pika_coach/analysis/pv_replay.dart';
import 'package:pika_coach/cchess/position.dart';

void main() {
  group('PvReplay', () {
    test('replays a legal principal variation', () {
      final result = PvReplay.replay(
        Position.startpos,
        const ['h2e2', 'h9g7', 'h0g2'],
      );

      expect(result.isComplete, isTrue);
      expect(result.frames, hasLength(3));
      expect(result.frames.first.notation, 'Pháo 2 bình 5');
      expect(result.frames.last.fenAfter, isNot(result.frames.first.fenBefore));
    });

    test('stops safely at an illegal engine move', () {
      final result = PvReplay.replay(Position.startpos, const ['h2h9']);
      expect(result.isComplete, isFalse);
      expect(result.rejectedMove, 'h2h9');
      expect(result.frames, isEmpty);
    });
  });
}
