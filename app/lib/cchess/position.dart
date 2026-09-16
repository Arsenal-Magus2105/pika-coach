import 'cc_base.dart';
import 'cc_fen.dart';
import 'cc_rules.dart';
import 'move_name.dart';
import 'move_recorder.dart';

class Position {
  Position(List<String> pieces, String sideToMove, MoveRecorder recorder) {
    if (pieces.length != 90) {
      throw ArgumentError.value(pieces.length, 'pieces.length', 'must be 90');
    }
    _pieces = List<String>.of(pieces);
    _sideToMove = sideToMove;
    _recorder = recorder;
    updateInitialPosition();
  }

  Position.clone(Position other) {
    _pieces = List<String>.of(other._pieces);
    _sideToMove = other._sideToMove;
    _recorder = MoveRecorder.clone(other._recorder);
    _initialBoard = other._initialBoard;
    _lastCapturedPosition = other._lastCapturedPosition;
    result = other.result;
  }

  GameResult result = GameResult.pending;
  late String _sideToMove;
  late List<String> _pieces;
  late MoveRecorder _recorder;
  String _initialBoard = '';
  String? _lastCapturedPosition;

  static Position get startpos => Fen.positionFromFen(Fen.defaultPosition)!;

  void updateInitialPosition() {
    _lastCapturedPosition = Fen.positionToFen(this);
    _initialBoard = Fen.positionToCrManualBoard(this);
  }

  bool move(Move move, {bool validate = true}) {
    if (validate && !validateMove(move.from, move.to)) return false;

    final captured = _pieces[move.to];
    move
      ..captured = captured
      ..counterMarks = _recorder.toString();
    MoveName.translate(this, move);
    _recorder.moveIn(move, _sideToMove);

    _pieces[move.to] = _pieces[move.from];
    _pieces[move.from] = Piece.noPiece;
    _sideToMove = PieceColor.opponent(_sideToMove);
    if (captured != Piece.noPiece) {
      _lastCapturedPosition = Fen.positionToFen(this);
    }
    return true;
  }

  void moveTest(Move move, {bool turnSide = false}) {
    _pieces[move.to] = _pieces[move.from];
    _pieces[move.from] = Piece.noPiece;
    if (turnSide) _sideToMove = PieceColor.opponent(_sideToMove);
  }

  bool regret() {
    final lastMove = _recorder.removeLast();
    if (lastMove == null) return false;
    _pieces[lastMove.from] = _pieces[lastMove.to];
    _pieces[lastMove.to] = lastMove.captured;
    _sideToMove = PieceColor.opponent(_sideToMove);
    final marks = MoveRecorder.fromCounterMarks(lastMove.counterMarks);
    _recorder
      ..halfMove = marks.halfMove
      ..fullMove = marks.fullMove;
    _rebuildLastCapturedPosition();
    result = GameResult.pending;
    return true;
  }

  void _rebuildLastCapturedPosition() {
    final temp = Position.clone(this);
    for (final move in temp._recorder.reverseMovesToPrevCapture()) {
      temp._pieces[move.from] = temp._pieces[move.to];
      temp._pieces[move.to] = move.captured;
      temp._sideToMove = PieceColor.opponent(temp._sideToMove);
    }
    _lastCapturedPosition = Fen.positionToFen(temp);
  }

  bool validateMove(int from, int to) {
    if (from < 0 || from >= 90 || to < 0 || to >= 90 || from == to) {
      return false;
    }
    if (PieceColor.of(_pieces[from]) != _sideToMove) return false;
    return ChessRules.validate(this, Move(from, to));
  }

  bool appearRepeatPosition() {
    if (_recorder.historyLength < 9) return false;
    bool same(Move first, Move second, [Move? third]) {
      final firstTwo = first.from == second.from && first.to == second.to;
      return third == null
          ? firstTwo
          : firstTwo && first.from == third.from && first.to == third.to;
    }

    return same(last9Moves(0), last9Moves(4), last9Moves(8)) &&
        same(last9Moves(1), last9Moves(5)) &&
        same(last9Moves(2), last9Moves(6)) &&
        same(last9Moves(3), last9Moves(7));
  }

  bool isLongCheck() {
    if (!appearRepeatPosition()) return false;
    final temp = Position.clone(this);
    for (var index = 0; index < 9; index++) {
      temp.regret();
    }
    temp.move(last9Moves(0));
    if (!ChessRules.beChecked(temp)) return false;
    temp.move(last9Moves(1));
    temp.move(last9Moves(2));
    if (!ChessRules.beChecked(temp)) return false;
    temp.move(last9Moves(3));
    temp.move(last9Moves(4));
    if (!ChessRules.beChecked(temp)) return false;
    temp.move(last9Moves(5));
    temp.move(last9Moves(6));
    if (!ChessRules.beChecked(temp)) return false;
    temp.move(last9Moves(7));
    temp.move(last9Moves(8));
    return ChessRules.beChecked(temp);
  }

  String buildPositionCommand() {
    final base = lastCapturedPosition;
    final moves = movesAfterLastCaptured;
    return moves.isEmpty
        ? 'position fen $base'
        : 'position fen $base moves $moves';
  }

  Move last9Moves(int index) =>
      _recorder.moveAt((_recorder.historyLength - 9) + index);
  String pieceAt(int index) => _pieces[index];
  void setPiece(int index, String piece) => _pieces[index] = piece;
  void turnSide() => _sideToMove = PieceColor.opponent(_sideToMove);

  String get initialBoard => _initialBoard;
  String get initBoard => _initialBoard;
  String get sideToMove => _sideToMove;
  MoveRecorder get recorder => _recorder;
  Move? get lastMove => _recorder.last;
  int get halfMove => _recorder.halfMove;
  int get fullMove => _recorder.fullMove;
  String get moveCount => _recorder.toString();
  String? get lastCapturedPosition => _lastCapturedPosition;
  String get allMoves => _recorder.allMoves();
  String get movesAfterLastCaptured => _recorder.movesAfterLastCaptured();
  String get fen => Fen.positionToFen(this);
}
