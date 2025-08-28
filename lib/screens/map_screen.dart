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
          photoUrl:
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=400&fit=crop',
          comment:
              '바다가 보이는 아름다운 카페예요! ☕ 포항 해변의 일몰을 보면서 마시는 커피는 정말 특별했어요. 인테리어도 바다 테마로 꾸며져 있어서 분위기가 너무 좋았습니다. 특히 2층 테라스에서 마시는 아메리카노는 정말 최고였어요!',
        ),
        Review(
          id: 'review2',
          friendName: '권하민',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=400&fit=crop',
          comment:
              '커피 맛있고 분위기 좋아요 🌊 바다 소리를 들으면서 마시는 커피는 정말 힐링이 되었어요. 커피 원두도 신선하고, 바리스타의 실력도 훌륭해서 맛있는 커피를 마실 수 있었습니다. 친구들과 함께 가기 좋은 곳이에요!',
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
          photoUrl:
              'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400&h=400&fit=crop',
          comment: '신선한 해산물이 정말 맛있어요 🦐',
        ),
        Review(
          id: 'review4',
          friendName: '박예은',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          photoUrl:
              'https://images.unsplash.com/photo-1576402187878-974f70c890a5?w=400&h=400&fit=crop',
          comment: '가격 대비 정말 맛있어요! 💕',
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
          id: 'review5',
          friendName: '이찬민',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          photoUrl:
              'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400&h=400&fit=crop',
          comment: '산책하기 좋은 공원이에요 🌳',
        ),
        Review(
          id: 'review6',
          friendName: '기노은',
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          photoUrl:
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=400&fit=crop',
          comment: '봄날 벚꽃이 정말 예뻐요 🌸',
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
          id: 'review7',
          friendName: '권하민',
          timestamp: DateTime.now().subtract(const Duration(hours: 7)),
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=400&fit=crop',
          comment: '포항 시내가 한눈에 보여요 🏙️',
        ),
        Review(
          id: 'review8',
          friendName: '정태주',
          timestamp: DateTime.now().subtract(const Duration(hours: 8)),
          photoUrl:
              'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400&h=400&fit=crop',
          comment: '야경이 정말 아름다워요 🌃',
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
          id: 'review9',
          friendName: '박예은',
          timestamp: DateTime.now().subtract(const Duration(hours: 9)),
          photoUrl:
              'https://images.unsplash.com/photo-1576402187878-974f70c890a5?w=400&h=400&fit=crop',
          comment: '일몰이 정말 아름다워요 🌅',
        ),
        Review(
          id: 'review10',
          friendName: '이찬민',
          timestamp: DateTime.now().subtract(const Duration(hours: 10)),
          photoUrl:
              'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400&h=400&fit=crop',
          comment: '바다 소리 듣기 좋아요 🌊',
        ),
      ],
    ),
    MapLocation(
      id: 'dummy6',
      name: '포항 문화센터',
      latitude: 36.083489,
      longitude: 129.388523,
      reviews: [
        Review(
          id: 'review11',
          friendName: '기노은',
          timestamp: DateTime.now().subtract(const Duration(hours: 11)),
          photoUrl:
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=400&fit=crop',
          comment: '전시회가 정말 흥미로워요 🎨',
        ),
      ],
    ),
    MapLocation(
      id: 'dummy7',
      name: '포항 대학교',
      latitude: 36.087489,
      longitude: 129.392523,
      reviews: [
        Review(
          id: 'review12',
          friendName: '권하민',
          timestamp: DateTime.now().subtract(const Duration(hours: 12)),
          photoUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=400&fit=crop',
          comment: '캠퍼스가 정말 넓어요 🏫',
        ),
        Review(
          id: 'review13',
          friendName: '정태주',
          timestamp: DateTime.now().subtract(const Duration(hours: 13)),
          photoUrl:
              'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400&h=400&fit=crop',
          comment: '도서관에서 공부하기 좋아요 📚',
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

  // 하단 네비게이션 토글 상태
  bool _showBottomNavigation = false;

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
      // 마커 생성 전에 충분한 시간 대기
      await Future.delayed(const Duration(milliseconds: 500));

      for (final entry in _markerKeys.entries) {
        final friendName = entry.key;
        final key = entry.value;

        // 위젯이 렌더링될 때까지 잠시 대기
        await Future.delayed(const Duration(milliseconds: 200));

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

      // Firestore에서 리뷰 데이터 가져오기
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
    final locations = _firestoreLocations.isNotEmpty
        ? _firestoreLocations
        : _dummyLocations;

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
        GestureDetector(
          onDoubleTap: () {
            // 더블탭으로 줌인
            _mapController?.animateCamera(CameraUpdate.zoomIn());
          },
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialCameraPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false, // 기본 줌 컨트롤 비활성화
            markers: _buildMapMarkers(),
            onTap: (_) => _hideLocationDetails(),
            zoomGesturesEnabled: true, // 핀치 줌 제스처 활성화
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),
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
          snippet: _getLocationSnippet(location),
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
    final scrollController = ScrollController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // 중간 높이로 시작
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 드래그 핸들과 높이 조절 버튼
              Container(
                margin: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 드래그 핸들
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // 높이 조절 버튼들
                    Row(
                      children: [
                        _buildHeightToggleButton('중간', 0.6, scrollController),
                        const SizedBox(width: 8),
                        _buildHeightToggleButton('전체', 0.95, scrollController),
                      ],
                    ),
                  ],
                ),
              ),

              // 위치 이름과 상세 정보 (인스타그램 스타일)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                              const SizedBox(height: 8),
                              Text(
                                _getLocationSnippet(location),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${location.reviews.length}개의 리뷰',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 인스타그램 스타일 리뷰 피드
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: location.reviews.length,
                  itemBuilder: (context, index) {
                    final review = location.reviews[index];
                    return _buildInstagramStyleReviewCard(review, index == 0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 인스타그램 스타일 리뷰 카드
  Widget _buildInstagramStyleReviewCard(Review review, bool isFirst) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (유저 정보 + 시간)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 유저 아바타
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      MapService.getFriendIconAsset(review.friendName),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 유저 이름
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.friendName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTimestamp(review.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // 더보기 버튼
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // 사진
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                review.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.red, size: 50),
                  );
                },
              ),
            ),
          ),

          // 액션 버튼들
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border, size: 24),
                  color: Colors.grey[700],
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline, size: 24),
                  color: Colors.grey[700],
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.send, size: 24),
                  color: Colors.grey[700],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border, size: 24),
                  color: Colors.grey[700],
                ),
              ],
            ),
          ),

          // 좋아요 수
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '좋아요 12개',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),

          // 리뷰 코멘트 (있는 경우에만)
          if (review.comment != null && review.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: review.friendName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: review.comment,
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 위치 상세 정보 숨기기
  void _hideLocationDetails() {
    // 현재는 구현하지 않음 (마커 탭 시에만 표시)
  }

  /// 시간 포맷팅
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
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
        child: MarkerWidget(friendName: friendName, markerKey: key),
      );
    }).toList();
  }

  /// 하단 네비게이션 토글
  void _toggleBottomNavigation() {
    setState(() {
      _showBottomNavigation = !_showBottomNavigation;
    });
  }

  /// 네비게이션 아이템 생성
  Widget _buildNavigationItem(IconData icon, String label, int tabIndex) {
    return InkWell(
      onTap: () {
        // 메인 페이지의 해당 탭으로 이동
        Navigator.of(
          context,
        ).pushReplacementNamed('/main', arguments: {'initialTab': tabIndex});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey[700], size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 마커 정보창에 표시할 텍스트 생성
  String _getLocationSnippet(MapLocation location) {
    final category = _getLocationCategory(location.name);
    final address = _getLocationAddress(location);
    return '$category • $address • ${location.reviews.length}개 리뷰';
  }

  /// 장소 카테고리 반환
  String _getLocationCategory(String name) {
    if (name.contains('카페') || name.contains('커피')) return '☕ 카페';
    if (name.contains('맛집') || name.contains('음식')) return '🍽️ 맛집';
    if (name.contains('공원')) return '🌳 공원';
    if (name.contains('전망대')) return '🏙️ 전망대';
    if (name.contains('해변')) return '🌊 해변';
    if (name.contains('문화')) return '🎨 문화시설';
    if (name.contains('대학교')) return '🏫 대학교';
    return '📍 장소';
  }

  /// 장소 주소 반환 (더 정확한 위치 정보)
  String _getLocationAddress(MapLocation location) {
    // 실제로는 Google Geocoding API를 사용하여 정확한 주소를 가져올 수 있습니다
    if (location.name.contains('포항 해변 카페')) return '포항시 북구 해안로 123';
    if (location.name.contains('포항 맛집 거리')) return '포항시 북구 중앙로 456';
    if (location.name.contains('포항 공원')) return '포항시 북구 공원로 789';
    if (location.name.contains('포항 전망대')) return '포항시 북구 전망대로 321';
    if (location.name.contains('포항 해변')) return '포항시 북구 해안로 654';
    if (location.name.contains('포항 문화센터')) return '포항시 북구 문화로 987';
    if (location.name.contains('포항 대학교')) return '포항시 북구 대학로 147';
    return '포항시 북구';
  }

  /// 높이 조절 버튼 생성
  Widget _buildHeightToggleButton(
    String label,
    double height,
    ScrollController scrollController,
  ) {
    return GestureDetector(
      onTap: () {
        // DraggableScrollableSheet의 높이를 동적으로 조절
        // 이 기능은 DraggableScrollableSheet에서 직접 지원하지 않으므로
        // 대신 스크롤 위치를 조절하여 효과를 만듭니다
        if (height == 0.6) {
          // 중간 높이로 스크롤
          scrollController.animateTo(
            scrollController.position.maxScrollExtent * 0.3,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          // 전체 높이로 스크롤
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
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
              onFriendsManage: () {
                Navigator.pushNamed(context, '/friends-manage');
              },
            ),
          ),

          // 우측 하단 현재 위치 버튼
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.my_location,
                color: _currentPosition != null ? Colors.green : Colors.grey,
              ),
            ),
          ),

          // 하단 네비게이션 토글 버튼
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            child: FloatingActionButton.small(
              onPressed: _toggleBottomNavigation,
              backgroundColor: Colors.white,
              child: Icon(
                _showBottomNavigation
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
                color: Colors.grey[700],
              ),
            ),
          ),

          // 하단 네비게이션 메뉴 (세로로 표시)
          if (_showBottomNavigation)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavigationItem(Icons.camera_alt, '카메라', 0),
                    _buildNavigationItem(Icons.map, '지도', 1),
                    _buildNavigationItem(Icons.store, '쇼핑', 2),
                  ],
                ),
              ),
            ),

          // 마커 위젯들 (비트맵 변환을 위해 숨김 처리)
          ..._buildHiddenMarkerWidgets(),
        ],
      ),
    );
  }
}
