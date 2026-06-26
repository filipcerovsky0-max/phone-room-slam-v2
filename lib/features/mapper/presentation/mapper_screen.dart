import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/position.dart';
import '../../../core/models/map_grid.dart';
import '../../../core/services/export_service.dart';
import '../../../shared/providers/mapping_provider.dart';
import 'map_painter.dart';

class MapperScreen extends ConsumerStatefulWidget {
  const MapperScreen({super.key});

  @override
  ConsumerState<MapperScreen> createState() => _MapperScreenState();
}

class _MapperScreenState extends ConsumerState<MapperScreen> {
  bool _isRecording = false;
  double _zoom = 1.0;
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final mappingState = ref.watch(mappingProvider);
    final currentPos = mappingState.currentPosition;
    final grid = mappingState.grid;
    final path = mappingState.path;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapování místnosti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: () => _saveSession(ref),
            tooltip: 'Uložit relaci',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(mappingProvider.notifier).reset(),
            tooltip: 'Reset mapy',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoChip(
                  icon: Icons.directions_walk,
                  label: 'Kroky',
                  value: '${path.length}',
                ),
                _InfoChip(
                  icon: Icons.straighten,
                  label: 'Vzdálenost',
                  value: '${_calculateDistance(path).toStringAsFixed(1)} m',
                ),
                _InfoChip(
                  icon: Icons.grid_on,
                  label: 'Buňky',
                  value: '${grid.width}×${grid.height}',
                ),
              ],
            ),
          ),

          // MAPA - hlavní prvek
          Expanded(
            child: GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _zoom = (_zoom * details.scale).clamp(0.5, 5.0);
                  _offset += details.focalPointDelta;
                });
              },
              onTapDown: (details) {
                // Ruční označení zdi
                if (_isRecording) {
                  _markWallAtTap(details.localPosition, grid, currentPos);
                }
              },
              child: Container(
                color: Colors.black87,
                child: CustomPaint(
                  painter: MapPainter(
                    grid: grid,
                    path: path,
                    currentPosition: currentPos,
                    zoom: _zoom,
                    offset: _offset,
                  ),
                  child: Container(),
                ),
              ),
            ),
          ),

          // Ovládací panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Colors.grey.shade800),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _toggleRecording(ref),
                      icon: Icon(_isRecording
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled),
                      label: Text(_isRecording ? 'Pauza' : 'Spustit mapování'),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            _isRecording ? Colors.orange : Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ref.read(mappingProvider.notifier).markWall(),
                      icon: const Icon(Icons.wallpaper),
                      label: const Text('Označit zeď'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // === NOVÉ: Export 2D a 3D ===
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _export2D(ref),
                      icon: const Icon(Icons.image),
                      label: const Text('Stáhnout 2D (.png)'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _export3D(ref),
                      icon: const Icon(Icons.view_in_ar),
                      label: const Text('Stáhnout 3D (.stl)'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '3D STL obsahuje zdi a podlahu. Pro prohlížení použij FreeCAD, Blender nebo online STL viewer.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _isRecording
                      ? 'Chodíte po místnosti. Aplikace zaznamenává vaši cestu a staví mapu.'
                      : 'Stiskněte "Spustit mapování" a začněte chodit po místnosti.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleRecording(WidgetRef ref) {
    setState(() {
      _isRecording = !_isRecording;
    });
    if (_isRecording) {
      ref.read(mappingProvider.notifier).startRecording();
    } else {
      ref.read(mappingProvider.notifier).pauseRecording();
    }
  }

  void _markWallAtTap(Offset tap, MapGrid grid, Position current) {
    // Převod tap pozice na world coordinates (zjednodušeno)
    final worldX = current.x + (tap.dx - 200) / 40.0; // scale factor
    final worldY = current.y + (tap.dy - 300) / 40.0;
    ref.read(mappingProvider.notifier).markWallAt(worldX, worldY);
  }

  double _calculateDistance(List<Position> path) {
    if (path.length < 2) return 0;
    double dist = 0;
    for (int i = 1; i < path.length; i++) {
      final dx = path[i].x - path[i - 1].x;
      final dy = path[i].y - path[i - 1].y;
      dist += (dx * dx + dy * dy);
    }
    return dist;
  }

  Future<void> _saveSession(WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Uložit relaci'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Název místnosti'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'Místnost ${DateTime.now().hour}:${DateTime.now().minute}'),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );

    if (name != null) {
      await ref.read(mappingProvider.notifier).saveCurrentSession(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relace byla úspěšně uložena!')),
        );
      }
    }
  }

  // === NOVÉ EXPORT FUNKCE ===
  Future<void> _export2D(WidgetRef ref) async {
    final state = ref.read(mappingProvider);
    try {
      final file = await ExportService.exportFloorAsImage(
        grid: state.grid,
        path: state.path,
        floor: 0, // prozatím jen přízemí
        fileName: 'room_2d_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('2D mapa uložena: ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při exportu 2D: $e')),
      );
    }
  }

  Future<void> _export3D(WidgetRef ref) async {
    final state = ref.read(mappingProvider);
    try {
      final file = await ExportService.exportAsSTL(
        grid: state.grid,
        path: state.path,
        fileName: 'room_3d_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('3D STL uložen: ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při exportu 3D STL: $e')),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
