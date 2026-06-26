import 'dart:math';
import '../models/position.dart';
import '../models/sensor_data.dart';
import 'fusion_engine.dart';

/// Pedestrian Dead Reckoning + integrace senzorů
class PositionTracker {
  Position _currentPosition = const Position(x: 0, y: 0, heading: 0);
  final FusionEngine fusionEngine;

  // Parametry detekce kroků
  double stepLength = 0.7; // metrů - kalibrovatelné
  double stepThreshold = 1.2; // magnituda zrychlení
  int minStepIntervalMs = 300;

  DateTime _lastStepTime = DateTime.now();
  double _lastAccelMag = 0;

  PositionTracker({required this.fusionEngine});

  Position get currentPosition => _currentPosition;

  /// Aktualizuje pozici na základě nových senzorových dat
  Position update(SensorData data) {
    // 1. Aktualizace orientace
    final quat = fusionEngine.update(data);
    final euler = quat.toEulerAngles();
    final heading = euler.z; // yaw

    // 2. Detekce kroku (jednoduchý peak detector)
    final bool stepDetected = _detectStep(data);

    if (stepDetected) {
      // Posuneme se o stepLength v aktuálním směru
      final dx = stepLength * sin(heading);
      final dy = stepLength * cos(heading);

      _currentPosition = Position(
        x: _currentPosition.x + dx,
        y: _currentPosition.y + dy,
        heading: heading,
        confidence: 0.85, // klesá s časem v reálné aplikaci
      );
    } else {
      // Aktualizujeme pouze heading i bez kroku
      _currentPosition = _currentPosition.copyWith(heading: heading);
    }

    return _currentPosition;
  }

  bool _detectStep(SensorData data) {
    final now = data.timestamp;
    final mag = data.accelerationMagnitude;

    // Jednoduchá detekce peaku
    final bool isPeak = mag > stepThreshold && _lastAccelMag < stepThreshold;
    final bool enoughTimePassed =
        now.difference(_lastStepTime).inMilliseconds > minStepIntervalMs;

    if (isPeak && enoughTimePassed) {
      _lastStepTime = now;
      _lastAccelMag = mag;
      return true;
    }

    _lastAccelMag = mag;
    return false;
  }

  void reset() {
    _currentPosition = const Position(x: 0, y: 0, heading: 0);
    _lastStepTime = DateTime.now();
  }

  void setStepLength(double length) {
    stepLength = length.clamp(0.4, 1.2);
  }
}
