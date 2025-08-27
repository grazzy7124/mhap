import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

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

  // 지도 설정: 초기 카메라 위치(서울)
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 15.0,
  );

  // 친구 필터링 상태
  String _selectedFriend = 'all'; // 'all'은 전체
  final List<String> _friends = ['all', '기노은', '권하민', '정태주', '박예은', '이찬민'];

  // 지도 마커 더미 데이터 (포항 지역)
  final List<MapLocation> _locations = [
    MapLocation(
      id: '1',
      name: '카츠닉',
      latitude: 36.073091,
      longitude: 129.404963,
      friendName: '기노은',
      photoUrl: 'https://via.placeholder.com/150/FF6B6B/FFFFFF?text=카츠닉',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    MapLocation(
      id: '2',
      name: '고바우 식당',
      latitude: 36.040135,
      longitude: 129.364282,
      friendName: '권하민',
      photoUrl: 'https://via.placeholder.com/150/4ECDC4/FFFFFF?text=고바우',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    MapLocation(
      id: '3',
      name: '컴포터블 피자',
      latitude: 36.088487,
      longitude: 129.390091,
      friendName: '정태주',
      photoUrl: 'https://via.placeholder.com/150/45B7D1/FFFFFF?text=컴포터블',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MapLocation(
      id: '4',
      name: '베라보 제면소',
      latitude: 36.081489,
      longitude: 129.399139,
      friendName: '박예은',
      photoUrl: 'https://via.placeholder.com/150/96CEB4/FFFFFF?text=베라보',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MapLocation(
      id: '5',
      name: '라멘 구루마',
      latitude: 36.088689,
      longitude: 129.390044,
      friendName: '이찬민',
      photoUrl: 'https://via.placeholder.com/150/FFEAA7/FFFFFF?text=구루마',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
    ),
    MapLocation(
      id: '6',
      name: '인브리즈',
      latitude: 36.081709,
      longitude: 129.395523,
      friendName: '기노은',
      photoUrl: 'https://via.placeholder.com/150/FF9FF3/FFFFFF?text=인브리즈',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MapLocation(
      id: '7',
      name: '쿠킹빌리지',
      latitude: 36.082127,
      longitude: 129.395925,
      friendName: '권하민',
      photoUrl: 'https://via.placeholder.com/150/FECA57/FFFFFF?text=쿠킹',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    MapLocation(
      id: '8',
      name: '스프커리보울',
      latitude: 36.081461,
      longitude: 129.398412,
      friendName: '정태주',
      photoUrl: 'https://via.placeholder.com/150/54A0FF/FFFFFF?text=스프커리',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    MapLocation(
      id: '9',
      name: '뜨돈',
      latitude: 36.086331,
      longitude: 129.403869,
      friendName: '박예은',
      photoUrl: 'https://via.placeholder.com/150/5F27CD/FFFFFF?text=뜨돈',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
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
    // 시작 시 현재 위치를 가져와 카메라를 이동
    _getCurrentLocation();
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
    return _locations.where((l) => l.friendName == _selectedFriend).toList();
  }

  /// 플랫폼별 지도 구성(현재는 Google Maps 고정)
  Widget _buildCrossPlatformMap() {
    return _buildGoogleMaps();
  }

  /// Google Maps + 오버레이(사진/현재 위치) 구성
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
        // 사진 썸네일 오버레이
        ..._buildPhotoOverlays(),
        // 현재 위치 상태 오버레이
        _buildCurrentLocationOverlay(),
      ],
    );
  }

  /// Google Maps 마커 생성
  Set<Marker> _buildMapMarkers() {
    return _getFilteredLocations().map((location) {
      return Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: location.name,
          snippet:
              '${location.friendName} • ${_formatTimestamp(location.timestamp)}',
        ),
        onTap: () => _showLocationDetails(location),
        // 커스텀 핀 아이콘 - 친구별로 다른 색상
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerColor(location.friendName),
        ),
        // 커스텀 핀 설정
        flat: false,
        draggable: false,
        anchor: const Offset(0.5, 1.0),
      );
    }).toSet();
  }

  /// 친구별 마커 색상 반환
  double _getMarkerColor(String friendName) {
    // 친구 이름을 기반으로 일관된 색상 반환
    final colors = [
      BitmapDescriptor.hueRed, // 빨강
      BitmapDescriptor.hueBlue, // 파랑
      BitmapDescriptor.hueGreen, // 초록
      BitmapDescriptor.hueYellow, // 노랑
      BitmapDescriptor.hueOrange, // 주황
      BitmapDescriptor.hueViolet, // 보라
      BitmapDescriptor.hueRose, // 분홍
      BitmapDescriptor.hueAzure, // 하늘색
    ];

    final index = friendName.hashCode.abs() % colors.length;
    return colors[index];
  }

  /// 사진 썸네일 오버레이 생성(데모 좌표 변환)
  List<Widget> _buildPhotoOverlays() {
    return _getFilteredLocations().map((location) {
      double screenX =
          (location.longitude + 180) / 360 * MediaQuery.of(context).size.width;
      double screenY =
          (90 - location.latitude) / 180 * MediaQuery.of(context).size.height;

      return Positioned(
        left: screenX - 25,
        top: screenY - 60,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _showLocationDetails(location),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                location.photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }).toList();
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

  /// 상세 정보 바텀시트 표시
  void _showLocationDetails(MapLocation location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  location.photoUrl,
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
                      child: const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            location.friendName[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        location.friendName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatTimestamp(location.timestamp),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
            const SizedBox(height: 20),
          ],
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

  /// 시간 포맷팅: "n시간 전", "n일 전"
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0) return '${difference.inDays}일 전';
    if (difference.inHours > 0) return '${difference.inHours}시간 전';
    if (difference.inMinutes > 0) return '${difference.inMinutes}분 전';
    return '방금 전';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
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
  final String friendName;
  final String photoUrl;
  final DateTime timestamp;

  MapLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.friendName,
    required this.photoUrl,
    required this.timestamp,
  });
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
