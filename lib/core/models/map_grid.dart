import 'dart:math';

enum CellType { unknown, free, occupied }

/// 2D Occupancy Grid pro mapování místnosti
/// Reprezentuje reálný prostor jako mřížku buněk
class MapGrid {
  final int width; // počet buněk v x
  final int height; // počet buněk v y
  final double resolution; // velikost jedné buňky v metrech (např. 0.1 = 10cm)
  final List<List<CellType>> cells;

  // Počátek mapy v reálných souřadnicích (obvykle 0,0 = start pozice)
  final double originX;
  final double originY;

  MapGrid({
    required this.width,
    required this.height,
    required this.resolution,
    double? originX,
    double? originY,
  })  : originX = originX ?? 0,
        originY = originY ?? 0,
        cells = List.generate(
          height,
          (_) => List.filled(width, CellType.unknown),
        );

  /// Převede reálné souřadnice (metry) na indexy buňky
  (int, int) worldToCell(double worldX, double worldY) {
    final cellX = ((worldX - originX) / resolution).floor();
    final cellY = ((worldY - originY) / resolution).floor();
    return (
      cellX.clamp(0, width - 1),
      cellY.clamp(0, height - 1)
    );
  }

  /// Označí oblast jako prozkoumanou / volnou (free)
  void markFree(double worldX, double worldY, {double radius = 0.3}) {
    final (cx, cy) = worldToCell(worldX, worldY);
    final r = (radius / resolution).ceil();

    for (int dx = -r; dx <= r; dx++) {
      for (int dy = -r; dy <= r; dy++) {
        final nx = cx + dx;
        final ny = cy + dy;
        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
          if (cells[ny][nx] == CellType.unknown) {
            cells[ny][nx] = CellType.free;
          }
        }
      }
    }
  }

  /// Označí buňku jako obsazenou (zeď / překážka)
  void markOccupied(double worldX, double worldY) {
    final (cx, cy) = worldToCell(worldX, worldY);
    cells[cy][cx] = CellType.occupied;
  }

  /// Vrátí typ buňky na dané pozici
  CellType getCellType(double worldX, double worldY) {
    final (cx, cy) = worldToCell(worldX, worldY);
    return cells[cy][cx];
  }

  /// Vrátí rozměry mapy v metrech
  double get worldWidth => width * resolution;
  double get worldHeight => height * resolution;

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'resolution': resolution,
        'originX': originX,
        'originY': originY,
        'cells': cells
            .map((row) => row.map((c) => c.index).toList())
            .toList(),
      };

  factory MapGrid.fromJson(Map<String, dynamic> json) {
    final grid = MapGrid(
      width: json['width'],
      height: json['height'],
      resolution: json['resolution'].toDouble(),
      originX: json['originX']?.toDouble() ?? 0,
      originY: json['originY']?.toDouble() ?? 0,
    );

    final cellData = json['cells'] as List;
    for (int y = 0; y < grid.height; y++) {
      for (int x = 0; x < grid.width; x++) {
        final idx = cellData[y][x] as int;
        grid.cells[y][x] = CellType.values[idx];
      }
    }
    return grid;
  }
}
