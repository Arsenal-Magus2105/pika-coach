import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../cchess/cc_base.dart';
import '../cchess/position.dart';

class XiangqiBoard extends StatelessWidget {
  const XiangqiBoard({
    super.key,
    required this.position,
    required this.selectedIndex,
    required this.onTap,
    this.lastMove,
    this.suggestedMove,
    this.inverted = false,
  });

  final Position position;
  final int selectedIndex;
  final Move? lastMove;
  final Move? suggestedMove;
  final bool inverted;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 520.0);
        final geometry = _BoardGeometry(width);
        final pieces = List<String>.generate(90, position.pieceAt);
        return Center(
          child: Semantics(
            label: 'Bàn Cờ Tướng',
            child: GestureDetector(
              onTapUp: (details) {
                final index = geometry.indexAt(details.localPosition, inverted);
                if (index != null) onTap(index);
              },
              child: SizedBox(
                width: width,
                height: geometry.height,
                child: CustomPaint(
                  painter: _XiangqiBoardPainter(
                    geometry: geometry,
                    pieces: pieces,
                    selectedIndex: selectedIndex,
                    lastMove: lastMove,
                    suggestedMove: suggestedMove,
                    inverted: inverted,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardGeometry {
  _BoardGeometry(this.width)
    : padding = width * 0.065,
      square = (width - width * 0.13) / 8;

  final double width;
  final double padding;
  final double square;
  double get height => padding * 2 + square * 9;

  Offset pointForIndex(int index, bool inverted) {
    var file = index % 9;
    var rank = index ~/ 9;
    if (inverted) {
      file = 8 - file;
      rank = 9 - rank;
    }
    return Offset(padding + file * square, padding + rank * square);
  }

  int? indexAt(Offset point, bool inverted) {
    final file = ((point.dx - padding) / square).round();
    final rank = ((point.dy - padding) / square).round();
    if (file < 0 || file > 8 || rank < 0 || rank > 9) return null;
    final center = Offset(padding + file * square, padding + rank * square);
    if ((point - center).distance > square * 0.48) return null;
    final boardFile = inverted ? 8 - file : file;
    final boardRank = inverted ? 9 - rank : rank;
    return boardRank * 9 + boardFile;
  }
}

class _XiangqiBoardPainter extends CustomPainter {
  _XiangqiBoardPainter({
    required this.geometry,
    required this.pieces,
    required this.selectedIndex,
    required this.lastMove,
    required this.suggestedMove,
    required this.inverted,
  });

  final _BoardGeometry geometry;
  final List<String> pieces;
  final int selectedIndex;
  final Move? lastMove;
  final Move? suggestedMove;
  final bool inverted;
  static const _wood = Color(0xFFF0C98B);
  static const _woodEdge = Color(0xFFB77A36);
  static const _ink = Color(0xFF5B341C);
  static const _red = Color(0xFFA62724);
  static const _black = Color(0xFF22252B);
  static const _hint = Color(0xFF17B890);

  @override
  void paint(Canvas canvas, Size size) {
    final boardRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );
    canvas.drawRRect(boardRect, Paint()..color = _wood);
    canvas.drawRRect(
      boardRect.deflate(1.5),
      Paint()
        ..color = _woodEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    _drawGrid(canvas);
    _drawHighlights(canvas);
    _drawPieces(canvas);
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = _ink.withValues(alpha: 0.82)
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke;
    final left = geometry.padding;
    final top = geometry.padding;
    final right = left + geometry.square * 8;
    canvas.drawRect(
      Rect.fromLTWH(left, top, geometry.square * 8, geometry.square * 9),
      paint..strokeWidth = 2.2,
    );
    paint.strokeWidth = 1.25;
    for (var rank = 1; rank < 9; rank++) {
      final y = top + rank * geometry.square;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
    for (var file = 1; file < 8; file++) {
      final x = left + file * geometry.square;
      canvas.drawLine(Offset(x, top), Offset(x, top + geometry.square * 4), paint);
      canvas.drawLine(
        Offset(x, top + geometry.square * 5),
        Offset(x, top + geometry.square * 9),
        paint,
      );
    }
    void palace(int firstRank) {
      final x3 = left + geometry.square * 3;
      final x5 = left + geometry.square * 5;
      final y0 = top + geometry.square * firstRank;
      final y2 = top + geometry.square * (firstRank + 2);
      canvas.drawLine(Offset(x3, y0), Offset(x5, y2), paint);
      canvas.drawLine(Offset(x5, y0), Offset(x3, y2), paint);
    }
    palace(0);
    palace(7);
    _text(
      canvas,
      '楚 河',
      Offset(left + geometry.square * 2.15, top + geometry.square * 4.5),
      fontSize: geometry.square * 0.36,
      color: _ink.withValues(alpha: 0.76),
    );
    _text(
      canvas,
      '漢 界',
      Offset(left + geometry.square * 5.85, top + geometry.square * 4.5),
      fontSize: geometry.square * 0.36,
      color: _ink.withValues(alpha: 0.76),
    );
  }

  void _drawHighlights(Canvas canvas) {
    final previous = lastMove;
    if (previous != null) {
      final paint = Paint()
        ..color = const Color(0xFFFFB703).withValues(alpha: 0.36);
      canvas.drawCircle(
        geometry.pointForIndex(previous.from, inverted),
        geometry.square * 0.23,
        paint,
      );
      canvas.drawCircle(
        geometry.pointForIndex(previous.to, inverted),
        geometry.square * 0.34,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    if (selectedIndex != Move.invalidIndex) {
      canvas.drawCircle(
        geometry.pointForIndex(selectedIndex, inverted),
        geometry.square * 0.44,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final suggestion = suggestedMove;
    if (suggestion != null) {
      final from = geometry.pointForIndex(suggestion.from, inverted);
      final to = geometry.pointForIndex(suggestion.to, inverted);
      final direction = to - from;
      if (direction.distance > 0) {
        final unit = direction / direction.distance;
        final start = from + unit * geometry.square * 0.28;
        final end = to - unit * geometry.square * 0.34;
        canvas.drawLine(
          start,
          end,
          Paint()
            ..color = _hint.withValues(alpha: 0.9)
            ..strokeWidth = geometry.square * 0.11
            ..strokeCap = StrokeCap.round,
        );
        final angle = math.atan2(direction.dy, direction.dx);
        final head = geometry.square * 0.25;
        final path = Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(
            end.dx - head * math.cos(angle - math.pi / 5),
            end.dy - head * math.sin(angle - math.pi / 5),
          )
          ..lineTo(
            end.dx - head * math.cos(angle + math.pi / 5),
            end.dy - head * math.sin(angle + math.pi / 5),
          )
          ..close();
        canvas.drawPath(path, Paint()..color = _hint);
      }
    }
  }

  void _drawPieces(Canvas canvas) {
    final radius = geometry.square * 0.42;
    for (var index = 0; index < pieces.length; index++) {
      final piece = pieces[index];
      if (piece == Piece.noPiece) continue;
      final center = geometry.pointForIndex(index, inverted);
      final color = Piece.isRed(piece) ? _red : _black;
      canvas.drawCircle(
        center + const Offset(1.5, 2.5),
        radius,
        Paint()..color = Colors.black.withValues(alpha: 0.24),
      );
      canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFFFF3D5));
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
      _text(
        canvas,
        Piece.zhName[piece]!,
        center,
        fontSize: radius * 1.05,
        color: color,
        fontWeight: FontWeight.w700,
      );
    }
  }

  void _text(
    Canvas canvas,
    String value,
    Offset center, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_XiangqiBoardPainter oldDelegate) =>
      oldDelegate.pieces.join() != pieces.join() ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.lastMove != lastMove ||
      oldDelegate.suggestedMove != suggestedMove ||
      oldDelegate.inverted != inverted ||
      oldDelegate.geometry.width != geometry.width;
}
