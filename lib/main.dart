import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatapp/mainpage/startscreenpage.dart';
import 'package:whatapp/onboarding.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_page.dart';

/// 메인 앱 클래스
///
/// 이 클래스는 앱의 전체적인 설정과 테마를 담당합니다.
/// - MaterialApp의 기본 설정
/// - 테마 및 색상 설정
/// - 라우팅 설정
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whatapp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // 앱 전체에서 사용할 기본 색상 테마
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        // 앱바 테마 설정
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        // 버튼 테마 설정
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AppStartupScreen(),
    );
  }
}

/// 앱 시작 화면
///
/// 이 화면은 앱이 시작될 때 가장 먼저 실행되는 화면입니다.
/// 주요 기능:
/// - Firebase 초기화
/// - 온보딩 완료 여부 확인
/// - 적절한 화면으로 라우팅 (온보딩 또는 메인페이지)
class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 Firebase 초기화 및 온보딩 상태 확인
    _initializeApp();
  }

  /// 앱 초기화 메서드
  ///
  /// 이 메서드는 앱이 시작될 때 실행되며:
  /// 1. Firebase를 초기화합니다
  /// 2. SharedPreferences에서 온보딩 완료 여부를 확인합니다
  /// 3. 결과에 따라 적절한 화면으로 이동합니다
  Future<void> _initializeApp() async {
    try {
      // Firebase 초기화
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 온보딩 완료 여부 확인
      await _checkOnboardingStatus();
    } catch (e) {
      print('앱 초기화 오류: $e');
      // 오류 발생 시 온보딩 화면으로 이동
      if (mounted) {
        _navigateToOnboarding();
      }
    }
  }

  /// 온보딩 완료 여부 확인 메서드
  ///
  /// SharedPreferences에서 'onboarding_completed' 키를 확인하여
  /// 사용자가 온보딩을 완료했는지 확인합니다.
  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (mounted) {
      if (onboardingCompleted) {
        // 온보딩 완료 시 메인페이지로 이동
        _navigateToMainPage();
      } else {
        // 온보딩 미완료 시 온보딩 화면으로 이동
        _navigateToOnboarding();
      }
    }
  }

  /// 메인페이지로 이동하는 메서드
  ///
  /// 슬라이드 애니메이션과 함께 메인페이지로 이동합니다.
  void _navigateToMainPage() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 오른쪽에서 왼쪽으로 슬라이드하는 애니메이션
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0), // 오른쪽에서 시작
              end: Offset.zero, // 중앙으로 이동
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// 온보딩 화면으로 이동하는 메서드
  ///
  /// 슬라이드 애니메이션과 함께 온보딩 화면으로 이동합니다.
  void _navigateToOnboarding() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 오른쪽에서 왼쪽으로 슬라이드하는 애니메이션
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0), // 오른쪽에서 시작
              end: Offset.zero, // 중앙으로 이동
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 앱 초기화 중일 때 표시할 로딩 화면
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고 또는 아이콘
            const Icon(Icons.location_on, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            // 앱 이름
            const Text(
              'Whatapp',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // 로딩 인디케이터
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            // 로딩 메시지
            const Text(
              '앱을 초기화하는 중...',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

/// 앱의 메인 함수
///
/// Flutter 앱의 진입점입니다.
/// MyApp 위젯을 실행하여 앱을 시작합니다.
void main() {
  runApp(const MyApp());
}
