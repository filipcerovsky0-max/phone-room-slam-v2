import 'package:vector_math/vector_math.dart';

/// Reprezentuje jeden snapshot ze všech senzorů telefonu v daném čase.
class SensorData {
  final DateTime timestamp;

  // Akcelerometr (m/s²) - včetně gravitace nebo lineární (podle pluginu)
  final Vector3 accelerometer;

  // Gyroskop (rad/s)
  final Vector3 gyroscope;

  // Magnetometr (µT)
  final Vector3 magnetometer;

  // GPS (pokud dostupné)
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? accuracy;

  // Barometr (hPa) - pokud telefon má
  final double? pressure;

  // Předzpracovaná data
  final double accelerationMagnitude; // sqrt(ax²+ay²+az²)
  final Quaternion? orientation; // aktuální odhad orientace (pokud již spočítáno)

  SensorData({
    required this.timestamp,
    required this.accelerometer,
    required this.gyroscope,
    required this.magnetometer,
    this.latitude,
    this.longitude,
    this.altitude,
    this.accuracy,
    this.pressure,
    Quaternion? orientation,
  })  : accelerationMagnitude = accelerometer.length,
        orientation = orientation;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'acc': [accelerometer.x, accelerometer.y, accelerometer.z],
        'gyro': [gyroscope.x, gyroscope.y, gyroscope.z],
        'mag': [magnetometer.x, magnetometer.y, magnetometer.z],
        'lat': latitude,
        'lon': longitude,
        'alt': altitude,
        'accu': accuracy,
        'pressure': pressure,
      };

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp: DateTime.parse(json['timestamp']),
      accelerometer: Vector3(
        json['acc'][0], json['acc'][1], json['acc'][2]),
      gyroscope: Vector3(
        json['gyro'][0], json['gyro'][1], json['gyro'][2]),
      magnetometer: Vector3(
        json['mag'][0], json['mag'][1], json['mag'][2]),
      latitude: json['lat']?.toDouble(),
      longitude: json['lon']?.toDouble(),
      altitude: json['alt']?.toDouble(),
      accuracy: json['accu']?.toDouble(),
      pressure: json['pressure']?.toDouble(),
    );
  }
}
