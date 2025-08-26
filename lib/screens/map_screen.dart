import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  String _selectedFriend = '전체';
  Position? _currentPosition;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // 임시 위치 데이터 (실제로는 Firebase에서 가져올 예정)
  final List<MapLocation> _locations = [
    MapLocation(
      id: '1',
      name: '스타벅스 강남점',
      latitude: 37.5665,
      longitude: 127.0080,
      friendName: '나',
      photoUrl: null,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      address: '서울특별시 강남구 강남대로 396',
    ),
    MapLocation(
      id: '2',
      name: '올리브영 강남점',
      latitude: 37.5670,
      longitude: 127.0090,
      friendName: '김철수',
      photoUrl: null,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      address: '서울특별시 강남구 강남대로 398',
    ),
    MapLocation(
      id: '3',
      name: '이마트 강남점',
      latitude: 37.5680,
      longitude: 127.0100,
      friendName: '이영희',
      photoUrl: null,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      address: '서울특별시 강남구 강남대로 400',
    ),
    MapLocation(
      id: '4',
      name: 'CGV 강남점',
      latitude: 37.5690,
      longitude: 127.0110,
      friendName: '박민수',
      photoUrl: null,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      address: '서울특별시 강남구 강남대로 402',
    ),
    MapLocation(
      id: '5',
      name: '강남역',
      latitude: 37.4981,
      longitude: 127.0276,
      friendName: '나',
      photoUrl: null,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      address: '서울특별시 강남구 강남대로 지하 396',
    ),
    MapLocation(
      id: '6',
      name: '홍대입구역',
      latitude: 37.5572,
      longitude: 126.9254,
      friendName: '김철수',
      photoUrl: null,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      address: '서울특별시 마포구 양화로 지하 160',
    ),
  ];

  final List<String> _friends = ['전체', '나', '김철수', '이영희', '박민수'];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = '위치 권한이 필요합니다';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '위치 권한이 영구적으로 거부되었습니다';
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
        _isLoading = false;
        _hasError = false;
      });

      // 지도를 현재 위치로 이동
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
      print('지도 초기화 오류: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '위치를 가져올 수 없습니다: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorScreen();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                  : const LatLng(37.5665, 127.0080), // 기본값: 강남역
              zoom: 15.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              // 현재 위치가 있으면 지도를 해당 위치로 이동
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
            },
            markers: _getFilteredMarkers(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (LatLng position) {
              // 지도 탭 시 마커 정보 숨기기
              _hideLocationDetails();
            },
            onCameraMove: (CameraPosition position) {
              // 카메라 이동 시 오류 방지
            },
            onCameraMoveStarted: () {
              // 카메라 이동 시작 시 오류 방지
            },
            onCameraIdle: () {
              // 카메라 정지 시 오류 방지
            },
          ),

          // 상단 친구 선택 바
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  final isSelected = _selectedFriend == friend;
                  return _buildFriendChip(friend, isSelected);
                },
              ),
            ),
          ),

          // 우측 하단 내 위치 버튼
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'my_location',
              onPressed: _goToMyLocation,
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              child: const Icon(Icons.my_location),
            ),
          ),

          // 좌측 하단 줌 컨트롤
          Positioned(
            bottom: 100,
            left: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: _zoomOut,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // 로딩 인디케이터
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
              const SizedBox(height: 24),
              Text(
                '지도를 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _initializeMap,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendChip(String friend, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFriend = friend;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    friend == '전체' ? '👥' : friend[0],
                    style: TextStyle(
                      color: isSelected ? Colors.green : Colors.white,
                      fontSize: friend == '전체' ? 10 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                friend,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Set<Marker> _getFilteredMarkers() {
    try {
      final filteredLocations = _getFilteredLocations();

      final Set<Marker> markers = {};

      // 현재 위치 마커 추가
      if (_currentPosition != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            infoWindow: const InfoWindow(title: '현재 위치', snippet: '여기에 있습니다'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      }

      // 친구들의 위치 마커 추가
      for (final location in filteredLocations) {
        markers.add(
          Marker(
            markerId: MarkerId(location.id),
            position: LatLng(location.latitude, location.longitude),
            infoWindow: InfoWindow(
              title: location.name,
              snippet:
                  '${location.friendName} • ${_formatTimestamp(location.timestamp)}',
            ),
            icon: _getMarkerIcon(location.friendName),
            onTap: () => _showLocationDetails(location),
          ),
        );
      }

      return markers;
    } catch (e) {
      print('마커 생성 오류: $e');
      return {};
    }
  }

  BitmapDescriptor _getMarkerIcon(String friendName) {
    try {
      // 친구별로 다른 색상의 마커 사용
      switch (friendName) {
        case '나':
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
        case '김철수':
          return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        case '이영희':
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          );
        case '박민수':
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          );
        default:
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
      }
    } catch (e) {
      print('마커 아이콘 생성 오류: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    try {
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
    } catch (e) {
      print('타임스탬프 포맷 오류: $e');
      return '알 수 없음';
    }
  }

  void _showLocationDetails(MapLocation location) {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
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

              // 위치 정보
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              location.friendName[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${location.friendName} • ${_formatTimestamp(location.timestamp)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 주소 정보
                    if (location.address != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location.address!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 액션 버튼들
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _openDirections(location);
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('길찾기'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _viewPhotos(location);
                            },
                            icon: const Icon(Icons.photo),
                            label: const Text('사진 보기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    } catch (e) {
      print('위치 상세 정보 표시 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('위치 정보를 표시할 수 없습니다: $e')));
    }
  }

  void _hideLocationDetails() {
    try {
      // 지도 탭 시 상세 정보 숨기기
      Navigator.of(context).pop();
    } catch (e) {
      print('위치 상세 정보 숨기기 오류: $e');
    }
  }

  void _openDirections(MapLocation location) {
    try {
      // TODO: 길찾기 기능 구현 (Google Maps 앱으로 연결)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${location.name}으로 길찾기를 시작합니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('길찾기 오류: $e');
    }
  }

  void _viewPhotos(MapLocation location) {
    try {
      // TODO: 해당 위치의 사진들 보기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${location.name}의 사진들을 불러옵니다'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('사진 보기 오류: $e');
    }
  }

  void _goToMyLocation() {
    try {
      if (_currentPosition != null) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 16.0,
            ),
          ),
        );
      } else {
        _initializeMap();
      }
    } catch (e) {
      print('내 위치로 이동 오류: $e');
    }
  }

  void _zoomIn() {
    try {
      _mapController?.animateCamera(CameraUpdate.zoomIn());
    } catch (e) {
      print('줌 인 오류: $e');
    }
  }

  void _zoomOut() {
    try {
      _mapController?.animateCamera(CameraUpdate.zoomOut());
    } catch (e) {
      print('줌 아웃 오류: $e');
    }
  }

  List<MapLocation> _getFilteredLocations() {
    try {
      if (_selectedFriend == '전체') {
        return _locations;
      } else {
        return _locations
            .where((location) => location.friendName == _selectedFriend)
            .toList();
      }
    } catch (e) {
      print('위치 필터링 오류: $e');
      return [];
    }
  }
}

class MapLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String friendName;
  final String? photoUrl;
  final DateTime timestamp;
  final String? address;

  MapLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.friendName,
    this.photoUrl,
    required this.timestamp,
    this.address,
  });
}
