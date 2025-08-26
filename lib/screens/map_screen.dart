import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

/// 지도 화면
///
/// 이 화면은 사용자와 친구들이 방문한 장소들을 지도 위에 표시하는 화면입니다.
/// 주요 기능:
/// - Google Maps를 통한 실제 지도 표시
/// - 사용자와 친구들의 방문 장소를 마커로 표시
/// - 친구별 필터링 기능
/// - 각 마커 클릭 시 상세 정보 표시
/// - 현재 위치로 이동 및 줌 기능
/// - 크로스 플랫폼 지원 (iOS/Android)
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

  // 지도 설정
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(37.5665, 126.9780), // 서울 시청 (기본 위치)
    zoom: 15.0,
  );

  // 친구 필터링 관련 상태
  String _selectedFriend = 'all'; // 선택된 친구 ('all'은 모든 친구)
  final List<String> _friends = ['all', '나', '김철수', '이영희', '박민수', '정수진'];

  // 지도 마커 데이터 (임시)
  final List<MapLocation> _locations = [
    MapLocation(
      id: '1',
      name: '스타벅스 강남점',
      latitude: 37.5665,
      longitude: 126.9780,
      friendName: '나',
      photoUrl: 'https://picsum.photos/200/200?random=1',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    MapLocation(
      id: '2',
      name: '올리브영 명동점',
      latitude: 37.5636,
      longitude: 126.9834,
      friendName: '김철수',
      photoUrl: 'https://picsum.photos/200/200?random=2',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    MapLocation(
      id: '3',
      name: '이마트 잠실점',
      latitude: 37.5139,
      longitude: 127.1006,
      friendName: '이영희',
      photoUrl: 'https://picsum.photos/200/200?random=3',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MapLocation(
      id: '4',
      name: '홈플러스 영등포점',
      latitude: 37.5260,
      longitude: 126.9251,
      friendName: '박민수',
      photoUrl: 'https://picsum.photos/200/200?random=4',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MapLocation(
      id: '5',
      name: '롯데마트 잠실점',
      latitude: 37.5139,
      longitude: 127.1006,
      friendName: '정수진',
      photoUrl: 'https://picsum.photos/200/200?random=5',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 화면 초기화 시 현재 위치 가져오기
    _getCurrentLocation();
  }

  @override
  void dispose() {
    // 지도 컨트롤러 정리
    _mapController?.dispose();
    super.dispose();
  }

  /// 현재 위치를 가져오는 메서드
  ///
  /// GPS를 통해 현재 위치 정보를 가져와서 지도의 초기 위치로 설정합니다.
  /// 위치 권한이 없는 경우 기본 위치(서울 시청)를 사용합니다.
  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLocationLoading = true;
      });

      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isLocationLoading = false;
      });

      // 지도 컨트롤러가 초기화된 경우 현재 위치로 카메라 이동
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0,
            ),
          ),
        );
      }
    } catch (e) {
      print('현재 위치 가져오기 오류: $e');
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  /// 지도가 생성되었을 때 호출되는 콜백
  ///
  /// Google Maps 컨트롤러를 저장하고, 현재 위치가 있는 경우
  /// 해당 위치로 카메라를 이동시킵니다.
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // 현재 위치가 있는 경우 해당 위치로 카메라 이동
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

  /// 선택된 친구에 따라 필터링된 위치 목록을 반환하는 메서드
  ///
  /// 'all'이 선택된 경우 모든 위치를 반환하고,
  /// 특정 친구가 선택된 경우 해당 친구의 위치만 반환합니다.
  List<MapLocation> _getFilteredLocations() {
    if (_selectedFriend == 'all') {
      return _locations;
    }
    return _locations
        .where((location) => location.friendName == _selectedFriend)
        .toList();
  }

  /// 크로스 플랫폼 지도를 구성하는 메서드
  ///
  /// 현재는 모든 플랫폼에서 Google Maps를 사용하도록 설정되어 있습니다.
  /// 향후 iOS에서 Apple Maps 스타일을 사용할 수 있도록 확장 가능합니다.
  Widget _buildCrossPlatformMap() {
    // 현재는 모든 플랫폼에서 Google Maps 사용
    return _buildGoogleMaps();

    // 향후 iOS에서 Apple Maps 스타일을 사용하려면:
    // if (Platform.isIOS) {
    //   return _buildAppleMapsStyle();
    // } else {
    //   return _buildGoogleMaps();
    // }
  }

  /// Google Maps를 구성하는 메서드
  ///
  /// 실제 Google Maps 위젯을 생성하고, 그 위에 사진 썸네일과
  /// 현재 위치 정보를 오버레이로 표시합니다.
  Widget _buildGoogleMaps() {
    return Stack(
      children: [
        // Google Maps 위젯
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: _initialCameraPosition,
          myLocationEnabled: true, // 현재 위치 표시
          myLocationButtonEnabled: false, // 기본 현재 위치 버튼 비활성화 (커스텀 버튼 사용)
          markers: _buildMapMarkers(),
          onTap: (_) => _hideLocationDetails(), // 지도 탭 시 상세 정보 숨김
        ),

        // 사진 썸네일 오버레이
        ..._buildPhotoOverlays(),

        // 현재 위치 정보 오버레이
        _buildCurrentLocationOverlay(),
      ],
    );
  }

  /// Apple Maps 스타일의 지도를 구성하는 메서드
  ///
  /// iOS에서 사용할 수 있는 커스텀 지도 스타일입니다.
  /// 그리드 패턴과 위치 마커를 포함한 디자인을 제공합니다.
  /// 현재는 사용되지 않지만 향후 확장을 위해 유지됩니다.
  Widget _buildAppleMapsStyle() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.green],
        ),
      ),
      child: Stack(
        children: [
          // 그리드 패턴 (CustomPaint 사용)
          CustomPaint(painter: MapGridPainter(), size: Size.infinite),

          // 현재 위치 아이콘
          if (_currentPosition != null)
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 15,
              top: MediaQuery.of(context).size.height / 2 - 15,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

          // 친구 마커들
          ..._buildAppleStyleMarkers(),

          // 현재 위치 정보 오버레이
          _buildCurrentLocationOverlay(),
        ],
      ),
    );
  }

  /// Apple Maps 스타일의 마커들을 생성하는 메서드
  ///
  /// 각 친구의 위치를 표시하는 마커를 생성합니다.
  /// 사진 썸네일과 친구 이니셜을 포함합니다.
  List<Widget> _buildAppleStyleMarkers() {
    return _getFilteredLocations().map((location) {
      // 위도/경도를 화면 좌표로 변환 (간단한 예시)
      double screenX =
          (location.longitude + 180) / 360 * MediaQuery.of(context).size.width;
      double screenY =
          (90 - location.latitude) / 180 * MediaQuery.of(context).size.height;

      return Positioned(
        left: screenX - 25,
        top: screenY - 25,
        child: GestureDetector(
          onTap: () => _showLocationDetails(location),
          child: Column(
            children: [
              // 사진 썸네일
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white, width: 3),
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
                        child: const Icon(Icons.photo, color: Colors.grey),
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
              const SizedBox(height: 4),
              // 친구 이니셜
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  location.friendName[0],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Google Maps 마커들을 생성하는 메서드
  ///
  /// Google Maps에서 사용할 Set<Marker>를 생성합니다.
  /// 각 마커는 친구의 위치를 나타내며, 탭 시 상세 정보를 표시합니다.
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
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
    }).toSet();
  }

  /// 사진 썸네일 오버레이를 생성하는 메서드
  ///
  /// Google Maps 위에 각 위치의 사진 썸네일을 오버레이로 표시합니다.
  /// 이는 사용자가 지도에서 바로 사진을 확인할 수 있게 해줍니다.
  List<Widget> _buildPhotoOverlays() {
    return _getFilteredLocations().map((location) {
      // 위도/경도를 화면 좌표로 변환 (간단한 예시)
      double screenX =
          (location.longitude + 180) / 360 * MediaQuery.of(context).size.width;
      double screenY =
          (90 - location.latitude) / 180 * MediaQuery.of(context).size.height;

      return Positioned(
        left: screenX - 25,
        top: screenY - 60, // 마커 위에 표시
        child: GestureDetector(
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

  /// 현재 위치 정보 오버레이를 생성하는 메서드
  ///
  /// 지도 우측 상단에 현재 위치 정보를 표시합니다.
  /// 현재 위치가 로딩 중이거나 사용할 수 없는 경우 적절한 메시지를 표시합니다.
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

  /// 위치 상세 정보를 표시하는 메서드
  ///
  /// 사용자가 마커나 사진 썸네일을 탭했을 때 호출됩니다.
  /// 선택된 위치의 상세 정보를 하단 시트로 표시합니다.
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

            // 위치 이름
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

            // 사진 (더 큰 크기)
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

            // 위치 정보
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 친구 이름
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

                  // 시간
                  Text(
                    _formatTimestamp(location.timestamp),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 액션 버튼들
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // 길찾기 버튼
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

                  // 공유 버튼
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

  /// 위치 상세 정보를 숨기는 메서드
  ///
  /// 지도를 탭했을 때 호출되어 상세 정보를 숨깁니다.
  void _hideLocationDetails() {
    Navigator.of(context).pop();
  }

  /// 길찾기 기능을 실행하는 메서드
  ///
  /// 선택된 위치로 가는 길을 찾아줍니다.
  /// 현재는 TODO 상태이며, 향후 Google Maps 앱과 연동할 예정입니다.
  void _openDirections(MapLocation location) {
    // TODO: Google Maps 앱으로 길찾기 열기
    if (Platform.isIOS) {
      // iOS에서는 Apple Maps 사용
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple Maps에서 길찾기를 열어드립니다'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      // Android에서는 Google Maps 사용
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Maps에서 길찾기를 열어드립니다'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  /// 위치 공유 기능을 실행하는 메서드
  ///
  /// 선택된 위치 정보를 다른 앱으로 공유합니다.
  /// 현재는 TODO 상태이며, 향후 실제 공유 기능을 구현할 예정입니다.
  void _shareLocation(MapLocation location) {
    // TODO: 위치 공유 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${location.name} 위치를 공유합니다'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 현재 위치로 이동하는 메서드
  ///
  /// 지도 컨트롤러를 사용하여 현재 위치로 카메라를 이동시킵니다.
  /// 현재 위치가 없는 경우 위치를 다시 가져오려고 시도합니다.
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
      // 현재 위치가 없는 경우 다시 가져오기
      _getCurrentLocation();
    }
  }

  /// 지도를 확대하는 메서드
  ///
  /// 현재 줌 레벨을 1 증가시킵니다.
  void _zoomIn() {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.zoomIn());
    }
  }

  /// 지도를 축소하는 메서드
  ///
  /// 현재 줌 레벨을 1 감소시킵니다.
  void _zoomOut() {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.zoomOut());
    }
  }

  /// 타임스탬프를 포맷팅하는 메서드
  ///
  /// DateTime 객체를 사용자가 읽기 쉬운 형태로 변환합니다.
  /// 예: "2시간 전", "1일 전" 등
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onTap: () {
                      setState(() {
                        _selectedFriend = friend;
                      });
                    },
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
                // 현재 위치 버튼
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

                // 확대 버튼
                FloatingActionButton.small(
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // 축소 버튼
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
///
/// 각 위치의 상세 정보를 저장합니다.
/// 위도, 경도, 이름, 친구 이름, 사진 URL, 타임스탬프 등을 포함합니다.
class MapLocation {
  final String id; // 고유 식별자
  final String name; // 위치 이름
  final double latitude; // 위도
  final double longitude; // 경도
  final String friendName; // 방문한 친구 이름
  final String photoUrl; // 사진 URL
  final DateTime timestamp; // 방문 시간

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

/// 지도 그리드 패턴을 그리는 CustomPainter
///
/// Apple Maps 스타일의 지도에서 사용되는 그리드 패턴을 그립니다.
/// 세로선, 가로선, 그리고 교차점에 점을 그려서 지도처럼 보이게 합니다.
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 0.5;

    // 세로선 그리기
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 가로선 그리기
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 교차점에 점 그리기
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
