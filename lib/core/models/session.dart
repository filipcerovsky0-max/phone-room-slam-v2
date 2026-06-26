import 'package:uuid/uuid.dart';
import 'position.dart';
import 'map_grid.dart';

/// Jedna kompletní relace mapování místnosti
class MappingSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final String name;
  final List<Position> path; // celá prošlá cesta
  final MapGrid grid;
  final Map<String, dynamic> metadata; // nastavení, kalibrace atd.

  MappingSession({
    String? id,
    required this.startTime,
    this.endTime,
    required this.name,
    required this.path,
    required this.grid,
    Map<String, dynamic>? metadata,
  })  : id = id ?? const Uuid().v4(),
        metadata = metadata ?? {};

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  int get stepCount => path.length; // přibližně (každý bod = krok nebo update)

  MappingSession copyWith({
    DateTime? endTime,
    List<Position>? path,
    MapGrid? grid,
    Map<String, dynamic>? metadata,
  }) {
    return MappingSession(
      id: id,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      name: name,
      path: path ?? this.path,
      grid: grid ?? this.grid,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'name': name,
        'path': path.map((p) => p.toJson()).toList(),
        'grid': grid.toJson(),
        'metadata': metadata,
      };

  factory MappingSession.fromJson(Map<String, dynamic> json) {
    return MappingSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      name: json['name'],
      path: (json['path'] as List).map((e) => Position.fromJson(e)).toList(),
      grid: MapGrid.fromJson(json['grid']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}
