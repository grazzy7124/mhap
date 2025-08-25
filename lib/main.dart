import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';
import 'services/location_service.dart';

void main() async {
  //flutter엔진과 위젯 시스템을 초기화
  WidgetsFlutterBinding.ensureInitialized();
  //firebase 서비스를 초기화(초기화 시작 전까지 시작하지 않고 대기)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, //현재 플랫폼에 맞는 설정 정보를 사용
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS 추적 앱',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LocationTrackingPage(),
    );
  }
}

class LocationTrackingPage extends StatefulWidget {
  const LocationTrackingPage({super.key});

  @override
  State<LocationTrackingPage> createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage> {
  final LocationService _locationService = LocationService();
  bool _isTracking = false;
  Position? _currentPosition;
  String _statusMessage = '위치 추적을 시작하려면 버튼을 누르세요';

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    bool hasPermission = await _locationService.hasLocationPermission;
    bool isServiceEnabled = await _locationService.isLocationServiceEnabled;

    if (!hasPermission) {
      setState(() {
        _statusMessage = '위치 권한이 필요합니다';
      });
    } else if (!isServiceEnabled) {
      setState(() {
        _statusMessage = '위치 서비스를 활성화해주세요';
      });
    }
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _locationService.stopTracking();
      setState(() {
        _isTracking = false;
        _statusMessage = '위치 추적이 중지되었습니다';
      });
    } else {
      bool success = await _locationService.startTracking();
      if (success) {
        setState(() {
          _isTracking = true;
          _statusMessage = '위치 추적이 시작되었습니다';
        });
      } else {
        setState(() {
          _statusMessage = '위치 추적 시작에 실패했습니다';
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    Position? position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentPosition = position;
        _statusMessage =
            '현재 위치: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    } else {
      setState(() {
        _statusMessage = '현재 위치를 가져올 수 없습니다';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('GPS 위치 추적'),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 상태 메시지
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isTracking
                    ? Colors.green.shade100
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isTracking ? Colors.green : Colors.blue,
                  width: 2,
                ),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _isTracking
                      ? Colors.green.shade800
                      : Colors.blue.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // 현재 위치 정보
            if (_currentPosition != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '현재 위치 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '위도: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                    ),
                    Text(
                      '경도: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                    ),
                    Text(
                      '정확도: ${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                    ),
                    if (_currentPosition!.altitude > 0)
                      Text(
                        '고도: ${_currentPosition!.altitude.toStringAsFixed(1)}m',
                      ),
                    if (_currentPosition!.speed > 0)
                      Text(
                        '속도: ${(_currentPosition!.speed * 3.6).toStringAsFixed(1)}km/h',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.location_on),
                  label: const Text('현재 위치'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _toggleTracking,
                  icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                  label: Text(_isTracking ? '추적 중지' : '추적 시작'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 추적 상태 표시
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isTracking ? Colors.green.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isTracking ? Icons.gps_fixed : Icons.gps_off,
                    color: _isTracking ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isTracking ? '실시간 추적 중' : '추적 중지됨',
                    style: TextStyle(
                      color: _isTracking
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 실시간 위치 추적 데이터 표시
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          '실시간 위치 추적 기록',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_sweep,
                            color: Colors.red,
                          ),
                          onPressed: _clearAllLocationTracks,
                          tooltip: '모든 기록 삭제',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _locationService.getLocationTracksStream(),
                      builder: (context, snapshot) {
                        // 데이터가 로드되지 않았을 때 로딩을 반환
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // 에러가 발생했을 때
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '데이터 로드 오류: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        // 데이터가 없을 때
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              '아직 위치 추적 기록이 없습니다',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        // 스트림에서 받은 데이터의 문서 목록을 저장
                        final documents = snapshot.data!.docs;

                        return ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: documents.length,
                          itemBuilder: (context, index) {
                            final doc = documents[index];
                            final data = doc.data() as Map<String, dynamic>;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  '${data['latitude']?.toStringAsFixed(6) ?? 'N/A'}, ${data['longitude']?.toStringAsFixed(6) ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                subtitle: Text(
                                  '정확도: ${data['accuracy']?.toStringAsFixed(1) ?? 'N/A'}m',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTimestamp(data['timestamp']),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _deleteLocationTrack(doc.id),
                                      tooltip: '삭제',
                                    ),
                                  ],
                                ),
                                onTap: () => _showLocationDetails(doc),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 타임스탬프 포맷팅 메서드
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  // 위치 추적 데이터 삭제
  Future<void> _deleteLocationTrack(String documentId) async {
    try {
      await _locationService.deleteLocationTrack(documentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('위치 추적 데이터가 삭제되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 위치 추적 데이터 상세 정보 표시
  void _showLocationDetails(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 상세 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('위도: ${data['latitude']?.toStringAsFixed(6) ?? 'N/A'}'),
            Text('경도: ${data['longitude']?.toStringAsFixed(6) ?? 'N/A'}'),
            Text('정확도: ${data['accuracy']?.toStringAsFixed(1) ?? 'N/A'}m'),
            if (data['altitude'] != null)
              Text('고도: ${data['altitude']?.toStringAsFixed(1) ?? 'N/A'}m'),
            if (data['speed'] != null)
              Text('속도: ${(data['speed'] * 3.6).toStringAsFixed(1)}km/h'),
            if (data['heading'] != null)
              Text('방향: ${data['heading']?.toStringAsFixed(1) ?? 'N/A'}°'),
            Text('디바이스 ID: ${data['device_id'] ?? 'N/A'}'),
            Text('생성 시간: ${_formatFullTimestamp(data['timestamp'])}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteLocationTrack(doc.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 전체 타임스탬프 포맷팅 메서드
  String _formatFullTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  // 일괄 삭제 기능
  Future<void> _clearAllLocationTracks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 위치 추적 데이터 삭제'),
        content: const Text('정말로 모든 위치 추적 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 현재 디바이스의 모든 위치 데이터 삭제
        final deviceId = await _locationService.getDeviceId();
        await _locationService.deleteDeviceLocationTracks(deviceId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 위치 추적 데이터가 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일괄 삭제 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
