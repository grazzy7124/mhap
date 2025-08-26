import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_page.dart';

/// 온보딩 화면
///
/// 이 화면은 사용자가 앱을 처음 사용할 때 보게 되는 화면입니다.
/// 주요 기능:
/// - 사용자 로그인/회원가입 폼 제공
/// - Firebase 인증 (현재는 TODO 상태)
/// - 온보딩 완료 후 메인페이지로 이동
/// - 슬라이드 애니메이션을 통한 화면 전환
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true; // true: 로그인 모드, false: 회원가입 모드

  @override
  void dispose() {
    // 컨트롤러 정리
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// 인증 처리 메서드
  ///
  /// 현재는 TODO 상태이며, 향후 Firebase Authentication을 구현할 예정입니다.
  /// 로그인/회원가입 성공 시 온보딩 완료로 표시하고 메인페이지로 이동합니다.
  Future<void> _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Firebase Authentication 구현
        // 현재는 임시로 성공 처리
        await Future.delayed(const Duration(seconds: 1));

        // 온보딩 완료로 표시
        await _markOnboardingComplete();

        // 메인페이지로 이동
        if (mounted) {
          _navigateToMainPage();
        }
      } catch (e) {
        // 오류 처리
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('인증 오류: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// 온보딩 완료 표시 메서드
  ///
  /// SharedPreferences에 'onboarding_completed' 키를 true로 설정하여
  /// 다음 앱 실행 시 온보딩을 건너뛰고 메인페이지로 바로 이동하도록 합니다.
  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
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

  /// 모드 전환 메서드
  ///
  /// 로그인 모드와 회원가입 모드 간을 전환합니다.
  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      // 폼 초기화
      _formKey.currentState?.reset();
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
            colors: [Colors.green, Colors.blue],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // 앱 로고
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        size: 50,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 앱 이름
                    const Text(
                      'Whatapp',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 앱 설명
                    Text(
                      _isLoginMode
                          ? '친구들과 함께하는 위치 기반 사진 공유'
                          : '새로운 계정을 만들어 시작하세요',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // 인증 폼
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // 모드 제목
                            Text(
                              _isLoginMode ? '로그인' : '회원가입',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 이메일 입력 필드
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: '이메일',
                                hintText: 'example@email.com',
                                prefixIcon: const Icon(
                                  Icons.email,
                                  color: Colors.green,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.green,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '이메일을 입력해주세요';
                                }
                                if (!value.contains('@')) {
                                  return '올바른 이메일 형식을 입력해주세요';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // 비밀번호 입력 필드
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: '비밀번호',
                                hintText: '••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Colors.green,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.green,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '비밀번호를 입력해주세요';
                                }
                                if (value.length < 6) {
                                  return '비밀번호는 6자 이상이어야 합니다';
                                }
                                return null;
                              },
                            ),

                            // 회원가입 모드일 때만 이름 필드 표시
                            if (!_isLoginMode) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: '이름',
                                  hintText: '홍길동',
                                  prefixIcon: const Icon(
                                    Icons.person,
                                    color: Colors.green,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '이름을 입력해주세요';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            const SizedBox(height: 24),

                            // 인증 버튼
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        _isLoginMode ? '로그인' : '회원가입',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 모드 전환 버튼
                            TextButton(
                              onPressed: _toggleMode,
                              child: Text(
                                _isLoginMode
                                    ? '계정이 없으신가요? 회원가입'
                                    : '이미 계정이 있으신가요? 로그인',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
