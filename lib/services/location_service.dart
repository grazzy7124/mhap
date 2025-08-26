import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _locationSubscription;
  bool _isTracking = false;

  // 위치 추적 간격 (초)
  static const int _locationUpdateInterval = 10;

  // 마지막으로 저장된 위치
  Position? _lastSavedPosition;

  // 위치 추적 시작
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    // 권한 확인
    if (!await _checkPermissions()) {
      return false;
    }

    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // 위치 추적 시작
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // 10미터마다 업데이트
          timeLimit: Duration(seconds: _locationUpdateInterval),
        ),
      ).listen(_onLocationUpdate, onError: _onLocationError);

      _isTracking = true;
      return true;
    } catch (e) {
      print('위치 추적 시작 실패: $e');
      return false;
    }
  }

  // 위치 추적 중지
  void stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
  }

  // 권한 확인
  Future<bool> _checkPermissions() async {
    // 위치 권한 확인
    PermissionStatus locationStatus = await Permission.location.status;

    if (locationStatus.isDenied) {
      locationStatus = await Permission.location.request();
    }

    if (locationStatus.isPermanentlyDenied) {
      return false;
    }

    // 백그라운드 위치 권한 확인 (Android)
    if (locationStatus.isGranted) {
      PermissionStatus backgroundStatus =
          await Permission.locationAlways.status;
      if (backgroundStatus.isDenied) {
        backgroundStatus = await Permission.locationAlways.request();
      }
    }

    return locationStatus.isGranted;
  }

  // 위치 업데이트 콜백
  void _onLocationUpdate(Position position) {
    _saveLocationToFirebase(position);
  }

  // 위치 에러 콜백
  void _onLocationError(Object error) {
    print('위치 추적 에러: $error');
    if (error is PermissionDeniedException) {
      // 권한 안내
    } else if (error is LocationServiceDisabledException) {
      // 위치 서비스 안내
    }
  }

  // Firebase에 위치 저장
  Future<void> _saveLocationToFirebase(Position position) async {
    try {
      // 마지막 저장 위치와 비교하여 의미있는 이동이 있는지 확인
      if (_lastSavedPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastSavedPosition!.latitude,
          _lastSavedPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // 10미터 이상 이동했을 때만 저장
        if (distance < 10) {
          return;
        }
      }

      // Firestore에 위치 데이터 저장
      await _firestore.collection('location_tracks').add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': FieldValue.serverTimestamp(),
        'device_id': await _getDeviceId(),
      });

      _lastSavedPosition = position;
      print('위치 저장 완료: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('위치 저장 실패: $e');
    }
  }

  // 디바이스 ID 가져오기 (간단한 구현)
  Future<String> _getDeviceId() async {
    // 실제 구현에서는 고유한 디바이스 ID를 사용해야 합니다
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  // 디바이스 ID 가져오기 (public 메서드)
  Future<String> getDeviceId() async {
    return await _getDeviceId();
  }

  // 현재 위치 가져오기
  Future<Position?> getCurrentLocation() async {
    try {
      if (!await _checkPermissions()) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('현재 위치 가져오기 실패: $e');
      return null;
    }
  }

  // 추적 상태 확인
  bool get isTracking => _isTracking;

  // 위치 권한 상태 확인
  Future<bool> get hasLocationPermission async {
    return await _checkPermissions();
  }

  // 위치 서비스 활성화 상태 확인
  Future<bool> get isLocationServiceEnabled async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // 위치 스트림 가져오기 (현재 추적 중인 스트림)
  Stream<Position>? get getPositionStream {
    if (_locationSubscription != null) {
      // 새로운 위치 스트림 생성
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    }
    return null;
  }

  // Firestore에서 위치 추적 데이터를 실시간으로 가져오는 스트림
  Stream<QuerySnapshot> getLocationTracksStream() {
    return _firestore
        .collection('location_tracks')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 특정 디바이스의 위치 추적 데이터를 실시간으로 가져오는 스트림
  Stream<QuerySnapshot> getDeviceLocationTracksStream(String deviceId) {
    return _firestore
        .collection('location_tracks')
        .where('device_id', isEqualTo: deviceId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 위치 추적 데이터를 날짜별로 필터링하여 가져오는 스트림
  Stream<QuerySnapshot> getLocationTracksByDateStream(DateTime date) {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('location_tracks')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 위치 추적 데이터 추가
  Future<void> addLocationTrack(Map<String, dynamic> locationData) async {
    try {
      await _firestore.collection('location_tracks').add({
        ...locationData,
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });
      print('위치 추적 데이터 추가 완료');
    } catch (e) {
      print('위치 추적 데이터 추가 실패: $e');
      rethrow;
    }
  }

  // 위치 추적 데이터 삭제
  Future<void> deleteLocationTrack(String documentId) async {
    try {
      await _firestore.collection('location_tracks').doc(documentId).delete();
      print('위치 추적 데이터 삭제 완료');
    } catch (e) {
      print('위치 추적 데이터 삭제 실패: $e');
      rethrow;
    }
  }

  // 위치 추적 데이터 업데이트
  Future<void> updateLocationTrack(
    String documentId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _firestore.collection('location_tracks').doc(documentId).update({
        ...updateData,
        'updated_at': FieldValue.serverTimestamp(),
      });
      print('위치 추적 데이터 업데이트 완료');
    } catch (e) {
      print('위치 추적 데이터 업데이트 실패: $e');
      rethrow;
    }
  }

  // 위치 추적 데이터 일괄 삭제 (특정 디바이스)
  Future<void> deleteDeviceLocationTracks(String deviceId) async {
    try {
      final querySnapshot = await _firestore
          .collection('location_tracks')
          .where('device_id', isEqualTo: deviceId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('디바이스 위치 추적 데이터 일괄 삭제 완료');
    } catch (e) {
      print('디바이스 위치 추적 데이터 일괄 삭제 실패: $e');
      rethrow;
    }
  }

  // 위치 추적 데이터 일괄 삭제 (특정 날짜 범위)
  Future<void> deleteLocationTracksByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('location_tracks')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThan: endDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('날짜 범위 위치 추적 데이터 일괄 삭제 완료');
    } catch (e) {
      print('날짜 범위 위치 추적 데이터 일괄 삭제 실패: $e');
      rethrow;
    }
  }
}
