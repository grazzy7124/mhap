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

  /// 친구 필터 적용된 위치 목록 반환
  List<MapLocation> _getFilteredLocations() {
    if (_selectedFriend == 'all') return _firestoreLocations;
    return _firestoreLocations
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
              const SizedBox(height: 20),

              // 장소 이름 헤더
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  location.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // 리뷰 개수 표시
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${location.reviews.length}개의 리뷰',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 인스타그램 스타일 리뷰 피드
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: location.reviews.length,
                  itemBuilder: (context, index) {
                    final review = location.reviews[index];
                    return ReviewCard(review: review, isFirst: index == 0);
                  },
                ),
              ),

              // 하단 버튼들
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openDirections(location),
                        icon: const Icon(Icons.directions),
                        label: const Text('길찾기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareLocation(location),
                        icon: const Icon(Icons.share),
                        label: const Text('공유'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 상세 시트 닫기
  void _hideLocationDetails() {
    Navigator.of(context).pop();
  }

  /// 길찾기 열기(플랫폼별 기본 지도 앱)
  void _openDirections(MapLocation location) {
    if (Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple Maps에서 길찾기를 열어드립니다'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Maps에서 길찾기를 열어드립니다'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  /// 위치 공유(데모)
  void _shareLocation(MapLocation location) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${location.name} 위치를 공유합니다'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 현재 위치로 카메라 이동
  void _goToMyLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
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
    } else {
      _getCurrentLocation();
    }
  }

  /// 확대/축소
  void _zoomIn() => _mapController?.animateCamera(CameraUpdate.zoomIn());
  void _zoomOut() => _mapController?.animateCamera(CameraUpdate.zoomOut());

  /// 마커 위젯들을 생성 (RepaintBoundary로 감싸서 비트맵 변환 가능하게)
  List<Widget> _buildHiddenMarkerWidgets() {
    return _markerKeys.entries.map((entry) {
      final friendName = entry.key;
      final key = entry.value;
      return Positioned(
        left: -1000, // 화면 밖에 위치시켜 숨김
        top: -1000,
        child: MarkerWidget(friendName: friendName, markerKey: key),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.camera_alt, color: Colors.black), // 카메라 아이콘
          onPressed: () {
            // PageView에서 카메라 탭(인덱스 0)으로 이동
            Navigator.pushReplacementNamed(context, '/main');
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: () {
              // 장바구니 페이지로 이동
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 메인 지도
          _buildCrossPlatformMap(),
          // 상단 친구 필터
          FriendFilterWidget(
            selectedFriend: _selectedFriend,
            friends: _friends,
            onFriendSelected: (friend) => setState(() => _selectedFriend = friend),
          ),
          // 마커 위젯들 (비트맵 변환을 위해 숨김 처리)
          ..._buildHiddenMarkerWidgets(),
          // 우측 하단 컨트롤 버튼들
          MapControlButtons(
            onMyLocation: _goToMyLocation,
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            currentPosition: _currentPosition,
          ),
        ],
      ),
    );
  }
}
