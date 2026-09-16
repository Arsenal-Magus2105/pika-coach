import 'package:flutter_test/flutter_test.dart';
import 'package:pika_coach/engine/engine_line.dart';
import 'package:pika_coach/engine/engine_score.dart';
import 'package:pika_coach/engine/uci_parser.dart';

void main() {
  group('UciInfoParser', () {
    test('parses a centipawn MultiPV line', () {
      final line = UciInfoParser.parseInfo(
        'info depth 24 seldepth 31 multipv 2 score cp -42 nodes 12345 '
        'nps 456789 hashfull 38 time 27 pv h2e2 h9g7',
      );

      expect(line, isNotNull);
      expect(line!.multiPv, 2);
      expect(line.depth, 24);
      expect(line.selDepth, 31);
      expect(line.score, const CentipawnScore(-42));
      expect(line.pv, ['h2e2', 'h9g7']);
      expect(line.nodes, 12345);
      expect(line.nps, 456789);
    });

    test('keeps mate and score bound semantics', () {
      final line = UciInfoParser.parseInfo(
        'info depth 30 score mate 3 lowerbound pv h2e2',
      );

      expect(line!.score, const MateScore(3));
      expect(line.bound, ScoreBound.lower);
      expect(line.score.display, 'Chiếu hết sau 3');
    });

    test('parses bestmove and ponder', () {
      final best = UciInfoParser.parseBestMove('bestmove h2e2 ponder h9g7');
      expect(best?.bestMove, 'h2e2');
      expect(best?.ponder, 'h9g7');
    });

    test('ignores unrelated output', () {
      expect(UciInfoParser.parseInfo('id name Pikafish'), isNull);
      expect(UciInfoParser.parseBestMove('readyok'), isNull);
    });
  });
}
