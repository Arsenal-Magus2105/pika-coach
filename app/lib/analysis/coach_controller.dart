import 'dart:async';

import 'package:flutter/foundation.dart';

import '../cchess/cc_base.dart';
import '../cchess/cc_fen.dart';
import '../cchess/position.dart';
import '../engine/engine_line.dart';
import '../engine/nnue_installer.dart';
import '../engine/pikafish_service.dart';
import 'move_grader.dart';
import 'pv_replay.dart';
import 'vietnamese_notation.dart';

enum CoachStatus { starting, ready, analyzing, engineUnavailable }

class CoachController extends ChangeNotifier {
  CoachController({
    required PikafishService engine,
    required NetworkInstaller networkInstaller,
    this.multiPv = 3,
    this.moveTimeMs = 800,
  }) : _engine = engine,
       _networkInstaller = networkInstaller,
       _position = Position.startpos;

  final PikafishService _engine;
  final NetworkInstaller _networkInstaller;
  Position _position;
  StreamSubscription<List<EngineLine>>? _progressSubscription;
  String? _analysisFen;

  CoachStatus status = CoachStatus.starting;
  int selectedIndex = Move.invalidIndex;
  Move? lastMove;
  Move? suggestedMove;
  List<EngineLine> lines = const [];
  MoveEvaluation? lastEvaluation;
  String? errorMessage;
  int multiPv;
  int moveTimeMs;

  Position get position => _position;
  bool get engineAvailable => status != CoachStatus.engineUnavailable;
  bool get isBusy =>
      status == CoachStatus.analyzing || status == CoachStatus.starting;

  Future<void> initialize() async {
    status = CoachStatus.starting;
    notifyListeners();
    try {
      final networkPath = await _networkInstaller.install();
      await _engine.initialize(evalFilePath: networkPath);
      _progressSubscription = _engine.progress.listen((progressLines) {
        if (status != CoachStatus.analyzing) return;
        lines = progressLines;
        _updateSuggestion();
        notifyListeners();
      });
      status = CoachStatus.ready;
      errorMessage = null;
    } catch (error) {
      status = CoachStatus.engineUnavailable;
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> analyzeCurrent() async {
    if (isBusy || !engineAvailable) return;
    final fen = position.fen;
    _analysisFen = fen;
    lastEvaluation = null;
    lines = const [];
    suggestedMove = null;
    status = CoachStatus.analyzing;
    notifyListeners();
    try {
      final result = await _engine.analyze(
        fen: fen,
        multiPv: multiPv,
        moveTimeMs: moveTimeMs,
      );
      if (position.fen == fen) {
        lines = result.lines;
        _updateSuggestion();
      }
      status = CoachStatus.ready;
      errorMessage = null;
    } catch (error) {
      status = CoachStatus.engineUnavailable;
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> tapSquare(int index) async {
    if (isBusy || index < 0 || index >= 90) return;
    final piece = position.pieceAt(index);
    if (selectedIndex == Move.invalidIndex) {
      if (PieceColor.of(piece) == position.sideToMove) {
        selectedIndex = index;
        notifyListeners();
      }
      return;
    }
    if (PieceColor.of(piece) == position.sideToMove) {
      selectedIndex = index;
      notifyListeners();
      return;
    }
    final before = Position.clone(position);
    final move = Move(selectedIndex, index);
    selectedIndex = Move.invalidIndex;
    if (!position.move(move)) {
      errorMessage = 'Nước đi không hợp lệ.';
      notifyListeners();
      return;
    }
    lastMove = Move.copy(move);
    suggestedMove = null;
    lastEvaluation = null;
    errorMessage = null;
    final cachedLines = _analysisFen == before.fen
        ? List<EngineLine>.of(lines)
        : null;
    lines = const [];
    _analysisFen = null;
    notifyListeners();
    if (engineAvailable) await _gradeMove(before, move, cachedLines);
  }

  Future<void> _gradeMove(
    Position before,
    Move playedMove,
    List<EngineLine>? cachedLines,
  ) async {
    status = CoachStatus.analyzing;
    notifyListeners();
    try {
      final beforeAnalysis = cachedLines == null || cachedLines.isEmpty
          ? await _engine.analyze(
              fen: before.fen,
              multiPv: multiPv,
              moveTimeMs: moveTimeMs,
            )
          : EngineAnalysis(
              lines: cachedLines,
              bestMove: cachedLines.first.firstMove ?? playedMove.move,
            );
      final bestLine = beforeAnalysis.bestLine;
      if (bestLine == null || bestLine.firstMove == null) {
        throw StateError('Pikafish không trả về biến phân tích hợp lệ.');
      }
      EngineLine? playedLine;
      for (final line in beforeAnalysis.lines) {
        if (line.firstMove == playedMove.move) {
          playedLine = line;
          break;
        }
      }
      final playedScore =
          playedLine?.score ??
          (await _engine.analyze(
            fen: position.fen,
            multiPv: 1,
            moveTimeMs: moveTimeMs,
          )).bestLine?.score.flipped();
      if (playedScore == null) throw StateError('Không thể đánh giá nước vừa đi.');
      lastEvaluation = MoveGrader.evaluate(
        playedMove: playedMove.move,
        bestMove: bestLine.firstMove!,
        bestScore: bestLine.score,
        playedScore: playedScore,
      );
      lines = beforeAnalysis.lines;
      status = CoachStatus.ready;
      errorMessage = null;
    } catch (error) {
      status = CoachStatus.engineUnavailable;
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  String notationFor(EngineLine line) {
    final base = positionForLines;
    final first = line.firstMove;
    if (first == null || !Move.isOK(first)) return first ?? '—';
    return VietnameseNotation.translate(base, Move.fromEngineMove(first));
  }

  Position get positionForLines {
    if (_analysisFen != null) {
      return Fen.positionFromFen(_analysisFen!) ?? Position.clone(position);
    }
    if (lastEvaluation != null) {
      final previous = Position.clone(position);
      if (previous.regret()) return previous;
    }
    return Position.clone(position);
  }

  void _updateSuggestion() {
    final first = lines.isEmpty ? null : lines.first.firstMove;
    suggestedMove = first != null && Move.isOK(first)
        ? Move.fromEngineMove(first)
        : null;
  }

  void undo() {
    if (isBusy || !position.regret()) return;
    selectedIndex = Move.invalidIndex;
    lastMove = position.lastMove == null ? null : Move.copy(position.lastMove!);
    _clearAnalysis();
    notifyListeners();
  }

  void reset() {
    if (isBusy) return;
    _position = Position.startpos;
    selectedIndex = Move.invalidIndex;
    lastMove = null;
    _engine.newGame();
    _clearAnalysis();
    notifyListeners();
  }

  void _clearAnalysis() {
    lines = const [];
    suggestedMove = null;
    lastEvaluation = null;
    errorMessage = null;
    _analysisFen = null;
  }

  @override
  void dispose() {
    unawaited(_progressSubscription?.cancel());
    unawaited(_engine.dispose());
    super.dispose();
  }
}
