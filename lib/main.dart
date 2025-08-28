import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_page.dart';
import 'screens/friends_manage_screen.dart';
import 'screens/shopping_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/review_form_screen.dart';
import 'services/firebase_service.dart';

/// 앱 진입 파일(main.dart)
///
/// 이 파일은 앱 실행 진입점과 전역 라우팅/테마 설정을 담당합니다.
/// - MaterialApp의 테마/라우트 초기화
/// - AppStartupScreen → Firebase 초기화 → 온보딩/메인 흐름 정의
/// - Firebase 초기화는 AppStartupScreen에서 처리
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

      // 초기 경로를 앱 시작 화면으로 설정 (Firebase 초기화를 위해)
      initialRoute: '/startup',
      // 전역 라우트 테이블
      routes: {
        '/startup': (context) => const AppStartupScreen(),

        '/onboarding': (context) => const OnboardingScreen(),
        '/main': (context) => const MainPage(),
        '/friends': (context) => const FriendsManageScreen(),
        '/friends-manage': (context) => const FriendsManageScreen(),
        '/shopping': (context) => const ShoppingScreen(),
        '/upload': (context) => const UploadScreen(),
        '/review': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? imagePath;
          if (args is Map && args['imagePath'] is String) {
            imagePath = args['imagePath'] as String;
          }
          return ReviewFormScreen(initialImagePath: imagePath);
        },
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
      // Firebase 초기화 (중복 방지)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase 초기화 완료');
      } else {
        debugPrint('Firebase 이미 초기화됨');
      }

      // Firebase 서비스 초기화
      try {
        await FirebaseService.initialize();
        debugPrint('Firebase 서비스 초기화 완료');
      } catch (e) {
        debugPrint('Firebase 서비스 초기화 오류: $e');
      }

      if (mounted) {
        await _checkOnboardingStatus();
      }
    } catch (e) {
      debugPrint('앱 초기화 오류: $e');
      // 초기화 실패 시 온보딩으로 폴백
      if (mounted) {
        _navigateToOnboarding();
      }
    }
  }

  /// 온보딩 완료 여부 확인 후 분기 이동
  Future<void> _checkOnboardingStatus() async {
    try {
      // Firebase 인증 상태 확인
      final currentUser = FirebaseService.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;

      if (!mounted) return;

      // Firebase 인증 상태에 따른 분기
      if (currentUser != null) {
        // 이미 로그인된 사용자
        debugPrint('사용자 이미 로그인됨: ${currentUser.email}');
        if (onboardingCompleted) {
          _navigateToMainPage();
        } else {
          // 온보딩 완료 플래그 설정 후 메인으로 이동
          await prefs.setBool('onboarding_completed', true);
          _navigateToMainPage();
        }
      } else {
        // 로그인되지 않은 사용자
        debugPrint('사용자 로그인되지 않음');
        if (onboardingCompleted) {
          // 온보딩은 완료했지만 로그아웃된 경우
          _navigateToOnboarding();
        } else {
          _navigateToOnboarding();
        }
      }
    } catch (e) {
      debugPrint('온보딩 상태 확인 오류: $e');
      // 오류 시 온보딩으로 이동
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
      arguments: {'initialTab': 1}, // 1 = 지도 탭 (0: 카메라, 1: 지도, 2: 쇼핑)
    );
  }

  /// 온보딩으로 이동
  void _navigateToOnboarding() {
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    // 초기화 진행 중 간단한 로딩 화면 표시
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 149),
            Image.asset(
              'assets/images/login_icon.png',
              width: 60.55,
            ),
            const SizedBox(height: 40),

            // 앱 이름
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

            // 부제목
            const Text(
              '여행의 모든 순간을 기록하세요',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 60),

            // 로딩 인디케이터
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 30),

            // 상태 메시지
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '앱을 초기화하는 중...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),

            // 타이머 표시
            Text(
              '잠시만 기다려주세요...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 32),
            
            // 수동 이동 버튼들 (디버그용)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _navigateToOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('온보딩으로 이동'),
                ),
                ElevatedButton(
                  onPressed: _navigateToMainPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('메인으로 이동'),
                ),
              ],
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
