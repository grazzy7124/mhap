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

        // 🔥 핵심: GeoPoint 기반 GPS 좌표 우선 사용 (Firestore 권장)
        double? latitude;
        double? longitude;

        // 1순위: GeoPoint 기반 GPS (Firestore 권장 방식)
        final geoPoint = data['location'] as GeoPoint?;
        if (geoPoint != null) {
          latitude = geoPoint.latitude;
          longitude = geoPoint.longitude;
          debugPrint(
            '📍 GeoPoint 기반 GPS 사용: ${latitude.toStringAsFixed(7)}, ${longitude.toStringAsFixed(7)}',
          );
        }

        // 2순위: 문자열 기반 GPS (정밀도 보존용)
        if (latitude == null || longitude == null) {
          final latString = data['latitudeString'] as String?;
          final lngString = data['longitudeString'] as String?;
          if (latString != null && lngString != null) {
            latitude = double.parse(latString);
            longitude = double.parse(lngString);
            debugPrint('📍 문자열 기반 GPS 사용: $latString, $lngString');
          }
        }

        // 3순위: double 기반 GPS (호환성)
        if (latitude == null || longitude == null) {
          latitude = data['latitude'] as double?;
          longitude = data['longitude'] as double?;
          if (latitude != null && longitude != null) {
            debugPrint('📍 double 기반 GPS 사용: $latitude, $longitude');
          }
        }

        // 4순위: 기존 loc 필드 (레거시 호환성)
        if (latitude == null || longitude == null) {
          final oldGeoPoint = data['loc'] as GeoPoint?;
          if (oldGeoPoint != null) {
            latitude = oldGeoPoint.latitude;
            longitude = oldGeoPoint.longitude;
            debugPrint('📍 기존 loc 필드 GPS 사용: $latitude, $longitude');
          }
        }

        // 좌표가 있는 경우에만 처리
        if (latitude != null && longitude != null) {
          // 정밀도가 높은 좌표를 위한 더 세밀한 그룹화
          final locationKey =
              '${latitude.toStringAsFixed(7)}_${longitude.toStringAsFixed(7)}';

          if (!locationGroups.containsKey(locationKey)) {
            locationGroups[locationKey] = [];
          }

          // 이미지 URL 추출 및 검증
          String? photoUrl;
          if (data['imageUrl'] != null) {
            photoUrl = data['imageUrl'] as String;
            debugPrint('🖼️ 이미지 URL 확인: $photoUrl (문서: ${doc.id})');

            // Firebase Storage URL인지 확인
            if (photoUrl.startsWith(
              'https://firebasestorage.googleapis.com/',
            )) {
              debugPrint('✅ Firebase Storage URL 확인됨');
            } else if (photoUrl.startsWith('/var/mobile/') ||
                photoUrl.startsWith('/data/') ||
                photoUrl.startsWith('/Documents/')) {
              debugPrint('📱 로컬 파일 경로 감지됨: $photoUrl');
              // 로컬 경로는 그대로 사용 (이제 로컬에서도 표시 가능)
              debugPrint('💾 로컬 이미지 사용: $photoUrl');
            } else if (photoUrl.startsWith('http')) {
              debugPrint('✅ 외부 URL 확인됨: $photoUrl');
            } else if (photoUrl.isNotEmpty) {
              debugPrint('⚠️ 알 수 없는 URL 형식: $photoUrl');
              // URL이 유효하지 않으면 빈 문자열로 처리
              photoUrl = '';
            } else {
              debugPrint('⚠️ 빈 이미지 URL');
              photoUrl = '';
            }
          } else if (data['photoUrl'] != null) {
            photoUrl = data['photoUrl'] as String;
            debugPrint('🖼️ photoUrl 필드 확인: $photoUrl (문서: ${doc.id})');
          } else {
            debugPrint('⚠️ 이미지 URL이 없음 (문서: ${doc.id})');
            photoUrl = ''; // 빈 문자열로 설정
          }

          locationGroups[locationKey]!.add(
            Review(
              id: doc.id,
              friendName:
                  data['userName'] ?? // ReviewFormScreen에서 저장하는 필드명
                  data['userEmail']?.toString().split('@')[0] ?? // 실제 저장되는 필드
                  data['authorId']?.toString().split('@')[0] ??
                  'Unknown',
              photoUrl: photoUrl ?? '', // null 안전 처리
              timestamp:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? // 실제 저장되는 필드
                  (data['timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              comment:
                  data['review'] ?? // ReviewFormScreen에서 저장하는 필드명
                  data['text'] ??
                  data['reviewText'] ??
                  '', // 리뷰 텍스트 필드명 통합
              placeName: data['placeName'] as String?, // 장소 이름
              rating: data['rating'] as int?, // 별점
              likes: data['likes'] as int? ?? 0, // 좋아요 수
              comments: data['comments'] as int? ?? 0, // 댓글 수
            ),
          );
        } else {
          debugPrint('⚠️ GPS 좌표 없음: ${doc.id}');
        }
      }

      // 그룹화된 리뷰들을 MapLocation으로 변환
      locationGroups.forEach((key, reviews) {
        if (reviews.isNotEmpty) {
          final coordinates = key.split('_');
          final latitude = double.parse(coordinates[0]);
          final longitude = double.parse(coordinates[1]);

          // 장소 이름은 첫 번째 리뷰의 장소 이름 사용 (우선순위: placeName > comment > 기본값)
          final placeName =
              reviews.first.placeName ??
              (reviews.first.comment?.isNotEmpty == true
                  ? reviews.first.comment!.substring(
                      0,
                      reviews.first.comment!.length > 10
                          ? 10
                          : reviews.first.comment!.length,
                    )
                  : '리뷰된 장소');

          locations.add(
            MapLocation(
              id: key,
              name: placeName,
              latitude: latitude,
              longitude: longitude,
              reviews: reviews,
            ),
          );

          debugPrint(
            '📍 마커 생성: $placeName (${latitude.toStringAsFixed(7)}, ${longitude.toStringAsFixed(7)}) - ${reviews.length}개 리뷰',
          );
        }
      });

      debugPrint('📍 총 ${locations.length}개 마커 생성 완료');
      return locations;
    } catch (e) {
      print('Firestore 리뷰 로딩 오류: $e');
      return [];
    }
  }

  /// 기존 문서에 GeoPoint `location` 필드를 백필(마이그레이션)
  /// - 우선순위: location 있으면 skip → latitudeString/longitudeString → latitude/longitude → loc
  Future<int> migrateReviewsToGeoPoint() async {
    int updated = 0;
    try {
      final snap = await _firestore.collection('reviews').get();
      for (final doc in snap.docs) {
        final data = doc.data();
        // 이미 location이 있으면 건너뜀
        if (data.containsKey('location') && data['location'] is GeoPoint) {
          continue;
        }

        double? lat;
        double? lng;

        // 문자열 기반
        final latStr = data['latitudeString'] as String?;
        final lngStr = data['longitudeString'] as String?;
        if (latStr != null && lngStr != null) {
          lat = double.tryParse(latStr);
          lng = double.tryParse(lngStr);
        }

        // number 기반
        lat ??= (data['latitude'] as num?)?.toDouble();
        lng ??= (data['longitude'] as num?)?.toDouble();

        // 레거시 loc 기반
        if (lat == null || lng == null) {
          final old = data['loc'];
          if (old is GeoPoint) {
            lat = old.latitude;
            lng = old.longitude;
          }
        }

        if (lat == null || lng == null) {
          debugPrint('⚠️ 위치 백필 불가: ${doc.id}');
          continue;
        }

        await doc.reference.update({'location': GeoPoint(lat, lng)});
        updated += 1;
      }
      debugPrint('✅ GeoPoint 백필 완료: $updated건 업데이트');
    } catch (e) {
      debugPrint('❌ GeoPoint 백필 실패: $e');
    }
    return updated;
  }

  /// 현재 위치 가져오기 (최고 정확도)
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

      // 최고 정확도로 위치 가져오기 (소수점 7자리까지)
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation, // 최고 정확도
        timeLimit: const Duration(seconds: 15), // 더 긴 대기 시간
        forceAndroidLocationManager: false, // Android에서 최신 위치 서비스 사용
      );
    } catch (e) {
      print('현재 위치 가져오기 오류: $e');
      return null;
    }
  }

  /// 연속 위치 추적 (실시간 업데이트)
  Stream<Position> getLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // 최고 정확도
      distanceFilter: 1, // 1미터마다 업데이트
      timeLimit: Duration(seconds: 10),
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// 위치 정확도 정보 반환
  Future<LocationAccuracyInfo> getLocationAccuracyInfo() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return LocationAccuracyInfo.unknown();

      return LocationAccuracyInfo(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
        isMocked: position.isMocked,
      );
    } catch (e) {
      print('위치 정확도 정보 가져오기 오류: $e');
      return LocationAccuracyInfo.unknown();
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
