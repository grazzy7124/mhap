import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_options.dart';
import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
          ],
        ),
      ),
    );
  }
}
