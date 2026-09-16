sealed class EngineScore implements Comparable<EngineScore> {
  const EngineScore();

  EngineScore flipped();
  int get orderingValue;
  String get display;

  @override
  int compareTo(EngineScore other) =>
      orderingValue.compareTo(other.orderingValue);
}

final class CentipawnScore extends EngineScore {
  const CentipawnScore(this.centipawns);

  final int centipawns;
  double get pawns => centipawns / 100;

  @override
  CentipawnScore flipped() => CentipawnScore(-centipawns);
  @override
  int get orderingValue => centipawns;
  @override
  String get display {
    final prefix = centipawns > 0 ? '+' : '';
    return '$prefix${pawns.toStringAsFixed(2)}';
  }

  @override
  bool operator ==(Object other) =>
      other is CentipawnScore && other.centipawns == centipawns;
  @override
  int get hashCode => centipawns.hashCode;
}

final class MateScore extends EngineScore {
  const MateScore(this.mateIn);

  final int mateIn;

  @override
  MateScore flipped() => MateScore(-mateIn);
  @override
  int get orderingValue {
    final distance = mateIn.abs().clamp(0, 999);
    return mateIn >= 0 ? 1000000 - distance : -1000000 + distance;
  }

  @override
  String get display => mateIn >= 0
      ? 'Chiếu hết sau ${mateIn.abs()}'
      : 'Bị chiếu hết sau ${mateIn.abs()}';

  @override
  bool operator ==(Object other) =>
      other is MateScore && other.mateIn == mateIn;
  @override
  int get hashCode => mateIn.hashCode;
}
