import 'package:flutter/material.dart';

/// 스플래시 화면
///
/// 앱 시작 시 지구 회전 + 핀이 꽂히는 애니메이션을 보여주고
/// 완료 후 앱 초기화 라우트('/startup')로 이동합니다.
/// - 위치 권한 요청/조회는 스플래시에서 수행하지 않습니다(안정성 향상).
/// - 지구 이미지는 네트워크 프리캐시로 로딩 지연을 최소화합니다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _earthRotationController;
  late AnimationController _pinAnimationController;
  late AnimationController _fadeController;

  late Animation<double> _earthRotation;
  late Animation<double> _pinScale;
  late Animation<Offset> _pinPosition;
  late Animation<double> _fadeAnimation;

  static const String _earthUrl =
      'https://upload.wikimedia.org/wikipedia/commons/3/3f/The_Blue_Marble_%28Asia%29.jpg';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // 첫 프레임 이후 네트워크 이미지 프리캐시 (로딩 지연 최소화)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await precacheImage(const NetworkImage(_earthUrl), context);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _earthRotationController.dispose();
    _pinAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _earthRotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _earthRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _earthRotationController,
        curve: Curves.easeInOut,
      ),
    );

    _pinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pinScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pinAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _pinPosition = Tween<Offset>(begin: const Offset(0, -2.0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _pinAnimationController,
            curve: Curves.bounceOut,
          ),
        );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    _earthRotationController.forward();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) _pinAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) _navigateToStartup();
  }

  void _navigateToStartup() {
    Navigator.pushReplacementNamed(context, '/startup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1426), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: Stack(
          children: [
            ..._buildStars(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _earthRotation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _earthRotation.value * 2 * 3.14159,
                              child: _buildEarth(),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 10,
                          child: AnimatedBuilder(
                            animation: _pinAnimationController,
                            builder: (context, child) {
                              return SlideTransition(
                                position: _pinPosition,
                                child: ScaleTransition(
                                  scale: _pinScale,
                                  child: _buildPin(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStars() {
    final stars = <Widget>[];
    for (int i = 0; i < 50; i++) {
      stars.add(
        Positioned(
          left: (i * 37) % MediaQuery.of(context).size.width,
          top: (i * 73) % MediaQuery.of(context).size.height,
          child: Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      );
    }
    return stars;
  }

  Widget _buildEarth() {
    const double size = 220;
    const List<double> saturationBrightnessMatrix = <double>[
      1.2,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.2,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.2,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      10.0,
      10.0,
      10.0,
      0.0,
      1.0,
    ];

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(saturationBrightnessMatrix),
          child: Image.network(
            _earthUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0xFF0B1426),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFF2A71C5), Color(0xFF174A8B)],
                    center: Alignment(-0.2, -0.2),
                    radius: 0.9,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 24),
        ),
        Container(
          width: 4,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Container(
          width: 20,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
