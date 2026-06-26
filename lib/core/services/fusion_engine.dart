import 'dart:math';
import 'package:vector_math/vector_math.dart';
import '../models/sensor_data.dart';

/// Pokročilý engine pro fúzi senzorů IMU.
/// Aktuálně implementuje Complementary Filter.
/// V budoucí verzi zde bude plný Madgwickův filtr + EKF.
class FusionEngine {
  Quaternion _orientation = Quaternion.identity();
  Vector3 _gyroBias = Vector3.zero();
  bool _isCalibrated = false;

  // Parametry Complementary Filter
  double alpha = 0.98; // vyšší = více důvěřujeme gyroskopu
  double dt = 0.02; // předpokládaný interval (50Hz)

  Quaternion get orientation => _orientation;

  /// Kalibrace gyroskopu - průměr z klidového stavu
  void calibrateGyro(List<Vector3> samples) {
    if (samples.isEmpty) return;
    _gyroBias = Vector3.zero();
    for (final g in samples) {
      _gyroBias += g;
    }
    _gyroBias /= samples.length.toDouble();
    _isCalibrated = true;
  }

  /// Hlavní metoda - aktualizuje orientaci na základě nových dat
  Quaternion update(SensorData data, {double? customDt}) {
    final deltaT = customDt ?? dt;

    // 1. Gyroskop - integrace úhlové rychlosti
    Vector3 correctedGyro = data.gyroscope - _gyroBias;

    // Převod gyro na změnu quaternionu (přibližně)
    final halfDt = deltaT / 2.0;
    final wx = correctedGyro.x;
    final wy = correctedGyro.y;
    final wz = correctedGyro.z;

    Quaternion gyroDelta = Quaternion(
      1.0,
      wx * halfDt,
      wy * halfDt,
      wz * halfDt,
    );
    gyroDelta.normalize();

    Quaternion gyroOrient = _orientation * gyroDelta;
    gyroOrient.normalize();

    // 2. Akcelerometr - odhad "dolů" (pitch + roll)
    final acc = data.accelerometer.normalized();
    final pitch = atan2(acc.y, sqrt(acc.x * acc.x + acc.z * acc.z));
    final roll = atan2(-acc.x, acc.z);

    // Převod na quaternion (zjednodušeně - bez yaw z akcelerometru)
    final accelQuat = Quaternion.fromRotation(
      Matrix3.rotationX(pitch) * Matrix3.rotationY(roll),
    );

    // 3. Complementary Filter - kombinace
    // alpha * gyro + (1-alpha) * accel (pro pitch/roll)
    // yaw zůstává primárně z gyro + magnetometr (v plné verzi)

    _orientation = Quaternion.slerp(accelQuat, gyroOrient, alpha);
    _orientation.normalize();

    return _orientation;
  }

  /// Reset orientace
  void reset() {
    _orientation = Quaternion.identity();
    _gyroBias = Vector3.zero();
    _isCalibrated = false;
  }

  /// Export aktuálního stavu pro uložení
  Map<String, dynamic> toJson() => {
        'orientation': [_orientation.x, _orientation.y, _orientation.z, _orientation.w],
        'gyroBias': [_gyroBias.x, _gyroBias.y, _gyroBias.z],
        'isCalibrated': _isCalibrated,
      };
}
