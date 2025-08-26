import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

/// 스플래시 화면
/// 
/// 이 화면은 앱이 시작된 후 사용자에게 보여지는 첫 번째 화면입니다.
/// 주요 기능:
/// - 앱 로고 및 브랜딩 표시
/// - 3초간 대기 후 자동으로 온보딩 화면으로 이동
/// - 슬라이드 애니메이션을 통한 화면 전환
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 페이드 인 애니메이션 (투명에서 불투명으로)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // 스케일 애니메이션 (작게에서 크게로)
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // 애니메이션 시작
    _animationController.forward();

    // 3초 후 온보딩 화면으로 자동 이동
    _navigateToOnboarding();
  }

  @override
  void dispose() {
    // 애니메이션 컨트롤러 정리
    _animationController.dispose();
    super.dispose();
  }

  /// 온보딩 화면으로 이동하는 메서드
  /// 
  /// 3초 후 자동으로 실행되며, 슬라이드 애니메이션과 함께
  /// 온보딩 화면으로 이동합니다.
  void _navigateToOnboarding() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OnboardingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 그라데이션 배경 (초록색에서 파란색으로)
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green,
              Colors.blue,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 애니메이션이 적용된 앱 로고
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          size: 60,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // 앱 이름 (페이드 인 애니메이션 적용)
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Whatapp',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 앱 설명 (페이드 인 애니메이션 적용)
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  '친구들과 함께하는 위치 기반 사진 공유',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              
              // 로딩 인디케이터 (페이드 인 애니메이션 적용)
              FadeTransition(
                opacity: _fadeAnimation,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              
              // 로딩 메시지 (페이드 인 애니메이션 적용)
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  '앱을 준비하는 중...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white60,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
