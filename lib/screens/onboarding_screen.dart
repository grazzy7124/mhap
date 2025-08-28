import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/firebase_service.dart';
import '../firebase_options.dart';

/// 온보딩 화면
///
/// 앱 최초 실행 시 사용자에게 로그인/회원가입 과정을 제공하는 화면입니다.
/// 현재는 백엔드 연동 없이 UI와 상태 전환에 집중되어 있으며,
/// 실제 인증(이메일/소셜 로그인) 연동은 추후 Firebase Auth로 확장됩니다.
///
/// 이 화면의 역할:
/// - 로그인/회원가입 폼 전환(_isLoginMode 토글)
/// - 폼 유효성 검사 및 제출
/// - 온보딩 완료 플래그 저장 후 메인으로 이동(임시)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// 로그인(true)/회원가입(false) 모드 전환 플래그
  bool _isLoginMode = true;

  /// 소셜 로그인 처리 중 로딩 플래그
  bool _isLoading = false;

  /// 폼 상태 및 텍스트 컨트롤러들 (예: 이메일/비밀번호)
  /// 실제 인증 연동 시 입력값을 사용합니다.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Firebase 초기화 상태 확인
    _ensureFirebaseInitialized();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Firebase가 초기화되었는지 확인하고 필요시 초기화
  Future<void> _ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await FirebaseService.initialize();
        debugPrint('OnboardingScreen: Firebase 초기화 완료');
      }
    } catch (e) {
      debugPrint('OnboardingScreen: Firebase 초기화 오류: $e');
    }
  }

  /// (이메일/비번 폼 제출은 현재 미사용)

  Future<void> _afterLoginSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/main',
      arguments: {'initialTab': 1}, // 1 = 지도 탭 (0: 카메라, 1: 지도, 2: 쇼핑)
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      // Firebase 초기화 상태 재확인
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await FirebaseService.initialize();
        debugPrint('Google 로그인 시 Firebase 초기화 완료');
      }

      await FirebaseService.signInWithGoogle();
      await _afterLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('구글 로그인 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 모드 전환(로그인<->회원가입)
  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // UI 구성: 배경 + 폼 + 행동 버튼들
    return Scaffold(
      backgroundColor: Color(0xff000000),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 149),
                Image.asset(
                  'assets/images/login_icon.png',
                  width: 60.55,
                ),
                Image.asset(
                  'assets/images/Mhap.png',
                  width: 100
                ),
                SizedBox(height: 100,),
            
                // 입력 폼
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _handleGoogleSignIn,
                        child: Container(
                          width: 278,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(0xffF0F0F0),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Image.asset('assets/images/google.png', width: 27),
                              SizedBox(width: 46),
                              Text(_isLoading ? '처리 중...' : '구글 계정으로 로그인'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
