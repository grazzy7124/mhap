import 'dart:math';

class GPSRoute {
  final String id;
  final String name;
  final DateTime date;
  final List<GPSRoutePoint> routePoints;
  final double totalDistance;
  final Duration totalDuration;
  final List<String> photos;

  GPSRoute({
    required this.id,
    required this.name,
    required this.date,
    required this.routePoints,
    required this.totalDistance,
    required this.totalDuration,
    required this.photos,
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'routePoints': routePoints.map((point) => point.toJson()).toList(),
      'totalDistance': totalDistance,
      'totalDuration': totalDuration.inSeconds,
      'photos': photos,
    };
  }

  factory GPSRoute.fromJson(Map<String, dynamic> json) {
    return GPSRoute(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      routePoints: (json['routePoints'] as List)
          .map((point) => GPSRoutePoint.fromJson(point))
          .toList(),
      totalDistance: json['totalDistance'].toDouble(),
      totalDuration: Duration(seconds: json['totalDuration']),
      photos: List<String>.from(json['photos']),
    );
  }

  // 동선 요약 정보
  Map<String, dynamic> getSummary() {
    return {
      'name': name,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'totalDistance': totalDistance.toStringAsFixed(1),
      'totalDuration':
          '${totalDuration.inHours}시간 ${totalDuration.inMinutes % 60}분',
      'pointCount': routePoints.length,
      'photoCount': photos.length,
      'startLocation': routePoints.isNotEmpty ? routePoints.first.name : '',
      'endLocation': routePoints.isNotEmpty ? routePoints.last.name : '',
    };
  }

  // 특정 시간대의 동선 정보
  List<GPSRoutePoint> getPointsInTimeRange(DateTime start, DateTime end) {
    return routePoints.where((point) {
      return point.timestamp.isAfter(start) && point.timestamp.isBefore(end);
    }).toList();
  }

  // 특정 반경 내의 포인트들
  List<GPSRoutePoint> getPointsInRadius(
    double centerLat,
    double centerLon,
    double radiusKm,
  ) {
    return routePoints.where((point) {
      final distance = _calculateDistance(
        centerLat,
        centerLon,
        point.latitude,
        point.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  // 두 지점 간의 거리 계산 (Haversine 공식)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // 지구 반지름 (km)

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1.toRadians()) *
            cos(lat2.toRadians()) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159 / 180);
  }
}

class GPSRoutePoint {
  final double latitude;
  final double longitude;
  final String name;
  final DateTime timestamp;
  final double accuracy;
  final double altitude;
  final double speed;
  final double heading;

  GPSRoutePoint({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.timestamp,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.heading,
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
    };
  }

  factory GPSRoutePoint.fromJson(Map<String, dynamic> json) {
    return GPSRoutePoint(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      name: json['name'],
      timestamp: DateTime.parse(json['timestamp']),
      accuracy: json['accuracy'].toDouble(),
      altitude: json['altitude'].toDouble(),
      speed: json['speed'].toDouble(),
      heading: json['heading'].toDouble(),
    );
  }

  // 두 지점 간의 거리 계산
  double distanceTo(GPSRoutePoint other) {
    return GPSRoute._calculateDistance(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  // 속도 변환 (m/s -> km/h)
  double get speedKmh => speed * 3.6;

  // 방향을 한글로 표현
  String get headingDirection {
    if (heading >= 337.5 || heading < 22.5) return '북';
    if (heading >= 22.5 && heading < 67.5) return '북동';
    if (heading >= 67.5 && heading < 112.5) return '동';
    if (heading >= 112.5 && heading < 157.5) return '남동';
    if (heading >= 157.5 && heading < 202.5) return '남';
    if (heading >= 202.5 && heading < 247.5) return '남서';
    if (heading >= 247.5 && heading < 292.5) return '서';
    if (heading >= 292.5 && heading < 337.5) return '북서';
    return '북';
  }

  // 시간 포맷팅
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // 좌표를 문자열로 표현
  String get coordinates {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}

// 확장 메서드
extension DoubleExtension on double {
  double toRadians() {
    return this * (3.14159 / 180);
  }
}
