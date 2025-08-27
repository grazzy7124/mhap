import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatapp/mainpage/startscreenpage.dart';
import 'package:whatapp/onboarding.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_page.dart';
import 'screens/friends_manage_screen.dart';
import 'screens/shopping_screen.dart';
import 'screens/upload_screen.dart';

/// 앱 진입 파일(main.dart)
///
/// 이 파일은 앱 실행 진입점과 전역 라우팅/테마 설정을 담당합니다.
/// - MaterialApp의 테마/라우트 초기화
/// - 스플래시('/' 경로) → 앱 초기화('/startup') → 온보딩/메인 흐름 정의
/// - Firebase 초기화(AppStartupScreen) 및 온보딩 완료 여부 확인
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whatapp',
      debugShowCheckedModeBanner: false,
      // 전역 테마: 앱바/버튼/색상 팔레트
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
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
      // 초기 경로를 스플래시로 설정
      initialRoute: '/',
      // 전역 라우트 테이블
      routes: {
        '/': (context) => const SplashScreen(),
        '/startup': (context) => const AppStartupScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/main': (context) => const MainPage(),
        '/friends': (context) => const FriendsManageScreen(),
        '/shopping': (context) => const ShoppingScreen(),
        '/upload': (context) => const UploadScreen(),
      },
    );
  }
}

/// 앱 시작 화면(AppStartupScreen)
///
/// 역할:
/// - Firebase를 1회만 초기화(중복 방지)
/// - SharedPreferences로 온보딩 완료 여부 확인
/// - 결과에 따라 온보딩('/onboarding') 또는 메인('/main')으로 이동
class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Firebase 초기화 + 온보딩 여부 확인
  Future<void> _initializeApp() async {
    try {
      // Firebase 초기화 (이미 존재하면 생략)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await _checkOnboardingStatus();
    } catch (e) {
      // 초기화 실패 시 온보딩으로 폴백
      if (mounted) {
        _navigateToOnboarding();
      }
    }
  }

  /// 온보딩 완료 여부 확인 후 분기 이동
  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    if (!mounted) return;
    if (onboardingCompleted) {
      _navigateToMainPage();
    } else {
      _navigateToOnboarding();
    }
  }

  /// 메인 페이지로 이동
  void _navigateToMainPage() {
    Navigator.pushReplacementNamed(context, '/main');
  }

  /// 온보딩으로 이동
  void _navigateToOnboarding() {
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    // 초기화 진행 중 간단한 로딩 화면 표시
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.location_on, size: 80, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Whatapp',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 24),
            Text(
              '앱을 초기화하는 중...',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

/// 앱 진입점: Flutter 실행 시작
void main() {
  runApp(const MyApp());
}
