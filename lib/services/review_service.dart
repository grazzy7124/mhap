// lib/services/review_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
      'loc': GeoPoint(lat, lng),
      'geohash': geohash,
      'rating': rating,
      'text': text,
      'photoUrl': photoUrl,
      'visibility': 'friends',
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: false)); // 중복 생성 시 rules에서 차단됨
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
    await _storage.ref('reviews/$_uid/$reviewId/photo.jpg').delete().catchError((_) {});
  }

  /// 내가 이 장소에 이미 작성했는지
  Future<bool> existsMyReview(String placeId) async {
    final reviewId = '${_uid}_$placeId';
    final snap = await _reviewDoc(reviewId).get();
    return snap.exists;
  }

  /// 장소 상세: 해당 placeId의 리뷰 최신순 (보안 규칙상 친구/본인만 내려옴)
  Query<Map<String, dynamic>> placeReviewsQuery(String placeId, {int limit = 50}) {
    return _fs.collection('reviews')
        .where('placeId', isEqualTo: placeId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
  }

  /// 내 리뷰 히스토리 (최신순)
  Query<Map<String, dynamic>> myReviewsQuery({int limit = 50}) {
    return _fs.collection('reviews')
        .where('authorId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
  }

  /// 피드: 내 + 친구들의 최신 리뷰 20개 (whereIn 배치 머지)
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> feedLatest20(
      {required Set<String> friendIds}) async {
    final authors = [_uid, ...friendIds];
    if (authors.isEmpty) return [];

    // whereIn 제한(10~30)을 고려해 배치 분할
    const chunkSize = 10;
    final chunks = <List<String>>[];
    for (var i = 0; i < authors.length; i += chunkSize) {
      chunks.add(authors.sublist(i, i + chunkSize > authors.length ? authors.length : i + chunkSize));
    }

    final futures = chunks.map((ids) => _fs.collection('reviews')
        .where('authorId', whereIn: ids)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get());

    final snaps = await Future.wait(futures);
    final merged = snaps.expand((s) => s.docs).toList()
      ..sort((a, b) {
        final ta = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final tb = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return tb.compareTo(ta);
      });

    return merged.take(20).toList();
  }

  /// 지도: 최근 N개 가져와서 클라이언트에서 뷰포트(bbox) 필터 (MVP)
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> recentForMap({int limit = 500}) async {
    final snap = await _fs.collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs;
  }
}
