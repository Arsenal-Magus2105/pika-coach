import 'engine_line.dart';
import 'engine_score.dart';

class UciInfoParser {
  const UciInfoParser._();

  static EngineLine? parseInfo(String rawLine) {
    final line = rawLine.trim();
    if (!line.startsWith('info ')) return null;
    final tokens = line.split(RegExp(r'\s+'));
    final scoreIndex = tokens.indexOf('score');
    if (scoreIndex < 0 || scoreIndex + 2 >= tokens.length) return null;
    final rawScore = int.tryParse(tokens[scoreIndex + 2]);
    if (rawScore == null) return null;

    final EngineScore? score = switch (tokens[scoreIndex + 1]) {
      'cp' => CentipawnScore(rawScore),
      'mate' => MateScore(rawScore),
      _ => null,
    };
    if (score == null) return null;

    var bound = ScoreBound.exact;
    if (scoreIndex + 3 < tokens.length) {
      bound = switch (tokens[scoreIndex + 3]) {
        'lowerbound' => ScoreBound.lower,
        'upperbound' => ScoreBound.upper,
        _ => ScoreBound.exact,
      };
    }
    final pvIndex = tokens.indexOf('pv');
    final pv = pvIndex < 0 || pvIndex + 1 >= tokens.length
        ? <String>[]
        : tokens.sublist(pvIndex + 1);
    return EngineLine(
      multiPv: _intAfter(tokens, 'multipv') ?? 1,
      depth: _intAfter(tokens, 'depth') ?? 0,
      selDepth: _intAfter(tokens, 'seldepth') ?? 0,
      score: score,
      bound: bound,
      nodes: _intAfter(tokens, 'nodes') ?? 0,
      nps: _intAfter(tokens, 'nps') ?? 0,
      hashFull: _intAfter(tokens, 'hashfull') ?? 0,
      timeMs: _intAfter(tokens, 'time') ?? 0,
      pv: List.unmodifiable(pv),
    );
  }

  static ({String bestMove, String? ponder})? parseBestMove(String rawLine) {
    final match = RegExp(r'^bestmove\s+(\S+)(?:\s+ponder\s+(\S+))?')
        .firstMatch(rawLine.trim());
    if (match == null) return null;
    return (bestMove: match.group(1)!, ponder: match.group(2));
  }

  static int? _intAfter(List<String> tokens, String key) {
    final index = tokens.indexOf(key);
    if (index < 0 || index + 1 >= tokens.length) return null;
    return int.tryParse(tokens[index + 1]);
  }
}
