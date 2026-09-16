import 'dart:async';

import 'engine_line.dart';
import 'engine_transport.dart';
import 'uci_parser.dart';

enum PikafishStatus { idle, starting, ready, analyzing, failed, disposed }

class PikafishService {
  PikafishService(this._transport);

  final EngineTransport _transport;
  final _progressController = StreamController<List<EngineLine>>.broadcast();
  final Map<int, EngineLine> _latestLines = {};
  StreamSubscription<String>? _subscription;
  Completer<void>? _uciCompleter;
  Completer<void>? _readyCompleter;
  Completer<EngineAnalysis>? _analysisCompleter;

  PikafishStatus status = PikafishStatus.idle;
  String? lastError;
  Stream<List<EngineLine>> get progress => _progressController.stream;
  bool get isReady => status == PikafishStatus.ready;

  Future<void> initialize({
    required String evalFilePath,
    int threads = 2,
    int hashMb = 64,
  }) async {
    if (status == PikafishStatus.ready) return;
    status = PikafishStatus.starting;
    try {
      await _transport.start();
      _subscription = _transport.stdout.listen(
        _handleLine,
        onError: _handleError,
        onDone: () {
          if (status != PikafishStatus.disposed) {
            _handleError(StateError('Pikafish output stream ended'));
          }
        },
      );
      _uciCompleter = Completer<void>();
      _transport.send('uci');
      await _uciCompleter!.future.timeout(const Duration(seconds: 15));
      _transport.send('setoption name Threads value $threads');
      _transport.send('setoption name Hash value $hashMb');
      _transport.send('setoption name Ponder value false');
      _transport.send('setoption name EvalFile value $evalFilePath');
      _transport.send('ucinewgame');
      _readyCompleter = Completer<void>();
      _transport.send('isready');
      await _readyCompleter!.future.timeout(const Duration(seconds: 15));
      status = PikafishStatus.ready;
    } catch (error) {
      status = PikafishStatus.failed;
      lastError = error.toString();
      rethrow;
    }
  }

  Future<EngineAnalysis> analyze({
    required String fen,
    int multiPv = 3,
    int moveTimeMs = 800,
  }) async {
    if (status != PikafishStatus.ready) {
      throw StateError('Pikafish is not ready ($status)');
    }
    if (_analysisCompleter != null) {
      throw StateError('Another analysis is already running');
    }
    final boundedMultiPv = multiPv.clamp(1, 5).toInt();
    final boundedMoveTime = moveTimeMs.clamp(100, 10000).toInt();
    _latestLines.clear();
    _analysisCompleter = Completer<EngineAnalysis>();
    status = PikafishStatus.analyzing;
    _transport.send('setoption name MultiPV value $boundedMultiPv');
    _transport.send('position fen $fen');
    _transport.send('go movetime $boundedMoveTime');
    try {
      return await _analysisCompleter!.future.timeout(
        Duration(milliseconds: boundedMoveTime + 15000),
      );
    } finally {
      _analysisCompleter = null;
      if (status == PikafishStatus.analyzing) status = PikafishStatus.ready;
    }
  }

  Future<void> stop() async {
    final completer = _analysisCompleter;
    if (completer == null || completer.isCompleted) return;
    _transport.send('stop');
    try {
      await completer.future.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('Pikafish did not stop'));
      }
    }
  }

  void newGame() {
    if (status == PikafishStatus.ready) _transport.send('ucinewgame');
  }

  void _handleLine(String rawLine) {
    final line = rawLine.trim();
    if (line == 'uciok') {
      final completer = _uciCompleter;
      if (completer != null && !completer.isCompleted) completer.complete();
      return;
    }
    if (line == 'readyok') {
      final completer = _readyCompleter;
      if (completer != null && !completer.isCompleted) completer.complete();
      return;
    }
    final info = UciInfoParser.parseInfo(line);
    if (info != null && _analysisCompleter != null) {
      final previous = _latestLines[info.multiPv];
      if (previous == null || info.isNewerThan(previous)) {
        _latestLines[info.multiPv] = info;
        _progressController.add(_sortedLines());
      }
      return;
    }
    final bestMove = UciInfoParser.parseBestMove(line);
    final completer = _analysisCompleter;
    if (bestMove != null && completer != null && !completer.isCompleted) {
      completer.complete(
        EngineAnalysis(
          lines: _sortedLines(),
          bestMove: bestMove.bestMove,
          ponder: bestMove.ponder,
        ),
      );
      status = PikafishStatus.ready;
    }
  }

  List<EngineLine> _sortedLines() {
    final result = _latestLines.values.toList()
      ..sort((first, second) => first.multiPv.compareTo(second.multiPv));
    return List.unmodifiable(result);
  }

  void _handleError(Object error) {
    lastError = error.toString();
    status = PikafishStatus.failed;
    final completer = _analysisCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  }

  Future<void> dispose() async {
    status = PikafishStatus.disposed;
    await _subscription?.cancel();
    await _transport.dispose();
    await _progressController.close();
  }
}
