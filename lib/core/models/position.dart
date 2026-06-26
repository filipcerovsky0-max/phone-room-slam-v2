/// 3D pozice v mapě (podpora více pater domu)
class Position {
  final double x;      // východ-západ (metry)
  final double y;      // sever-jih (metry)
  final double z;      // výška (metry) - z barometru nebo AR
  final int floor;     // číslo patra (0 = přízemí, 1 = 1. patro atd.)
  final double heading; // yaw v radiánech
  final double confidence;

  const Position({
    required this.x,
    required this.y,
    this.z = 0.0,
    this.floor = 0,
    required this.heading,
    this.confidence = 1.0,
  });

  Position copyWith({
    double? x,
    double? y,
    double? z,
    int? floor,
    double? heading,
    double? confidence,
  }) {
    return Position(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      floor: floor ?? this.floor,
      heading: heading ?? this.heading,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'floor': floor,
        'heading': heading,
        'confidence': confidence,
      };

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        x: json['x'].toDouble(),
        y: json['y'].toDouble(),
        z: json['z']?.toDouble() ?? 0.0,
        floor: json['floor']?.toInt() ?? 0,
        heading: json['heading'].toDouble(),
        confidence: json['confidence']?.toDouble() ?? 1.0,
      );
}
