import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class DailyRoute {
  final String id;
  final String userId;
  final DateTime date;
  final List<RoutePoint> routePoints;
  final double totalDistance;
  final Duration totalDuration;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DailyRoute({
    required this.id,
    required this.userId,
    required this.date,
    required this.routePoints,
    required this.totalDistance,
    required this.totalDuration,
    required this.createdAt,
    this.updatedAt,
  });

  // Firestore에서 데이터를 가져올 때 사용
  factory DailyRoute.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    List<RoutePoint> points = [];
    if (data['routePoints'] != null) {
      points = (data['routePoints'] as List)
          .map((point) => RoutePoint.fromMap(point))
          .toList();
    }

    return DailyRoute(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      routePoints: points,
      totalDistance: (data['totalDistance'] ?? 0.0).toDouble(),
      totalDuration: Duration(seconds: data['totalDurationSeconds'] ?? 0),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Firestore에 저장할 때 사용
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'routePoints': routePoints.map((point) => point.toMap()).toList(),
      'totalDistance': totalDistance,
      'totalDurationSeconds': totalDuration.inSeconds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // 동선 요약 정보
  Map<String, dynamic> getSummary() {
    return {
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'totalDistance': totalDistance,
      'totalDuration': '${totalDuration.inHours}시간 ${totalDuration.inMinutes % 60}분',
      'pointCount': routePoints.length,
      'startTime': routePoints.isNotEmpty ? routePoints.first.timestamp : null,
      'endTime': routePoints.isNotEmpty ? routePoints.last.timestamp : null,
    };
  }
}

class RoutePoint {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  factory RoutePoint.fromMap(Map<String, dynamic> map) {
    return RoutePoint(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      accuracy: map['accuracy']?.toDouble(),
      altitude: map['altitude']?.toDouble(),
      speed: map['speed']?.toDouble(),
      heading: map['heading']?.toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // 두 지점 간의 거리 계산
  double distanceTo(RoutePoint other) {
    return Geolocator.distanceBetween(
      latitude, longitude,
      other.latitude, other.longitude,
    );
  }
}
