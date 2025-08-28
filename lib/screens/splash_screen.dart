import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import '../services/firebase_service.dart';
import '../services/map_service.dart';

/// 스플래시 화면
///
/// 앱 시작 시 Firebase 초기화를 담당하는 화면입니다.
/// - Firebase 초기화
/// - 온보딩 완료 여부 확인
/// - 적절한 화면으로 이동
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusText = '앱을 준비하는 중...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Firebase 초기화 + 온보딩 여부 확인
  Future<void> _initializeApp() async {
    try {
      debugPrint('🚀 앱 초기화 시작...');
      _updateStatus('앱을 준비하는 중...');

      // 최소 5초는 스플래시 화면을 보여줌
      await Future.delayed(const Duration(seconds: 5));

      // Firebase 초기화
      if (Firebase.apps.isEmpty) {
        debugPrint('🔥 Firebase 초기화 중...');
        _updateStatus('Firebase를 초기화하는 중...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase 초기화 완료');
        _updateStatus('Firebase 초기화 완료');
      } else {
        debugPrint('ℹ️ Firebase 이미 초기화됨');
        _updateStatus('Firebase 준비됨');
      }

      // Firebase가 실제로 초기화되었는지 확인
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase 초기화 실패');
      }

      // Firebase 서비스 초기화
      debugPrint('🔧 Firebase 서비스 초기화 중...');
      _updateStatus('Firebase 서비스를 준비하는 중...');
      await FirebaseService.initialize(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase 서비스 초기화 완료');
      _updateStatus('Firebase 서비스 준비 완료');

      // GeoPoint 마이그레이션 (기존 문서 location 백필)
      _updateStatus('데이터 정리 중...');
      final updated = await MapService().migrateReviewsToGeoPoint();
      debugPrint('GeoPoint 백필 업데이트 수: $updated');

      // 온보딩 완료 여부 확인
      if (mounted) {
        await _checkOnboardingStatus();
      }
    } catch (e) {
      debugPrint('❌ 앱 초기화 오류: $e');
      _updateStatus('오류 발생: $e');
      // 오류 발생 시에도 최소 5초는 스플래시 화면을 보여줌
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        _navigateToOnboarding();
      }
    }
  }

  void _updateStatus(String status) {
    if (mounted) {
      setState(() {
        _statusText = status;
      });
    }
  }

  /// 온보딩 완료 여부 확인 후 분기 이동
  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;

      if (!mounted) return;

      // 추가 5초 대기 (총 10초 이상 스플래시 화면 표시)
      _updateStatus('온보딩 상태를 확인하는 중...');
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;

      debugPrint('📍 온보딩 상태 확인: $onboardingCompleted');

      if (onboardingCompleted) {
        debugPrint('🚀 메인 페이지로 이동');
        _navigateToMainPage();
      } else {
        debugPrint('📱 온보딩 화면으로 이동');
        _navigateToOnboarding();
      }
    } catch (e) {
      debugPrint('❌ 온보딩 상태 확인 오류: $e');
      if (mounted) {
        _navigateToOnboarding();
      }
    }
  }

  /// 메인 페이지로 이동
  void _navigateToMainPage() {
    Navigator.pushReplacementNamed(
      context,
      '/main',
      arguments: {'initialTab': 1}, // 지도 탭
    );
  }

  /// 온보딩으로 이동
  void _navigateToOnboarding() {
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade600, Colors.green.shade400],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 아이콘 (더 크고 눈에 띄게)
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 90,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 40),

                // 앱 이름 (더 크고 굵게)
                const Text(
                  'Whatapp',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 부제목 (더 명확하게)
                const Text(
                  '여행의 모든 순간을 기록하세요',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 60),

                // 로딩 인디케이터 (더 크게)
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 30),

                // 상태 메시지 (더 명확하게)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),

                // 타이머 표시 (선택사항)
                Text(
                  '잠시만 기다려주세요...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
