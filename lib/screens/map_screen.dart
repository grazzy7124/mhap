import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

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

  // 지도 설정: 초기 카메라 위치(서울)
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 15.0,
  );

  // 친구 필터링 상태
  String _selectedFriend = 'all'; // 'all'은 전체
  final List<String> _friends = ['all', '기노은', '권하민', '정태주', '박예은', '이찬민'];

  // 지도 마커 더미 데이터 (포항 지역) - 실제 사진처럼 보이는 이미지들
  final List<MapLocation> _locations = [
    MapLocation(
      id: '1',
      name: '카츠닉',
      latitude: 36.073091,
      longitude: 129.404963,
      reviews: [
        Review(
          id: '1-1',
          friendName: '기노은',
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          comment: '돈카츠가 정말 맛있어요! 🍖',
        ),
        Review(
          id: '1-2',
          friendName: '권하민',
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop&crop=faces',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          comment: '가격 대비 퀄리티 좋아요 👍',
        ),
      ],
    ),
    MapLocation(
      id: '2',
      name: '고바우 식당',
      latitude: 36.040135,
      longitude: 129.364282,
      reviews: [
        Review(
          id: '2-1',
          friendName: '권하민',
          photoUrl:
              'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=300&fit=crop',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          comment: '한식의 정석! 🥘',
        ),
        Review(
          id: '2-2',
          friendName: '정태주',
          photoUrl:
              'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=300&fit=crop&crop=faces',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          comment: '반찬이 정말 맛있어요 😋',
        ),
      ],
    ),
    MapLocation(
      id: '3',
      name: '컴포터블 피자',
      latitude: 36.088487,
      longitude: 129.390091,
      reviews: [
        Review(
          id: '3-1',
          friendName: '정태주',
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          comment: '피자 크러스트가 완벽해요 🍕',
        ),
        Review(
          id: '3-2',
          friendName: '박예은',
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop&crop=faces',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          comment: '치즈가 정말 풍부해요 🧀',
        ),
      ],
    ),
    MapLocation(
      id: '4',
      name: '베라보 제면소',
      latitude: 36.081489,
      longitude: 129.399139,
      reviews: [
        Review(
          id: '4-1',
          friendName: '박예은',
          photoUrl:
              'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=300&fit=crop',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          comment: '면발이 쫄깃쫄깃해요 🍜',
        ),
        Review(
          id: '4-2',
          friendName: '이찬민',
          photoUrl:
              'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=300&fit=crop&crop=faces',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          comment: '육수가 정말 깊어요 🥣',
        ),
      ],
    ),
    MapLocation(
      id: '5',
      name: '라멘 구루마',
      latitude: 36.088689,
      longitude: 129.390044,
      reviews: [
        Review(
          id: '5-1',
          friendName: '이찬민',
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          comment: '일본 라멘의 맛을 느낄 수 있어요 🇯🇵',
        ),
        Review(
          id: '5-2',
          friendName: '기노은',
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop&crop=faces',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          comment: '차슈가 부드러워요 🥩',
        ),
      ],
    ),
    MapLocation(
      id: '6',
      name: '인브리즈',
      latitude: 36.081709,
      longitude: 129.395523,
      reviews: [
        Review(
          id: '6-1',
          friendName: '기노은',
          photoUrl:
              'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=300&fit=crop',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          comment: '분위기가 정말 좋아요 ✨',
        ),
        Review(
          id: '6-2',
          friendName: '권하민',
          photoUrl:
              'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=300&fit=crop&crop=faces',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          comment: '커피가 정말 맛있어요 ☕',
        ),
      ],
    ),
    MapLocation(
      id: '7',
      name: '쿠킹빌리지',
      latitude: 36.082127,
      longitude: 129.395925,
      reviews: [
        Review(
          id: '7-1',
          friendName: '권하민',
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop',
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          comment: '한식 뷔페의 정석! 🍽️',
        ),
        Review(
          id: '7-2',
          friendName: '정태주',
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop&crop=faces',
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          comment: '반찬 종류가 정말 많아요 🥗',
        ),
      ],
    ),
    MapLocation(
      id: '8',
      name: '스프커리보울',
      latitude: 36.081461,
      longitude: 129.398412,
      reviews: [
        Review(
          id: '8-1',
          friendName: '정태주',
          photoUrl:
              'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=300&fit=crop',
          timestamp: DateTime.now().subtract(const Duration(hours: 8)),
          comment: '커리가 정말 맛있어요 🍛',
        ),
        Review(
          id: '8-2',
          friendName: '박예은',
          photoUrl:
              'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=300&fit=crop&crop=faces',
          timestamp: DateTime.now().subtract(const Duration(hours: 8)),
          comment: '양이 정말 많아요! 🥄',
        ),
      ],
    ),
    MapLocation(
      id: '9',
      name: '뜨돈',
      latitude: 36.086331,
      longitude: 129.403869,
      reviews: [
        Review(
          id: '9-1',
          friendName: '박예은',
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          comment: '돼지고기가 정말 맛있어요 🐷',
        ),
        Review(
          id: '9-2',
          friendName: '정태주',
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop&crop=faces',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          comment: '삼겹살이 완벽해요 🔥',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 포항 지역 중심으로 초기 카메라 위치 설정
    _initialCameraPosition = const CameraPosition(
      target: LatLng(36.081489, 129.395523), // 포항 시내 중심 (베라보 제면소 근처)
      zoom: 13.0,
    );
    // 마커 키들 초기화
    _initializeMarkerKeys();
    // 시작 시 현재 위치를 가져와 카메라를 이동
    _getCurrentLocation();
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

  /// 마커 위젯 생성 (RepaintBoundary로 감싸서 비트맵 변환 가능하게)
  Widget _buildMarkerWidget(String friendName, GlobalKey key) {
    return RepaintBoundary(
      key: key,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _hueToColor(_getMarkerColor(friendName)), // 친구별 마커 색상과 동일한 배경색
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white, // 테두리는 흰색으로 변경하여 대비 효과
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: Padding(
            padding: const EdgeInsets.all(6.0), // 이미지 주변에 여백 추가
            child: Image.asset(
              _getFriendIconAsset(friendName),
              width: 32, // 42에서 32로 줄여서 여백 생성
              height: 32, // 42에서 32로 줄여서 여백 생성
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  /// 친구별 아이콘 에셋 경로 반환
  String _getFriendIconAsset(String friendName) {
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

  @override
  void dispose() {
    // 지도 컨트롤러 정리
    _mapController?.dispose();
    super.dispose();
  }

  /// 현재 위치 1회 조회 → 카메라 이동
  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLocationLoading = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLocationLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLocationLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLocationLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isLocationLoading = false;
      });

      // 지도 준비된 경우 현재 위치로 이동
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
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
    if (_selectedFriend == 'all') return _locations;
    return _locations
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
        _buildCurrentLocationOverlay(),
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
              '${location.reviews.length}개 리뷰 • ${location.firstFriendName} • ${_formatTimestamp(location.latestTimestamp)}',
        ),
        onTap: () => _showLocationDetails(location),
        // 커스텀 마커가 있으면 사용, 없으면 기본 마커
        icon:
            _customMarkers[location.firstFriendName] ??
            BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerColor(location.firstFriendName),
            ),
        // 마커 설정
        flat: false,
        draggable: false,
        anchor: const Offset(0.5, 1.0), // 마커 하단 중앙에 위치
        zIndex: 1.0, // 마커 레이어 순서
      );
    }).toSet();
  }

  /// Hue 값을 Color로 변환하는 헬퍼 메서드
  Color _hueToColor(double hue) {
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

  /// 친구별 마커 색상 반환
  double _getMarkerColor(String friendName) {
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

  /// 우측 상단 현재 위치 상태 오버레이
  Widget _buildCurrentLocationOverlay() {
    return Positioned(
      top: 50,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.my_location,
                  color: _currentPosition != null ? Colors.green : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '현재 위치',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _currentPosition != null
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _isLocationLoading
                  ? '확인 중...'
                  : _currentPosition != null
                  ? '위치 확인됨'
                  : '위치를 확인할 수 없습니다',
              style: TextStyle(
                fontSize: 10,
                color: _currentPosition != null ? Colors.grey[600] : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
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
                    return _buildReviewCard(review, index == 0);
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

  /// 개별 리뷰 카드 위젯 (인스타그램 스타일)
  Widget _buildReviewCard(Review review, bool isFirst) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 리뷰 헤더 (유저 정보 + 시간)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 유저 아바타
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _hueToColor(_getMarkerColor(review.friendName)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      review.friendName[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 유저 이름
                Expanded(
                  child: Text(
                    review.friendName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // 시간
                Text(
                  _formatTimestamp(review.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // 사진
          Container(
            width: double.infinity,
            height: 250,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(0),
                bottom: Radius.circular(12),
              ),
              child: Image.network(
                review.photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.red, size: 50),
                  );
                },
              ),
            ),
          ),

          // 리뷰 코멘트 (있는 경우에만)
          if (review.comment != null && review.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                review.comment!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
        ],
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

  /// 시간 포맷팅: "n시간 전", "n일 전"
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0) return '${difference.inDays}일 전';
    if (difference.inHours > 0) return '${difference.inHours}시간 전';
    if (difference.inMinutes > 0) return '${difference.inMinutes}분 전';
    return '방금 전';
  }

  /// 마커 위젯들을 비트맵으로 변환하여 저장 (RepaintBoundary 사용)
  Future<void> _generateHiddenMarkerBitmaps() async {
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

  /// 마커 위젯들을 생성 (RepaintBoundary로 감싸서 비트맵 변환 가능하게)
  List<Widget> _buildHiddenMarkerWidgets() {
    return _markerKeys.entries.map((entry) {
      final friendName = entry.key;
      final key = entry.value;
      return Positioned(
        left: -1000, // 화면 밖에 위치시켜 숨김
        top: -1000,
        child: _buildMarkerWidget(friendName, key),
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
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  final isSelected = _selectedFriend == friend;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFriend = friend),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          friend == 'all' ? '전체' : friend,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 마커 위젯들 (비트맵 변환을 위해 숨김 처리)
          ..._buildHiddenMarkerWidgets(),
          // 우측 하단 컨트롤 버튼들
          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: _goToMyLocation,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.my_location,
                    color: _currentPosition != null
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  onPressed: _zoomOut,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 지도 위치 정보를 담는 데이터 클래스
class MapLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<Review> reviews; // 여러 리뷰를 저장할 리스트

  MapLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.reviews,
  });

  // 첫 번째 리뷰의 친구 이름 (마커 색상용)
  String get firstFriendName =>
      reviews.isNotEmpty ? reviews.first.friendName : 'Unknown';

  // 첫 번째 리뷰의 사진 URL (마커 썸네일용)
  String get firstPhotoUrl => reviews.isNotEmpty ? reviews.first.photoUrl : '';

  // 가장 최근 리뷰 시간
  DateTime get latestTimestamp => reviews.isNotEmpty
      ? reviews.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)
      : DateTime.now();
}

/// 리뷰 정보를 담는 데이터 클래스
class Review {
  final String id;
  final String friendName;
  final String photoUrl;
  final DateTime timestamp;
  final String? comment; // 리뷰 코멘트 (선택사항)

  Review({
    required this.id,
    required this.friendName,
    required this.photoUrl,
    required this.timestamp,
    this.comment,
  });
}

/// 핀 꼬리 그리드 페인터(삼각형 모양)
class PinTailPainter extends CustomPainter {
  final Color color;

  PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Apple Maps 스타일 그리드 페인터(데모)
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final dotPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    for (double x = 25; x < size.width; x += 50) {
      for (double y = 25; y < size.height; y += 50) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
