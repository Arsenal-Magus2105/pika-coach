import 'package:flutter_test/flutter_test.dart';
import 'package:pika_coach/analysis/move_grader.dart';
import 'package:pika_coach/engine/engine_score.dart';

void main() {
  group('MoveGrader', () {
    test('uses centipawn loss buckets', () {
      MoveGrade gradeFor(int played) => MoveGrader.evaluate(
        playedMove: 'h0g2',
        bestMove: 'h2e2',
        bestScore: const CentipawnScore(150),
        playedScore: CentipawnScore(played),
      ).grade;

      expect(gradeFor(145), MoveGrade.best);
      expect(gradeFor(125), MoveGrade.excellent);
      expect(gradeFor(100), MoveGrade.good);
      expect(gradeFor(50), MoveGrade.inaccuracy);
      expect(gradeFor(-50), MoveGrade.mistake);
      expect(gradeFor(-200), MoveGrade.blunder);
    });

    test('never reports negative loss', () {
      final evaluation = MoveGrader.evaluate(
        playedMove: 'h0g2',
        bestMove: 'h2e2',
        bestScore: const CentipawnScore(100),
        playedScore: const CentipawnScore(120),
      );
      expect(evaluation.lossCentipawns, 0);
      expect(evaluation.grade, MoveGrade.best);
    });

    test('a missed forced mate is a blunder', () {
      final evaluation = MoveGrader.evaluate(
        playedMove: 'h0g2',
        bestMove: 'h2e2',
        bestScore: const MateScore(3),
        playedScore: const CentipawnScore(500),
      );
      expect(evaluation.grade, MoveGrade.blunder);
    });
  });
}
