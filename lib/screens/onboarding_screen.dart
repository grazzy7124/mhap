import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_page.dart';

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

  /// 폼 상태 및 텍스트 컨트롤러들 (예: 이메일/비밀번호)
  /// 실제 인증 연동 시 입력값을 사용합니다.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 폼 제출 핸들러
  ///
  /// - 폼 유효성 검사
  /// - (추후) Firebase Auth 연동하여 로그인/회원가입 수행
  /// - 성공 시 온보딩 완료로 표시하고 메인 페이지로 이동
  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    // TODO: Firebase Auth 연동 (로그인/회원가입)
    // 성공 가정 후 메인으로 이동
    Navigator.pushReplacementNamed(context, '/main');
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Whatapp',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(
                _isLoginMode ? '로그인' : '회원가입',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // 입력 폼
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        
                      },
                      child: Container(
                        width: 278, height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xffF0F0F0),
                          borderRadius: BorderRadius.circular(18)
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 8,),
                            Image.asset(
                              'assets/images/google.png',
                              width: 27,
                            ),
                            SizedBox(width: 46,),
                            Text('구글 계정으로 로그인')
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        
                      },
                      child: Container(
                        width: 278, height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xffF0F0F0),
                          borderRadius: BorderRadius.circular(18)
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 8,),
                            Image.asset(
                              'assets/images/apple.png',
                              width: 23, height: 29,
                            ),
                            SizedBox(width: 46,),
                            Text('애플 계정으로 로그인')
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 8),

              // 모드 전환 텍스트 버튼
              TextButton(
                onPressed: _toggleMode,
                child: Text(_isLoginMode ? '계정이 없으신가요? 회원가입' : '이미 계정이 있으신가요? 로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
