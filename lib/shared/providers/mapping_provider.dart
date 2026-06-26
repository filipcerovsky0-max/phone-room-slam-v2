import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/position.dart';
import '../../core/models/map_grid.dart';
import '../../core/models/session.dart';
import '../../core/models/sensor_data.dart';
import '../../core/services/sensor_service.dart';
import '../../core/services/fusion_engine.dart';
import '../../core/services/position_tracker.dart';
import '../../core/services/mapper_service.dart';

/// Komplexní state pro mapování - spojuje všechny služby
class MappingState {
  final bool isRecording;
  final Position currentPosition;
  final List<Position> path;
  final MapGrid grid;
  final List<SensorData> recentSensorData; // pro grafy

  const MappingState({
    this.isRecording = false,
    this.currentPosition = const Position(x: 0, y: 0, heading: 0),
    this.path = const [],
    required this.grid,
    this.recentSensorData = const [],
  });

  MappingState copyWith({
    bool? isRecording,
    Position? currentPosition,
    List<Position>? path,
    MapGrid? grid,
    List<SensorData>? recentSensorData,
  }) {
    return MappingState(
      isRecording: isRecording ?? this.isRecording,
      currentPosition: currentPosition ?? this.currentPosition,
      path: path ?? this.path,
      grid: grid ?? this.grid,
      recentSensorData: recentSensorData ?? this.recentSensorData,
    );
  }
}

class MappingNotifier extends StateNotifier<MappingState> {
  final SensorService _sensorService = SensorService();
  final FusionEngine _fusionEngine = FusionEngine();
  final PositionTracker _positionTracker;
  final MapperService _mapperService = MapperService();

  StreamSubscription? _sensorSub;
  Timer? _updateTimer;

  MappingNotifier()
      : _positionTracker = PositionTracker(fusionEngine: FusionEngine()),
        super(MappingState(grid: MapGrid(width: 120, height: 120, resolution: 0.1)));

  void startRecording() {
    if (state.isRecording) return;

    _sensorService.start();
    _sensorSub = _sensorService.sensorStream.listen(_onNewSensorData);

    // Pravidelné ukládání pozice do path (i když se nehýbeme)
    _updateTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (state.isRecording) {
        final pos = _positionTracker.currentPosition;
        final newPath = [...state.path, pos];
        final newGrid = state.grid;
        _mapperService.updateFromPosition(pos);

        state = state.copyWith(
          currentPosition: pos,
          path: newPath,
          grid: newGrid,
        );
      }
    });

    state = state.copyWith(isRecording: true);
  }

  void pauseRecording() {
    _sensorSub?.cancel();
    _updateTimer?.cancel();
    _sensorService.stop();
    state = state.copyWith(isRecording: false);
  }

  void _onNewSensorData(SensorData data) {
    if (!state.isRecording) return;

    // Fúze + aktualizace pozice
    final newPos = _positionTracker.update(data);
    _mapperService.updateFromPosition(newPos);

    // Přidání do recent dat pro grafy (max 60 vzorků)
    final newRecent = [...state.recentSensorData, data];
    if (newRecent.length > 60) newRecent.removeAt(0);

    state = state.copyWith(
      currentPosition: newPos,
      path: [...state.path, newPos],
      grid: _mapperService.grid,
      recentSensorData: newRecent,
    );
  }

  void markWall() {
    // Označí aktuální pozici jako zeď (uživatel může stát u zdi)
    _mapperService.markWallAt(
      state.currentPosition.x,
      state.currentPosition.y,
    );
    state = state.copyWith(grid: _mapperService.grid);
  }

  void markWallAt(double x, double y) {
    _mapperService.markWallAt(x, y);
    state = state.copyWith(grid: _mapperService.grid);
  }

  Future<void> saveCurrentSession(String name) async {
    final session = MappingSession(
      startTime: DateTime.now().subtract(const Duration(minutes: 5)),
      endTime: DateTime.now(),
      name: name,
      path: state.path,
      grid: state.grid,
      metadata: {
        'stepCount': state.path.length,
        'durationMinutes': 5,
      },
    );

    // V plné verzi bychom uložili do Hive
    // Pro demo zatím jen print
    print('Uložena relace: ${session.name} s ${session.path.length} body');
  }

  void reset() {
    pauseRecording();
    _positionTracker.reset();
    _mapperService.reset();
    _fusionEngine.reset();

    state = MappingState(grid: MapGrid(width: 120, height: 120, resolution: 0.1));
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _updateTimer?.cancel();
    _sensorService.dispose();
    super.dispose();
  }
}

final mappingProvider = StateNotifierProvider<MappingNotifier, MappingState>((ref) {
  return MappingNotifier();
});
