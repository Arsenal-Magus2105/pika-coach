import '../engine/engine_score.dart';

enum MoveGrade {
  best('Tốt nhất'),
  excellent('Xuất sắc'),
  good('Tốt'),
  inaccuracy('Sai nhẹ'),
  mistake('Sai lầm'),
  blunder('Đại sai lầm');

  const MoveGrade(this.label);
  final String label;
}

class MoveEvaluation {
  const MoveEvaluation({
    required this.playedMove,
    required this.bestMove,
    required this.bestScore,
    required this.playedScore,
    required this.grade,
    this.lossCentipawns,
  });

  final String playedMove;
  final String bestMove;
  final EngineScore bestScore;
  final EngineScore playedScore;
  final MoveGrade grade;
  final int? lossCentipawns;
}

class MoveGrader {
  const MoveGrader._();

  static MoveEvaluation evaluate({
    required String playedMove,
    required String bestMove,
    required EngineScore bestScore,
    required EngineScore playedScore,
  }) {
    final cpLoss = _centipawnLoss(bestScore, playedScore);
    return MoveEvaluation(
      playedMove: playedMove,
      bestMove: bestMove,
      bestScore: bestScore,
      playedScore: playedScore,
      lossCentipawns: cpLoss,
      grade: _grade(bestScore, playedScore, cpLoss),
    );
  }

  static int? _centipawnLoss(EngineScore best, EngineScore played) {
    if (best is! CentipawnScore || played is! CentipawnScore) return null;
    final loss = best.centipawns - played.centipawns;
    return loss < 0 ? 0 : loss;
  }

  static MoveGrade _grade(EngineScore best, EngineScore played, int? cpLoss) {
    if (cpLoss != null) {
      if (cpLoss <= 10) return MoveGrade.best;
      if (cpLoss <= 30) return MoveGrade.excellent;
      if (cpLoss <= 60) return MoveGrade.good;
      if (cpLoss <= 120) return MoveGrade.inaccuracy;
      if (cpLoss <= 250) return MoveGrade.mistake;
      return MoveGrade.blunder;
    }
    if (best is MateScore && played is MateScore) {
      if (best.mateIn > 0 && played.mateIn <= 0) return MoveGrade.blunder;
      if (best.mateIn < 0 && played.mateIn > 0) return MoveGrade.best;
      if (best.mateIn > 0 && played.mateIn > 0) {
        final delay = played.mateIn - best.mateIn;
        if (delay <= 0) return MoveGrade.best;
        if (delay <= 2) return MoveGrade.excellent;
        if (delay <= 5) return MoveGrade.good;
        return MoveGrade.inaccuracy;
      }
      final lostDistance = best.mateIn.abs() - played.mateIn.abs();
      if (lostDistance <= 0) return MoveGrade.best;
      if (lostDistance <= 2) return MoveGrade.good;
      return MoveGrade.mistake;
    }
    if (best is MateScore && best.mateIn > 0) return MoveGrade.blunder;
    if (played is MateScore && played.mateIn < 0) return MoveGrade.blunder;
    if (played is MateScore && played.mateIn > 0) return MoveGrade.best;
    return MoveGrade.mistake;
  }
}
