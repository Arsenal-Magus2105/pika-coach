import '../cchess/cc_base.dart';
import '../cchess/position.dart';

class VietnameseNotation {
  const VietnameseNotation._();

  static String translate(Position position, Move move) {
    final piece = position.pieceAt(move.from);
    if (piece == Piece.noPiece) return move.move;
    final red = Piece.isRed(piece);
    final fromFile = red ? 9 - move.fx : move.fx + 1;
    final toFile = red ? 9 - move.tx : move.tx + 1;
    final name = Piece.viName[piece] ?? piece;

    if (move.fy == move.ty) return '$name $fromFile bình $toFile';

    final forward = red ? move.ty < move.fy : move.ty > move.fy;
    final verb = forward ? 'tiến' : 'thoái';
    final usesDestinationFile =
        piece.toLowerCase() == 'n' ||
        piece.toLowerCase() == 'b' ||
        piece.toLowerCase() == 'a';
    final amount = usesDestinationFile ? toFile : (move.ty - move.fy).abs();
    return '$name $fromFile $verb $amount';
  }
}
