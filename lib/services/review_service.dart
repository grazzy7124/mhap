// lib/services/review_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class ReviewService {
  ReviewService._();
  static final instance = ReviewService._();

  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  String get _uid => _auth.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> _reviewDoc(String reviewId) =>
      _fs.collection('reviews').doc(reviewId);

  /// 사진 업로드 → 다운로드 URL 반환
  Future<String> _uploadPhoto(String reviewId, File file) async {
    final ref = _storage.ref('reviews/$_uid/$reviewId/photo.jpg');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  /// 리뷰 생성 (1인1장소1리뷰) — reviewId = "{uid}_{placeId}"
  /// GPS 좌표는 GeoPoint 단일 필드로 저장 (숫자/문자열 필드 제거)
  Future<void> createReview({
    required String placeId,
    required String placeName,
    required double lat,
    required double lng,
    required int rating, // 1..5
    required String text, // <= 500
    required File photoFile,
    String? geohash, // 나중에 지도 최적화 시 사용
  }) async {
    final reviewId = '${_uid}_$placeId';
    final docRef = _reviewDoc(reviewId);

    // 사진 먼저 업로드
    final photoUrl = await _uploadPhoto(reviewId, photoFile);

    final now = FieldValue.serverTimestamp();

    await docRef.set({
      'authorId': _uid,
      'placeId': placeId,
      'placeName': placeName,

      // GeoPoint 메인 필드 (단일 저장)
      'location': GeoPoint(lat, lng),

      // 메타데이터
      'geohash': geohash,
      'rating': rating,
      'text': text,
      'photoUrl': photoUrl,
      'visibility': 'friends',
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: false));

    debugPrint('📍 리뷰 생성 완료 - GeoPoint 저장: (${lat.toStringAsFixed(7)}, ${lng.toStringAsFixed(7)})');
  }

  /// 리뷰 수정 (본문/별점/사진 교체)
  Future<void> updateReview({
    required String placeId,
    int? rating,
    String? text,
    File? newPhotoFile,
  }) async {
    final reviewId = '${_uid}_$placeId';
    final docRef = _reviewDoc(reviewId);

    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (rating != null) data['rating'] = rating;
    if (text != null) data['text'] = text;
    if (newPhotoFile != null) {
      data['photoUrl'] = await _uploadPhoto(reviewId, newPhotoFile);
    }
    await docRef.update(data);
  }

  /// 리뷰 삭제
  Future<void> deleteReview(String placeId) async {
    final reviewId = '${_uid}_$placeId';
    await _reviewDoc(reviewId).delete();
    // 스토리지 파일은 필요 시 별도 정리
    await _storage
        .ref('reviews/$_uid/$reviewId/photo.jpg')
        .delete()
        .catchError((_) {});
  }

  /// 내가 이 장소에 이미 작성했는지
  Future<bool> existsMyReview(String placeId) async {
    final reviewId = '${_uid}_$placeId';
    final snap = await _reviewDoc(reviewId).get();
    return snap.exists;
  }

  /// 장소 상세: 해당 placeId의 리뷰 최신순 (보안 규칙상 친구/본인만 내려옴)
  Query<Map<String, dynamic>> placeReviewsQuery(
    String placeId, {
    int limit = 50,
  }) {
    return _fs
        .collection('reviews')
        .where('placeId', isEqualTo: placeId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
  }

  /// 내 리뷰 히스토리 (최신순)
  Query<Map<String, dynamic>> myReviewsQuery({int limit = 50}) {
    return _fs
        .collection('reviews')
        .where('authorId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
  }

  /// 피드: 내 + 친구들의 최신 리뷰 20개 (whereIn 배치 머지)
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> feedLatest20({
    required Set<String> friendIds,
  }) async {
    final authors = [_uid, ...friendIds];
    if (authors.isEmpty) return [];

    // whereIn 제한(10~30)을 고려해 배치 분할
    const chunkSize = 10;
    final chunks = <List<String>>[];
    for (var i = 0; i < authors.length; i += chunkSize) {
      chunks.add(
        authors.sublist(
          i,
          i + chunkSize > authors.length ? authors.length : i + chunkSize,
        ),
      );
    }

    final futures = chunks.map(
      (ids) => _fs
          .collection('reviews')
          .where('authorId', whereIn: ids)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get(),
    );

    final snaps = await Future.wait(futures);
    final merged = snaps.expand((s) => s.docs).toList()
      ..sort((a, b) {
        final ta =
            (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final tb =
            (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return tb.compareTo(ta);
      });

    return merged.take(20).toList();
  }

  /// 지도: 최근 N개 가져와서 클라이언트에서 뷰포트(bbox) 필터 (MVP)
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> recentForMap({
    int limit = 500,
  }) async {
    final snap = await _fs
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs;
  }

  /// GPS 좌표 정밀도 테스트
  static Map<String, dynamic> testGPSPrecision(double lat, double lng) {
    // 다양한 정밀도로 변환하여 비교
    final original = {'lat': lat, 'lng': lng};
    final precision6 = {
      'lat': double.parse(lat.toStringAsFixed(6)),
      'lng': double.parse(lng.toStringAsFixed(6)),
    };
    final precision7 = {
      'lat': double.parse(lat.toStringAsFixed(7)),
      'lng': double.parse(lng.toStringAsFixed(7)),
    };
    final precision8 = {
      'lat': double.parse(lat.toStringAsFixed(8)),
      'lng': double.parse(lng.toStringAsFixed(8)),
    };

    // 문자열로 변환 (정밀도 보존)
    final string6 = {
      'lat': lat.toStringAsFixed(6),
      'lng': lng.toStringAsFixed(6),
    };
    final string7 = {
      'lat': lat.toStringAsFixed(7),
      'lng': lng.toStringAsFixed(7),
    };
    final string8 = {
      'lat': lat.toStringAsFixed(8),
      'lng': lng.toStringAsFixed(8),
    };

    // 정밀도 손실 계산
    final loss6 = {
      'lat': (lat - precision6['lat']!).abs(),
      'lng': (lng - precision6['lng']!).abs(),
    };
    final loss7 = {
      'lat': (lat - precision7['lat']!).abs(),
      'lng': (lng - precision7['lng']!).abs(),
    };
    final loss8 = {
      'lat': (lat - precision8['lat']!).abs(),
      'lng': (lng - precision8['lng']!).abs(),
    };

    return {
      'original': original,
      'precision6': precision6,
      'precision7': precision7,
      'precision8': precision8,
      'string6': string6,
      'string7': string7,
      'string8': string8,
      'precision_loss': {
        '6_decimal': loss6,
        '7_decimal': loss7,
        '8_decimal': loss8,
      },
      'recommendation': 'Use string7 for maximum precision preservation',
    };
  }

  /// GPS 좌표 검증 (저장 전후 비교)
  static bool validateGPSPrecision({
    required double originalLat,
    required double originalLng,
    required double storedLat,
    required double storedLng,
    double tolerance = 0.0000001, // 소수점 7자리 기준
  }) {
    final latDiff = (originalLat - storedLat).abs();
    final lngDiff = (originalLng - storedLng).abs();

    final isValid = latDiff <= tolerance && lngDiff <= tolerance;

    if (!isValid) {
      debugPrint('⚠️ GPS 정밀도 검증 실패:');
      debugPrint('   위도 차이: $latDiff (허용치: $tolerance)');
      debugPrint('   경도 차이: $lngDiff (허용치: $tolerance)');
    }

    return isValid;
  }

  /// 문자열 기반 GPS 정밀도 검증
  static bool validateStringPrecision(
    double originalLat,
    double originalLng,
    String storedLatString,
    String storedLngString,
  ) {
    final storedLat = double.parse(storedLatString);
    final storedLng = double.parse(storedLngString);

    final isValid = validateGPSPrecision(
      originalLat: originalLat,
      originalLng: originalLng,
      storedLat: storedLat,
      storedLng: storedLng,
    );

    if (!isValid) {
      debugPrint('⚠️ 문자열 기반 GPS 정밀도 검증 실패:');
      debugPrint('   원본 위도: $originalLat, 저장된 위도: $storedLatString');
      debugPrint('   원본 경도: $originalLng, 저장된 경도: $storedLngString');
    }

    return isValid;
  }

  /// 🔥 핵심: GeoPoint에서 GPS 좌표를 정밀도 손실 없이 읽어오기
  static Map<String, dynamic> getPreciseGPSFromDocument(Map<String, dynamic> docData) {
    // 우선순위: GeoPoint(location) > 기존 loc > 문자열 > double
    final GeoPoint? location = docData['location'] as GeoPoint?;
    if (location != null) {
      return {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'latitudeString': location.latitude.toStringAsFixed(7),
        'longitudeString': location.longitude.toStringAsFixed(7),
        'precision': 'geopoint_location',
        'accuracy': 'perfect',
        'source': 'location (GeoPoint)'
      };
    }

    final GeoPoint? legacyLoc = docData['loc'] as GeoPoint?;
    if (legacyLoc != null) {
      return {
        'latitude': legacyLoc.latitude,
        'longitude': legacyLoc.longitude,
        'latitudeString': legacyLoc.latitude.toStringAsFixed(7),
        'longitudeString': legacyLoc.longitude.toStringAsFixed(7),
        'precision': 'geopoint_loc',
        'accuracy': 'standard',
        'source': 'loc (legacy)'
      };
    }

    final String? latString = docData['latitudeString'] as String?;
    final String? lngString = docData['longitudeString'] as String?;
    if (latString != null && lngString != null) {
      return {
        'latitude': double.parse(latString),
        'longitude': double.parse(lngString),
        'latitudeString': latString,
        'longitudeString': lngString,
        'precision': 'string_7_decimal',
        'accuracy': 'high',
        'source': 'latitudeString/longitudeString',
      };
    }

    final double? latDouble = (docData['latitude'] as num?)?.toDouble();
    final double? lngDouble = (docData['longitude'] as num?)?.toDouble();
    if (latDouble != null && lngDouble != null) {
      return {
        'latitude': latDouble,
        'longitude': lngDouble,
        'latitudeString': latDouble.toStringAsFixed(7),
        'longitudeString': lngDouble.toStringAsFixed(7),
        'precision': 'double_7_decimal',
        'accuracy': 'standard',
        'source': 'latitude/longitude',
      };
    }

    // GPS 정보 없음
    return {
      'latitude': 0.0,
      'longitude': 0.0,
      'latitudeString': '0.0000000',
      'longitudeString': '0.0000000',
      'precision': 'none',
      'accuracy': 'unknown',
      'source': 'none',
    };
  }

  /// GPS 좌표를 문자열로 변환 (정밀도 보존)
  static Map<String, String> convertGPSToStrings(
    double lat,
    double lng, {
    int decimalPlaces = 7,
  }) {
    return {
      'latitude': lat.toStringAsFixed(decimalPlaces),
      'longitude': lng.toStringAsFixed(decimalPlaces),
    };
  }

  /// 문자열 GPS를 double로 변환 (정밀도 검증)
  static Map<String, dynamic> convertStringGPSToDouble(
    String latString,
    String lngString,
  ) {
    try {
      final lat = double.parse(latString);
      final lng = double.parse(lngString);

      // 변환 후 정밀도 검증
      final latBackToString = lat.toStringAsFixed(7);
      final lngBackToString = lng.toStringAsFixed(7);

      final isPrecise =
          latString == latBackToString && lngString == lngBackToString;

      return {
        'latitude': lat,
        'longitude': lng,
        'isPrecise': isPrecise,
        'precision': isPrecise ? 'perfect' : 'degraded',
        'originalStrings': {'lat': latString, 'lng': lngString},
        'convertedStrings': {'lat': latBackToString, 'lng': lngBackToString},
      };
    } catch (e) {
      return {
        'latitude': 0.0,
        'longitude': 0.0,
        'isPrecise': false,
        'precision': 'error',
        'error': e.toString(),
      };
    }
  }
}
