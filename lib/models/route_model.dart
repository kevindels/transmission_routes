import 'package:latlong2/latlong.dart';
import 'route_point_model.dart';

class RouteModel {
  final String id;
  final String streamId;
  final String userId;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final List<RoutePointModel> points;
  final double totalDistance;
  final double averageSpeed;
  final double maxSpeed;
  final bool powerSavingModeUsed;

  RouteModel({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.name,
    required this.startTime,
    this.endTime,
    required this.points,
    required this.totalDistance,
    required this.averageSpeed,
    required this.maxSpeed,
    this.powerSavingModeUsed = false,
  });

  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  List<LatLng> get polylinePoints {
    return points.map((p) => p.latLng).toList();
  }

  int get pointsCount => points.length;

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String,
      streamId: json['streamId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      points: (json['points'] as List<dynamic>)
          .map((p) => RoutePointModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      totalDistance: (json['totalDistance'] as num).toDouble(),
      averageSpeed: (json['averageSpeed'] as num).toDouble(),
      maxSpeed: (json['maxSpeed'] as num).toDouble(),
      powerSavingModeUsed: json['powerSavingModeUsed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'streamId': streamId,
      'userId': userId,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'points': points.map((p) => p.toJson()).toList(),
      'totalDistance': totalDistance,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'powerSavingModeUsed': powerSavingModeUsed,
    };
  }
}
