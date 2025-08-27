import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// 지도 위치 정보를 담는 데이터 클래스
class MapLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<Review> reviews; // 여러 리뷰를 저장할 리스트

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

/// 리뷰 정보를 담는 데이터 클래스
class Review {
  final String id;
  final String friendName;
  final String photoUrl;
  final DateTime timestamp;
  final String? comment; // 리뷰 코멘트 (선택사항)

  Review({
    required this.id,
    required this.friendName,
    required this.photoUrl,
    required this.timestamp,
    this.comment,
  });
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
