import '../models/map_grid.dart';
import '../models/position.dart';

/// Služba starající se o aktualizaci mapy během pohybu
class MapperService {
  late MapGrid grid;

  MapperService({
    int width = 120, // 12 metrů při 0.1m rozlišení
    int height = 120,
    double resolution = 0.1,
  }) {
    grid = MapGrid(
      width: width,
      height: height,
      resolution: resolution,
    );
  }

  /// Volá se při každé aktualizaci pozice
  void updateFromPosition(Position position) {
    // Označíme oblast kolem aktuální pozice jako volnou
    grid.markFree(position.x, position.y, radius: 0.4);

    // Lehce označíme i předchozí bod cesty (pro spojitou mapu)
    // V reálné verzi bychom měli historii a dělali raycasting
  }

  /// Ruční označení zdi/překážky uživatelem
  void markWallAt(double worldX, double worldY) {
    grid.markOccupied(worldX, worldY);
  }

  /// Reset mapy
  void reset({int? newWidth, int? newHeight, double? newResolution}) {
    grid = MapGrid(
      width: newWidth ?? grid.width,
      height: newHeight ?? grid.height,
      resolution: newResolution ?? grid.resolution,
    );
  }

  /// Změna rozlišení mapy (přepočítá buňky - jednoduchá verze)
  void changeResolution(double newResolution) {
    // Pro jednoduchost vytvoříme novou mřížku stejné velikosti v metrech
    final newWidth = (grid.worldWidth / newResolution).floor();
    final newHeight = (grid.worldHeight / newResolution).floor();

    final newGrid = MapGrid(
      width: newWidth,
      height: newHeight,
      resolution: newResolution,
    );

    // TODO: převod starých dat (pro demo ponecháme prázdné)
    grid = newGrid;
  }
}
