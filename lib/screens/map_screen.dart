import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/map_models.dart';
import '../services/map_service.dart';
import '../widgets/map_widgets.dart';

/// 지도 화면(MapScreen)
///
/// Google Maps를 이용해 사용자/친구 위치를 마커로 표시하고,
/// 사진 썸네일/정보 오버레이, 현재 위치 이동/확대/축소 등 지도를 제어합니다.
///
/// 제스처 충돌 방지:
/// - 상위 PageView와의 충돌을 막기 위해 gestureRecognizers(EagerGestureRecognizer) 사용
/// - GoogleMap의 줌/스크롤/회전/틸트 제스처 명시적 활성화
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController; // Google Maps 컨트롤러

  // 현재 위치 관련 상태
  Position? _currentPosition; // 현재 GPS 위치
  bool _isLocationLoading = false; // 위치 로딩 상태

  // 커스텀 마커 이미지들
  Map<String, BitmapDescriptor> _customMarkers = {};
  Map<String, GlobalKey> _markerKeys = {}; // 마커 위젯의 키를 저장할 맵

  // Firestore 관련 상태
  final MapService _mapService = MapService();
  List<MapLocation> _firestoreLocations = []; // Firestore에서 가져온 리뷰 위치들
  bool _isLoadingReviews = false;

  // 더미 데이터 (Firestore에 데이터가 없을 때 사용)
  final List<MapLocation> _dummyLocations = [
    MapLocation(
      id: 'dummy1',
      name: '포항 해변 카페',
      latitude: 36.081489,
      longitude: 129.395523,
      reviews: [
        Review(
          id: 'review1',
          friendName: '기노은',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          photoUrl: 'https://via.placeholder.com/150',
          comment: '바다가 보이는 아름다운 카페예요! ☕',
        ),
        Review(
          id: 'review2',
          friendName: '권하민',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          photoUrl: 'https://via.placeholder.com/150',
          comment: '커피 맛있고 분위기 좋아요 🌊',
        ),
      ],
    ),
    MapLocation(
      id: 'dummy2',
      name: '포항 맛집 거리',
      latitude: 36.075489,
      longitude: 129.385523,
      reviews: [
        Review(
          id: 'review3',
          friendName: '정태주',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          photoUrl: 'https://via.placeholder.com/150',
          comment: '신선한 해산물이 정말 맛있어요 🦐',
        ),
      ],
    ),
    MapLocation(
      id: 'dummy3',
      name: '포항 공원',
      latitude: 36.085489,
      longitude: 129.405523,
      reviews: [
        Review(
          id: 'review4',
          friendName: '박예은',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          photoUrl: 'https://via.placeholder.com/150',
          comment: '산책하기 좋은 공원이에요 🌳',
        ),
        Review(
          id: 'review5',
          friendName: '이찬민',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          photoUrl: 'https://via.placeholder.com/150',
          comment: '아이들과 놀기 좋아요 🎈',
        ),
      ],
    ),
    MapLocation(
      id: 'dummy4',
      name: '포항 전망대',
      latitude: 36.070489,
      longitude: 129.390523,
      reviews: [
        Review(
          id: 'review6',
          friendName: '기노은',
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          photoUrl: 'https://via.placeholder.com/150',
          comment: '포항 시내가 한눈에 보여요 🏙️',
        ),
      ],
    ),
    MapLocation(
      id: 'dummy5',
      name: '포항 해변',
      latitude: 36.078489,
      longitude: 129.400523,
      reviews: [
        Review(
          id: 'review7',
          friendName: '권하민',
          timestamp: DateTime.now().subtract(const Duration(hours: 7)),
          photoUrl: 'https://via.placeholder.com/150',
          comment: '일몰이 정말 아름다워요 🌅',
        ),
      ],
    ),
  ];

  // 지도 설정: 초기 카메라 위치(포항)
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(36.081489, 129.395523), // 포항 시내 중심
    zoom: 13.0,
  );

  // 친구 필터링 상태
  String _selectedFriend = 'all'; // 'all'은 전체
  final List<String> _friends = ['all', '기노은', '권하민', '정태주', '박예은', '이찬민'];

  @override
  void initState() {
    super.initState();
    // 마커 키들 초기화
    _initializeMarkerKeys();
    // 시작 시 현재 위치를 가져와 카메라를 이동
    _getCurrentLocation();
    // Firestore에서 리뷰 데이터 가져오기
    _loadReviewsFromFirestore();
  }

  /// 마커 키들 초기화
  void _initializeMarkerKeys() {
    final friends = ['기노은', '권하민', '정태주', '박예은', '이찬민', '김철수', '이영희', '박민수'];
    for (final friend in friends) {
      _markerKeys[friend] = GlobalKey();
    }

    // 빌드 완료 후 마커 이미지 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateMarkerBitmaps();
    });
  }

  /// 마커 위젯을 비트맵으로 변환하여 저장
  Future<void> _generateMarkerBitmaps() async {
    try {
      for (final entry in _markerKeys.entries) {
        final friendName = entry.key;
        final key = entry.value;

        // 위젯이 렌더링될 때까지 잠시 대기
        await Future.delayed(const Duration(milliseconds: 100));

        // 위젯을 비트맵으로 변환
        final bitmap = await _widgetToBitmap(key);
        if (bitmap != null) {
          _customMarkers[friendName] = bitmap;
        }
      }

      // 마커 업데이트
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('마커 비트맵 생성 오류: $e');
    }
  }

  /// 위젯을 비트맵 이미지로 변환
  Future<BitmapDescriptor?> _widgetToBitmap(GlobalKey key) async {
    try {
      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return null;

      return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('위젯을 비트맵으로 변환 오류: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // 지도 컨트롤러 정리
    _mapController?.dispose();
    super.dispose();
  }

  /// Firestore에서 리뷰 데이터를 가져와서 지도 위치로 변환
  Future<void> _loadReviewsFromFirestore() async {
    try {
      setState(() {
        _isLoadingReviews = true;
      });

      final locations = await _mapService.loadReviewsFromFirestore();
      
      setState(() {
        _firestoreLocations = locations;
        _isLoadingReviews = false;
      });
    } catch (e) {
      print('Firestore 리뷰 로딩 오류: $e');
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  /// 현재 위치 1회 조회 → 카메라 이동
  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLocationLoading = true;
      });

      final position = await _mapService.getCurrentLocation();
      
      setState(() {
        _currentPosition = position;
        _isLocationLoading = false;
      });

      // 지도 준비된 경우 현재 위치로 이동
      if (position != null) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('현재 위치 가져오기 오류: $e');
      setState(() => _isLocationLoading = false);
    }
  }

  /// 지도 생성 콜백: 컨트롤러 저장 + 현재 위치 이동
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  /// 친구 필터 적용된 위치 목록 반환 (하이브리드 방식)
  List<MapLocation> _getFilteredLocations() {
    // Firestore에 데이터가 있으면 사용, 없으면 목데이터 사용
    final locations = _firestoreLocations.isNotEmpty ? _firestoreLocations : _dummyLocations;
    
    if (_selectedFriend == 'all') return locations;
    return locations
        .where((l) => l.reviews.any((r) => r.friendName == _selectedFriend))
        .toList();
  }

  /// 플랫폼별 지도 구성(현재는 Google Maps 고정)
  Widget _buildCrossPlatformMap() {
    return _buildGoogleMaps();
  }

  /// Google Maps + 오버레이(현재 위치) 구성
  Widget _buildGoogleMaps() {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: _initialCameraPosition,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: _buildMapMarkers(),
          onTap: (_) => _hideLocationDetails(),
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        ),
        // 현재 위치 상태 오버레이
        CurrentLocationOverlay(
          currentPosition: _currentPosition,
          isLocationLoading: _isLocationLoading,
        ),
      ],
    );
  }

  /// Google Maps 마커 생성 (친구별 커스텀 이미지 마커)
  Set<Marker> _buildMapMarkers() {
    return _getFilteredLocations().map((location) {
      return Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: location.name,
          snippet:
              '${location.reviews.length}개 리뷰 • ${location.firstFriendName} • ${MapService.formatTimestamp(location.latestTimestamp)}',
        ),
        onTap: () => _showLocationDetails(location),
        // 커스텀 마커가 있으면 사용, 없으면 기본 마커
        icon:
            _customMarkers[location.firstFriendName] ??
            BitmapDescriptor.defaultMarkerWithHue(
              MapService.getMarkerColor(location.firstFriendName),
            ),
        // 마커 설정
        flat: false,
        draggable: false,
        anchor: const Offset(0.5, 1.0), // 마커 하단 중앙에 위치
        zIndex: 1.0, // 마커 레이어 순서
      );
    }).toSet();
  }

  /// 상세 정보 바텀시트 표시 (인스타그램 스타일 피드)
  void _showLocationDetails(MapLocation location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // 스크롤 가능하도록 설정
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7, // 초기 높이를 화면의 70%로 설정
        minChildSize: 0.5, // 최소 높이를 화면의 50%로 설정
        maxChildSize: 0.95, // 최대 높이를 화면의 95%로 설정
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 위치 이름과 리뷰 수
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${location.reviews.length}개의 리뷰',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // 리뷰 목록
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: location.reviews.length,
                  itemBuilder: (context, index) {
                    final review = location.reviews[index];
                    return ReviewCard(
                      review: review,
                      isFirst: index == 0,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 위치 상세 정보 숨기기
  void _hideLocationDetails() {
    // 현재는 구현하지 않음 (마커 탭 시에만 표시)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도
          _buildCrossPlatformMap(),
          
          // 상단 친구 필터
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: FriendFilterWidget(
              selectedFriend: _selectedFriend,
              friends: _friends,
              onFriendSelected: (friend) {
                setState(() {
                  _selectedFriend = friend;
                });
              },
            ),
          ),
          
          // 우측 하단 지도 컨트롤 버튼들
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            right: 16,
            child: MapControlButtons(
              onMyLocation: _getCurrentLocation,
              onZoomIn: () {
                _mapController?.animateCamera(CameraUpdate.zoomIn());
              },
              onZoomOut: () {
                _mapController?.animateCamera(CameraUpdate.zoomOut());
              },
              currentPosition: _currentPosition,
            ),
          ),
        ],
      ),
    );
  }
}
