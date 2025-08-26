import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VisitedPlace {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String? description;
  final DateTime timestamp;
  final String? type; // restaurant, cafe, shopping, entertainment, landmark
  final String userId;

  VisitedPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.description,
    required this.timestamp,
    this.type,
    required this.userId,
  });

  // Firestore에서 데이터 생성
  factory VisitedPlace.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VisitedPlace(
      id: doc.id,
      name: data['name'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'],
      userId: data['userId'] ?? '',
    );
  }

  // Firestore로 데이터 변환
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'userId': userId,
    };
  }

  // LatLng 변환
  LatLng get latLng => LatLng(latitude, longitude);

  // 거리 계산 (다른 장소와의)
  double distanceTo(VisitedPlace other) {
    return _calculateDistance(latitude, longitude, other.latitude, other.longitude);
  }

  // 거리 계산 (좌표와의)
  double distanceToLatLng(LatLng latLng) {
    return _calculateDistance(latitude, longitude, latLng.latitude, latLng.longitude);
  }

  // Haversine 공식을 사용한 거리 계산
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // 지구 반지름 (km)
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // 복사본 생성
  VisitedPlace copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? description,
    DateTime? timestamp,
    String? type,
    String? userId,
  }) {
    return VisitedPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'VisitedPlace(id: $id, name: $name, lat: $latitude, lng: $longitude, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisitedPlace && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
