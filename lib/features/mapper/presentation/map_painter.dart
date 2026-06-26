import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/models/position.dart';
import '../../../core/models/map_grid.dart';

class MapPainter extends CustomPainter {
  final MapGrid grid;
  final List<Position> path;
  final Position currentPosition;
  final double zoom;
  final Offset offset;

  MapPainter({
    required this.grid,
    required this.path,
    required this.currentPosition,
    this.zoom = 1.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.save();
    canvas.translate(center.dx + offset.dx, center.dy + offset.dy);
    canvas.scale(zoom);

    final cellSize = 8.0; // velikost buňky na obrazovce (px)
    final scale = cellSize / grid.resolution;

    // Pozadí mřížky
    final bgPaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        -grid.width * cellSize / 2,
        -grid.height * cellSize / 2,
        grid.width * cellSize,
        grid.height * cellSize,
      ),
      bgPaint,
    );

    // Vykreslení buněk mapy
    for (int y = 0; y < grid.height; y++) {
      for (int x = 0; x < grid.width; x++) {
        final cell = grid.cells[y][x];
        if (cell == CellType.unknown) continue;

        final paint = Paint()
          ..style = PaintingStyle.fill
          ..color = switch (cell) {
            CellType.free => Colors.green.withOpacity(0.6),
            CellType.occupied => Colors.red.withOpacity(0.85),
            _ => Colors.transparent,
          };

        final rect = Rect.fromLTWH(
          (x - grid.width / 2) * cellSize,
          (y - grid.height / 2) * cellSize,
          cellSize,
          cellSize,
        );
        canvas.drawRect(rect, paint);
      }
    }

    // Mřížka (tenké čáry)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 0.5;
    for (int i = -grid.width ~/ 2; i <= grid.width ~/ 2; i++) {
      canvas.drawLine(
        Offset(i * cellSize, -grid.height * cellSize / 2),
        Offset(i * cellSize, grid.height * cellSize / 2),
        gridPaint,
      );
    }
    for (int i = -grid.height ~/ 2; i <= grid.height ~/ 2; i++) {
      canvas.drawLine(
        Offset(-grid.width * cellSize / 2, i * cellSize),
        Offset(grid.width * cellSize / 2, i * cellSize),
        gridPaint,
      );
    }

    // Cesta (modrá čára)
    if (path.length > 1) {
      final pathPaint = Paint()
        ..color = Colors.blueAccent
        ..strokeWidth = 3.5 / zoom
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final pathPoints = path.map((p) {
        return Offset(
          (p.x / grid.resolution) * cellSize,
          (p.y / grid.resolution) * cellSize,
        );
      }).toList();

      final pathToDraw = Path()..moveTo(pathPoints.first.dx, pathPoints.first.dy);
      for (final pt in pathPoints.skip(1)) {
        pathToDraw.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(pathToDraw, pathPaint);
    }

    // Aktuální pozice (šipka)
    final posX = (currentPosition.x / grid.resolution) * cellSize;
    final posY = (currentPosition.y / grid.resolution) * cellSize;

    canvas.save();
    canvas.translate(posX, posY);
    canvas.rotate(-currentPosition.heading); // otočení podle yaw

    // Šipka
    final arrowPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    final pathArrow = Path()
      ..moveTo(0, -18)
      ..lineTo(12, 12)
      ..lineTo(-12, 12)
      ..close();
    canvas.drawPath(pathArrow, arrowPaint);

    // Kruh kolem
    canvas.drawCircle(
      Offset.zero,
      22,
      Paint()
        ..color = Colors.orange.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.restore();

    // Start bod
    if (path.isNotEmpty) {
      final start = path.first;
      final startX = (start.x / grid.resolution) * cellSize;
      final startY = (start.y / grid.resolution) * cellSize;
      canvas.drawCircle(
        Offset(startX, startY),
        8,
        Paint()..color = Colors.purpleAccent,
      );
      canvas.drawCircle(
        Offset(startX, startY),
        14,
        Paint()
          ..color = Colors.purpleAccent.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    canvas.restore();

    // Legenda v rohu
    _drawLegend(canvas, size);
  }

  void _drawLegend(Canvas canvas, Size size) {
    final legendX = size.width - 140;
    final legendY = 20.0;

    final bg = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(legendX - 10, legendY - 10, 130, 95),
        const Radius.circular(8),
      ),
      bg,
    );

    final textStyle = const TextStyle(color: Colors.white, fontSize: 11);
    final tp = TextPainter(textDirection: TextDirection.ltr);

    void drawItem(double y, Color color, String text) {
      canvas.drawRect(
        Rect.fromLTWH(legendX, y, 16, 16),
        Paint()..color = color,
      );
      tp.text = TextSpan(text: text, style: textStyle);
      tp.layout();
      tp.paint(canvas, Offset(legendX + 22, y + 1));
    }

    drawItem(legendY, Colors.green.withOpacity(0.7), 'Volný prostor');
    drawItem(legendY + 22, Colors.red.withOpacity(0.85), 'Zeď / překážka');
    drawItem(legendY + 44, Colors.blueAccent, 'Vaše cesta');
    drawItem(legendY + 66, Colors.orange, 'Aktuální pozice');
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return true; // Vždy překreslit při změně stavu
  }
}
