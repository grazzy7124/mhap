import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
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
/// - 스플래시('/') → Firebase 초기화 → 온보딩/메인 흐름 정의
/// - Firebase 초기화는 SplashScreen에서 처리
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
      // 초기 경로를 스플래시 화면으로 설정 (Firebase 초기화를 위해)
      initialRoute: '/',
      // 전역 라우트 테이블
      routes: {
        '/': (context) => const SplashScreen(),
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

/// 앱 진입점: Flutter 실행 시작
void main() {
  runApp(const MyApp());
}
