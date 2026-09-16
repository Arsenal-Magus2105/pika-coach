class PieceColor {
  const PieceColor._();

  static const unknown = '-';
  static const red = 'w';
  static const black = 'b';

  static String of(String piece) {
    if ('RNBAKCP'.contains(piece)) return red;
    if ('rnbakcp'.contains(piece)) return black;
    return unknown;
  }

  static bool sameColor(String first, String second) =>
      of(first) == of(second);

  static String opponent(String color) {
    if (color == red) return black;
    if (color == black) return red;
    return color;
  }
}

class Piece {
  const Piece._();

  static const noPiece = ' ';
  static const redRook = 'R';
  static const redKnight = 'N';
  static const redBishop = 'B';
  static const redAdvisor = 'A';
  static const redKing = 'K';
  static const redCanon = 'C';
  static const redPawn = 'P';
  static const blackRook = 'r';
  static const blackKnight = 'n';
  static const blackBishop = 'b';
  static const blackAdvisor = 'a';
  static const blackKing = 'k';
  static const blackCanon = 'c';
  static const blackPawn = 'p';

  static const zhName = <String, String>{
    noPiece: '',
    redRook: '車',
    redKnight: '馬',
    redBishop: '相',
    redAdvisor: '仕',
    redKing: '帥',
    redCanon: '炮',
    redPawn: '兵',
    blackRook: '車',
    blackKnight: '馬',
    blackBishop: '象',
    blackAdvisor: '士',
    blackKing: '將',
    blackCanon: '砲',
    blackPawn: '卒',
  };

  static const viName = <String, String>{
    redRook: 'Xe',
    redKnight: 'Mã',
    redBishop: 'Tượng',
    redAdvisor: 'Sĩ',
    redKing: 'Tướng',
    redCanon: 'Pháo',
    redPawn: 'Tốt',
    blackRook: 'Xe',
    blackKnight: 'Mã',
    blackBishop: 'Tượng',
    blackAdvisor: 'Sĩ',
    blackKing: 'Tướng',
    blackCanon: 'Pháo',
    blackPawn: 'Tốt',
  };

  static bool isRed(String piece) => 'RNBAKCP'.contains(piece);
  static bool isBlack(String piece) => 'rnbakcp'.contains(piece);
}

class Move {
  static const invalidIndex = -1;

  Move(
    this.from,
    this.to, {
    this.captured = Piece.noPiece,
    this.counterMarks = '',
  }) {
    fx = from % 9;
    fy = from ~/ 9;
    tx = to % 9;
    ty = to ~/ 9;
    if (!_validCoordinate(fx, fy) || !_validCoordinate(tx, ty)) {
      throw ArgumentError('Invalid move ($from, $to)');
    }
    move = asEngineMove();
  }

  Move.fromCoordinate(this.fx, this.fy, this.tx, this.ty) {
    if (!_validCoordinate(fx, fy) || !_validCoordinate(tx, ty)) {
      throw ArgumentError('Invalid move coordinates');
    }
    from = fx + fy * 9;
    to = tx + ty * 9;
    move = asEngineMove();
  }

  Move.fromEngineMove(this.move) {
    if (!isOK(move)) throw FormatException('Invalid engine move', move);
    fx = move.codeUnitAt(0) - 97;
    fy = 9 - (move.codeUnitAt(1) - 48);
    tx = move.codeUnitAt(2) - 97;
    ty = 9 - (move.codeUnitAt(3) - 48);
    from = fx + fy * 9;
    to = tx + ty * 9;
  }

  Move.copy(Move other)
    : from = other.from,
      to = other.to,
      fx = other.fx,
      fy = other.fy,
      tx = other.tx,
      ty = other.ty,
      captured = other.captured,
      move = other.move,
      name = other.name,
      counterMarks = other.counterMarks;

  late int from;
  late int to;
  late int fx;
  late int fy;
  late int tx;
  late int ty;
  String captured = Piece.noPiece;
  late String move;
  String? name;
  String counterMarks = '';

  String asEngineMove() =>
      '${String.fromCharCode(97 + fx)}${9 - fy}'
      '${String.fromCharCode(97 + tx)}${9 - ty}';

  static bool isOK(String value) {
    if (value.length != 4) return false;
    final fx = value.codeUnitAt(0) - 97;
    final fy = 9 - (value.codeUnitAt(1) - 48);
    final tx = value.codeUnitAt(2) - 97;
    final ty = 9 - (value.codeUnitAt(3) - 48);
    return _validCoordinate(fx, fy) && _validCoordinate(tx, ty);
  }

  static bool _validCoordinate(int file, int rank) =>
      file >= 0 && file <= 8 && rank >= 0 && rank <= 9;

  @override
  bool operator ==(Object other) =>
      other is Move && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

enum GameResult { pending, win, lose, draw }
