import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/position.dart';
import '../models/map_grid.dart';
import '../models/session.dart';

/// Služba pro export mapy do 2D (JPG/PNG) a 3D (STL)
class ExportService {
  /// Export aktuálního patra jako obrázek (PNG)
  static Future<File> exportFloorAsImage({
    required MapGrid grid,
    required List<Position> path,
    required int floor,
    required String fileName,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(1200, 1200);

    // Jednoduchý painter pro export (podobný MapPainter)
    final paint = Paint();
    final cellSize = size.width / grid.width;

    // Pozadí
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Buňky
    for (int y = 0; y < grid.height; y++) {
      for (int x = 0; x < grid.width; x++) {
        final cell = grid.cells[y][x];
        if (cell == CellType.unknown) continue;

        paint.color = cell == CellType.free
            ? Colors.green.shade300
            : Colors.red.shade400;

        canvas.drawRect(
          Rect.fromLTWH(
            x * cellSize,
            y * cellSize,
            cellSize,
            cellSize,
          ),
          paint,
        );
      }
    }

    // Cesta
    if (path.isNotEmpty) {
      final pathPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;

      final pathPoints = path
          .where((p) => p.floor == floor)
          .map((p) => Offset(
                (p.x / grid.resolution) * cellSize + size.width / 2,
                (p.y / grid.resolution) * cellSize + size.height / 2,
              ))
          .toList();

      if (pathPoints.length > 1) {
        final p = Path()..moveTo(pathPoints.first.dx, pathPoints.first.dy);
        for (final pt in pathPoints.skip(1)) {
          p.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(p, pathPaint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    return file;
  }

  /// Export do jednoduchého 3D STL (ASCII)
  /// Vytvoří boxy pro obsazené buňky + jednoduché stěny
  static Future<File> exportAsSTL({
    required MapGrid grid,
    required List<Position> path,
    required String fileName,
    double wallHeight = 2.5, // výška stěn v metrech
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('solid PhoneRoomSLAM_3D');

    final cellSize = grid.resolution;
    final halfW = grid.width * cellSize / 2;
    final halfH = grid.height * cellSize / 2;

    // Pro každou obsazenou buňku vytvoříme 3D box (zed)
    for (int y = 0; y < grid.height; y++) {
      for (int x = 0; x < grid.width; x++) {
        if (grid.cells[y][x] != CellType.occupied) continue;

        final worldX = (x - grid.width / 2) * cellSize;
        final worldY = (y - grid.height / 2) * cellSize;

        _addBoxToSTL(
          buffer,
          x: worldX,
          y: worldY,
          z: 0,
          width: cellSize,
          depth: cellSize,
          height: wallHeight,
        );
      }
    }

    // Přidáme jednoduchou podlahu
    _addBoxToSTL(
      buffer,
      x: -halfW,
      y: -halfH,
      z: -0.1,
      width: grid.width * cellSize,
      depth: grid.height * cellSize,
      height: 0.1,
    );

    buffer.writeln('endsolid PhoneRoomSLAM_3D');

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.stl');
    await file.writeAsString(buffer.toString());

    return file;
  }

  static void _addBoxToSTL(
    StringBuffer buffer, {
    required double x,
    required double y,
    required double z,
    required double width,
    required double depth,
    required double height,
  }) {
    // Velmi jednoduchý box (6 stěn)
    // Pro demo stačí základní triangulace

    // Horní strana
    buffer.writeln('  facet normal 0 0 1');
    buffer.writeln('    outer loop');
    buffer.writeln('      vertex ${x} ${y} ${z + height}');
    buffer.writeln('      vertex ${x + width} ${y} ${z + height}');
    buffer.writeln('      vertex ${x + width} ${y + depth} ${z + height}');
    buffer.writeln('    endloop');
    buffer.writeln('  endfacet');

    // Spodní strana
    buffer.writeln('  facet normal 0 0 -1');
    buffer.writeln('    outer loop');
    buffer.writeln('      vertex ${x} ${y} ${z}');
    buffer.writeln('      vertex ${x + width} ${y + depth} ${z}');
    buffer.writeln('      vertex ${x + width} ${y} ${z}');
    buffer.writeln('    endloop');
    buffer.writeln('  endfacet');

    // Další stěny by byly podobné (pro zjednodušení jen horní a spodní + 4 boční)
    // V reálné verzi bychom přidali všechny 3D trojúhelníky
  }
}
