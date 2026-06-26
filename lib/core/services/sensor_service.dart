import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vector_math/vector_math.dart';
import '../models/sensor_data.dart';
import '../models/position.dart';

/// Služba pro sjednocený přístup k senzorům telefonu.
/// Stream všech dat v reálném čase.
class SensorService {
  StreamController<SensorData> _controller =
      StreamController<SensorData>.broadcast();

  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _magSub;
  StreamSubscription? _positionSub;

  // Poslední známé hodnoty (pro sloučení do jednoho SensorData)
  Vector3 _lastAccel = Vector3.zero();
  Vector3 _lastGyro = Vector3.zero();
  Vector3 _lastMag = Vector3.zero();
  Position? _lastPosition;

  bool _isRunning = false;

  Stream<SensorData> get sensorStream => _controller.stream;
  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // Akcelerometr (včetně gravitace) - 50Hz
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((event) {
      _lastAccel = Vector3(event.x, event.y, event.z);
      _emitCurrentData();
    });

    // Gyroskop
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((event) {
      _lastGyro = Vector3(event.x, event.y, event.z);
      _emitCurrentData();
    });

    // Magnetometr
    _magSub = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((event) {
      _lastMag = Vector3(event.x, event.y, event.z);
      _emitCurrentData();
    });

    // GPS (nižší frekvence)
    final hasPermission = await _checkLocationPermission();
    if (hasPermission) {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      ).listen((pos) {
        _lastPosition = Position(
          x: pos.longitude, // pro demo používáme jako offset
          y: pos.latitude,
          heading: pos.heading ?? 0,
        );
        _emitCurrentData();
      });
    }
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  void _emitCurrentData() {
    if (!_isRunning || _controller.isClosed) return;

    final data = SensorData(
      timestamp: DateTime.now(),
      accelerometer: _lastAccel,
      gyroscope: _lastGyro,
      magnetometer: _lastMag,
      latitude: _lastPosition?.y,
      longitude: _lastPosition?.x,
    );

    _controller.add(data);
  }

  Future<void> stop() async {
    _isRunning = false;
    await _accelSub?.cancel();
    await _gyroSub?.cancel();
    await _magSub?.cancel();
    await _positionSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _magSub = null;
    _positionSub = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
