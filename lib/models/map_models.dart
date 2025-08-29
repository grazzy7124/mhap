import 'package:flutter/material.dart';

/// 지도에 표시할 위치 정보
class MapLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<Review> reviews;

  MapLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.reviews,
  });

  // 첫 번째 리뷰의 친구 이름 (마커 색상용)
  String get firstFriendName =>
      reviews.isNotEmpty ? reviews.first.friendName : 'Unknown';

  // 첫 번째 리뷰의 사진 URL (마커 썸네일용)
  String get firstPhotoUrl => reviews.isNotEmpty ? reviews.first.photoUrl : '';

  // 가장 최근 리뷰 시간
  DateTime get latestTimestamp => reviews.isNotEmpty
      ? reviews.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)
      : DateTime.now();
}

/// 리뷰 정보
class Review {
  final String id;
  final String friendName;
  final String photoUrl;
  final DateTime timestamp;
  final String? comment;
  final String? placeName;  // 장소 이름
  final int? rating;        // 별점 (1-5)
  final int likes;          // 좋아요 수
  final int comments;       // 댓글 수

  Review({
    required this.id,
    required this.friendName,
    required this.photoUrl,
    required this.timestamp,
    this.comment,
    this.placeName,
    this.rating,
    this.likes = 0,
    this.comments = 0,
  });
}

/// 위치 정확도 정보 클래스
class LocationAccuracyInfo {
  final double latitude;
  final double longitude;
  final double accuracy; // 미터 단위
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final bool isMocked;

  LocationAccuracyInfo({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.timestamp,
    required this.isMocked,
  });

  /// 알 수 없는 위치 정보
  factory LocationAccuracyInfo.unknown() {
    return LocationAccuracyInfo(
      latitude: 0.0,
      longitude: 0.0,
      accuracy: 0.0,
      timestamp: DateTime.now(),
      isMocked: false,
    );
  }

  /// 위도/경도를 소수점 7자리까지 포맷팅
  String get formattedLatitude => latitude.toStringAsFixed(7);
  String get formattedLongitude => longitude.toStringAsFixed(7);

  /// 정확도를 미터 단위로 포맷팅
  String get formattedAccuracy => '${accuracy.toStringAsFixed(1)}m';

  /// Mock 위치인지 확인
  bool get isRealLocation => !isMocked;

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
      'isMocked': isMocked,
    };
  }

  /// JSON에서 생성
  factory LocationAccuracyInfo.fromJson(Map<String, dynamic> json) {
    return LocationAccuracyInfo(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      accuracy: json['accuracy'].toDouble(),
      altitude: json['altitude']?.toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      isMocked: json['isMocked'] ?? false,
    );
  }
}

/// 핀 꼬리 그리드 페인터(삼각형 모양)
class PinTailPainter extends CustomPainter {
  final Color color;

  PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Apple Maps 스타일 그리드 페인터(데모)
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final dotPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    for (double x = 25; x < size.width; x += 50) {
      for (double y = 25; y < size.height; y += 50) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
