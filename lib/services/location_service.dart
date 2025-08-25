import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stream_transform/stream_transform.dart';

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
  void _onLocationError(LocationSettingsException error) {
    print('위치 추적 에러: $error');
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
}
