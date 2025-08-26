import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapService {
  // 서울 중심 좌표
  static const LatLng seoulCenter = LatLng(37.5665, 126.9780);
  
  // 서울 지역 경계
  static const double minLat = 37.4;
  static const double maxLat = 37.7;
  static const double minLng = 126.5;
  static const double maxLng = 127.2;

  // 기본 카메라 위치
  static CameraPosition get defaultCameraPosition => const CameraPosition(
    target: seoulCenter,
    zoom: 12.0,
  );

  // 서울 지역으로 제한된 카메라 위치
  static CameraPosition getCameraPositionForLocation(LatLng location) {
    return CameraPosition(
      target: location,
      zoom: 15.0,
    );
  }

  // 서울 지역 내 좌표인지 확인
  static bool isInSeoulArea(LatLng location) {
    return location.latitude >= minLat &&
           location.latitude <= maxLat &&
           location.longitude >= minLng &&
           location.longitude <= maxLng;
  }

  // 현재 위치 가져오기
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('위치 가져오기 오류: $e');
      return null;
    }
  }

  // 두 지점 간 거리 계산 (km)
  static double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    ) / 1000; // 미터를 킬로미터로 변환
  }

  // 마커 아이콘 생성
  static BitmapDescriptor createMarkerIcon({
    required String title,
    Color color = Colors.red,
  }) {
    return BitmapDescriptor.defaultMarkerWithHue(
      color == Colors.red ? BitmapDescriptor.hueRed :
      color == Colors.green ? BitmapDescriptor.hueGreen :
      color == Colors.blue ? BitmapDescriptor.hueBlue :
      BitmapDescriptor.hueRed,
    );
  }

  // 커스텀 마커 아이콘 (색상별)
  static BitmapDescriptor getCustomMarkerIcon(String type) {
    switch (type) {
      case 'restaurant':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'cafe':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'shopping':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'entertainment':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'landmark':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }
}
