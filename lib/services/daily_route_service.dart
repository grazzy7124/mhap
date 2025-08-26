import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/daily_route.dart';

class DailyRouteService {
  static final DailyRouteService _instance = DailyRouteService._internal();
  factory DailyRouteService() => _instance;
  DailyRouteService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 오늘 날짜의 동선 기록
  DailyRoute? _todayRoute;

  // 동선 기록 시작
  Future<void> startDailyTracking(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    // 오늘 날짜의 기존 기록이 있는지 확인
    final existingDoc = await _firestore
        .collection('daily_routes')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: startOfDay.add(const Duration(days: 1)))
        .limit(1)
        .get();

    if (existingDoc.docs.isNotEmpty) {
      // 기존 기록이 있으면 로드
      _todayRoute = DailyRoute.fromFirestore(existingDoc.docs.first);
    } else {
      // 새로운 기록 생성
      _todayRoute = DailyRoute(
        id: '',
        userId: userId,
        date: startOfDay,
        routePoints: [],
        totalDistance: 0.0,
        totalDuration: Duration.zero,
        createdAt: DateTime.now(),
      );
    }
  }

  // 위치 포인트 추가
  Future<void> addRoutePoint(Position position) async {
    if (_todayRoute == null) return;

    final routePoint = RoutePoint(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      timestamp: position.timestamp ?? DateTime.now(),
    );

    // 거리 계산 및 업데이트
    if (_todayRoute != null && _todayRoute!.routePoints.isNotEmpty) {
      final lastPoint = _todayRoute!.routePoints.last;
      final distance = routePoint.distanceTo(lastPoint);
      _todayRoute = DailyRoute(
        id: _todayRoute!.id,
        userId: _todayRoute!.userId,
        date: _todayRoute!.date,
        routePoints: [..._todayRoute!.routePoints, routePoint],
        totalDistance: _todayRoute!.totalDistance + distance,
        totalDuration: DateTime.now().difference(
          _todayRoute!.routePoints.first.timestamp,
        ),
        createdAt: _todayRoute!.createdAt,
        updatedAt: DateTime.now(),
      );
    } else {
      // 첫 번째 포인트
      _todayRoute = DailyRoute(
        id: _todayRoute?.id ?? '',
        userId: _todayRoute?.userId ?? '',
        date: _todayRoute?.date ?? DateTime.now(),
        routePoints: [routePoint],
        totalDistance: 0.0,
        totalDuration: Duration.zero,
        createdAt: _todayRoute?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Firestore에 저장
    await _saveDailyRoute();
  }

  // 동선 기록 저장
  Future<void> _saveDailyRoute() async {
    if (_todayRoute == null) return;

    try {
      if (_todayRoute!.id.isEmpty) {
        // 새로운 기록 생성
        final docRef = await _firestore
            .collection('daily_routes')
            .add(_todayRoute!.toFirestore());
        _todayRoute = DailyRoute(
          id: docRef.id,
          userId: _todayRoute!.userId,
          date: _todayRoute!.date,
          routePoints: _todayRoute!.routePoints,
          totalDistance: _todayRoute!.totalDistance,
          totalDuration: _todayRoute!.totalDuration,
          createdAt: _todayRoute!.createdAt,
          updatedAt: _todayRoute!.updatedAt,
        );
      } else {
        // 기존 기록 업데이트
        await _firestore
            .collection('daily_routes')
            .doc(_todayRoute!.id)
            .update(_todayRoute!.toFirestore());
      }
    } catch (e) {
      print('동선 기록 저장 실패: $e');
    }
  }

  // 오늘 동선 기록 가져오기
  Future<DailyRoute?> getTodayRoute(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final doc = await _firestore
        .collection('daily_routes')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: startOfDay.add(const Duration(days: 1)))
        .limit(1)
        .get();

    if (doc.docs.isNotEmpty) {
      return DailyRoute.fromFirestore(doc.docs.first);
    }
    return null;
  }

  // 특정 날짜의 동선 기록 가져오기
  Future<DailyRoute?> getRouteByDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);

    final doc = await _firestore
        .collection('daily_routes')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: startOfDay.add(const Duration(days: 1)))
        .limit(1)
        .get();

    if (doc.docs.isNotEmpty) {
      return DailyRoute.fromFirestore(doc.docs.first);
    }
    return null;
  }

  // 사용자의 모든 동선 기록 가져오기
  Stream<QuerySnapshot> getUserRoutesStream(String userId) {
    return _firestore
        .collection('daily_routes')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // 동선 기록 삭제
  Future<void> deleteRoute(String routeId) async {
    await _firestore.collection('daily_routes').doc(routeId).delete();
  }

  // 현재 동선 정보 가져오기
  DailyRoute? get currentRoute => _todayRoute;

  // 동선 요약 정보
  Map<String, dynamic>? get currentRouteSummary => _todayRoute?.getSummary();
}
