import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/map_models.dart';

/// 지도 관련 서비스 클래스
class MapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Firestore에서 리뷰 데이터를 가져와서 지도 위치로 변환
  Future<List<MapLocation>> loadReviewsFromFirestore() async {
    try {
      // reviews 컬렉션에서 실시간으로 데이터 가져오기
      final snapshot = await _firestore.collection('reviews').get();
      final List<MapLocation> locations = [];
      final Map<String, List<Review>> locationGroups = {};

      // 리뷰들을 위치별로 그룹화
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final latitude = data['latitude'] as double?;
        final longitude = data['longitude'] as double?;
        
        // 좌표가 있는 경우에만 처리
        if (latitude != null && longitude != null) {
          final locationKey = '${latitude}_${longitude}';
          
          if (!locationGroups.containsKey(locationKey)) {
            locationGroups[locationKey] = [];
          }

          locationGroups[locationKey]!.add(Review(
            id: doc.id,
            friendName: data['userEmail']?.toString().split('@')[0] ?? 'Unknown',
            photoUrl: data['imageUrl'] ?? '',
            timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            comment: data['reviewText'] ?? '',
          ));
        }
      }

      // 그룹화된 리뷰들을 MapLocation으로 변환
      locationGroups.forEach((key, reviews) {
        if (reviews.isNotEmpty) {
          final coordinates = key.split('_');
          final latitude = double.parse(coordinates[0]);
          final longitude = double.parse(coordinates[1]);
          
          // 장소 이름은 첫 번째 리뷰의 장소 이름 사용
          final placeName = reviews.first.comment?.isNotEmpty == true 
              ? reviews.first.comment!.substring(0, reviews.first.comment!.length > 10 ? 10 : reviews.first.comment!.length)
              : '리뷰된 장소';

          locations.add(MapLocation(
            id: key,
            name: placeName,
            latitude: latitude,
            longitude: longitude,
            reviews: reviews,
          ));
        }
      });

      return locations;
    } catch (e) {
      print('Firestore 리뷰 로딩 오류: $e');
      return [];
    }
  }

  /// 현재 위치 가져오기
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('현재 위치 가져오기 오류: $e');
      return null;
    }
  }

  /// 친구별 마커 색상 반환
  static double getMarkerColor(String friendName) {
    switch (friendName) {
      case '기노은':
        return BitmapDescriptor.hueRed; // 빨간색
      case '권하민':
        return BitmapDescriptor.hueBlue; // 파란색
      case '정태주':
        return BitmapDescriptor.hueGreen; // 초록색
      case '박예은':
        return BitmapDescriptor.hueYellow; // 노란색
      case '이찬민':
        return BitmapDescriptor.hueOrange; // 주황색
      case '김철수':
        return BitmapDescriptor.hueViolet; // 보라색
      case '이영희':
        return BitmapDescriptor.hueRose; // 분홍색
      case '박민수':
        return BitmapDescriptor.hueAzure; // 하늘색
      default:
        return BitmapDescriptor.hueRed; // 기본값
    }
  }

  /// Hue 값을 Color로 변환하는 헬퍼 메서드
  static Color hueToColor(double hue) {
    switch (hue.toInt()) {
      case 0: // BitmapDescriptor.hueRed
        return Colors.red;
      case 120: // BitmapDescriptor.hueGreen
        return Colors.green;
      case 240: // BitmapDescriptor.hueBlue
        return Colors.blue;
      case 60: // BitmapDescriptor.hueYellow
        return Colors.yellow;
      case 30: // BitmapDescriptor.hueOrange
        return Colors.orange;
      case 280: // BitmapDescriptor.hueViolet
        return Colors.purple;
      case 300: // BitmapDescriptor.hueRose
        return Colors.pink;
      case 210: // BitmapDescriptor.hueAzure
        return Colors.lightBlue;
      default:
        return Colors.red;
    }
  }

  /// 시간 포맷팅: "n시간 전", "n일 전"
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0) return '${difference.inDays}일 전';
    if (difference.inHours > 0) return '${difference.inHours}시간 전';
    if (difference.inMinutes > 0) return '${difference.inMinutes}분 전';
    return '방금 전';
  }

  /// 친구별 아이콘 에셋 경로 반환
  static String getFriendIconAsset(String friendName) {
    switch (friendName) {
      case '기노은':
        return 'assets/images/item1.png';
      case '권하민':
        return 'assets/images/item2.png';
      case '정태주':
        return 'assets/images/item3.png';
      case '박예은':
        return 'assets/images/item4.png';
      case '이찬민':
        return 'assets/images/item5.png';
      case '김철수':
        return 'assets/images/item6.png';
      case '이영희':
        return 'assets/images/item7.png';
      case '박민수':
        return 'assets/images/item8.png';
      default:
        return 'assets/images/item1.png';
    }
  }
}
