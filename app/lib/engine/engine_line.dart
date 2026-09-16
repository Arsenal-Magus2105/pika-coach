import 'engine_score.dart';

enum ScoreBound { exact, lower, upper }

class EngineLine {
  const EngineLine({
    required this.multiPv,
    required this.depth,
    required this.selDepth,
    required this.score,
    required this.pv,
    this.bound = ScoreBound.exact,
    this.nodes = 0,
    this.nps = 0,
    this.hashFull = 0,
    this.timeMs = 0,
  });

  final int multiPv;
  final int depth;
  final int selDepth;
  final EngineScore score;
  final ScoreBound bound;
  final int nodes;
  final int nps;
  final int hashFull;
  final int timeMs;
  final List<String> pv;

  String? get firstMove => pv.isEmpty ? null : pv.first;
  bool isNewerThan(EngineLine other) =>
      depth > other.depth || (depth == other.depth && timeMs >= other.timeMs);
}

class EngineAnalysis {
  EngineAnalysis({
    required List<EngineLine> lines,
    required this.bestMove,
    this.ponder,
  }) : lines = List.unmodifiable(lines);

  final List<EngineLine> lines;
  final String bestMove;
  final String? ponder;
  EngineLine? get bestLine => lines.isEmpty ? null : lines.first;
}
