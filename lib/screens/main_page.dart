import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'shopping_screen.dart';
import 'onboarding_screen.dart';
import 'camera_screen.dart';

/// 메인 페이지
///
/// 앱의 핵심 탭(사진/카메라/지도/쇼핑 등)으로 이동하는 허브 역할을 합니다.
/// - 하단 네비게이션 바로 탭 전환
/// - PageView로 스와이프 전환(필요 시 비활성화 가능)
/// - 프로필/로그아웃 등 상단 메뉴 제공(로그아웃 시 온보딩으로 복귀)
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  /// 현재 선택된 탭 인덱스
  int _currentIndex = 0; // 기본 카메라 탭으로 시작

  /// 페이지 컨트롤러 (탭과 동기화)
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // 라우트 파라미터에서 초기 탭 인덱스 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        final initialTab = args['initialTab'] as int?;
        if (initialTab != null && initialTab >= 0 && initialTab < 3) {
          setState(() => _currentIndex = initialTab);
          _pageController.jumpToPage(initialTab);
        }
      }
    });
    _pageController = PageController(initialPage: 1); // 0: 카메라 → 1: 지도로 변경
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 하단 탭 선택 시 페이지 이동
  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  /// 특정 탭으로 이동하는 메서드
  void goToTab(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  /// 로그아웃 처리: 온보딩으로 전환
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Whatapp'),
      //   actions: [
      //     PopupMenuButton<String>(
      //       onSelected: (value) {
      //         if (value == 'logout') _logout();
      //       },
      //       itemBuilder: (context) => const [
      //         PopupMenuItem(value: 'logout', child: Text('로그아웃')),
      //       ],
      //     ),
      //   ],
      // ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        children: const [
          CameraScreen(), // 카메라 화면으로 변경
          MapScreen(),
          ShoppingScreen(),
        ],
      ),
      // 하단 네비게이션 바 제거(지도 페이지 커스텀 네비 사용)
    );
  }
}
