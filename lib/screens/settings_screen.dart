import 'package:flutter/material.dart';

/// 설정 화면
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true; // 알림 토글 상태

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(), // 지도 페이지로 돌아가기
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 이미지와 '설정' 텍스트
            Row(
              children: [
                Image.asset(
                  'assets/images/settingscreen.png',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 12),
                const Text(
                  '설정',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 알림 on/off 토글
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '알림',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                _buildCustomToggle(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 프로필 수정 버튼
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  // 프로필 수정 기능 구현
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.centerLeft,
                ),
                child: const Text(
                  '프로필 수정',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 로그아웃 버튼
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _showLogoutDialog(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.centerLeft,
                ),
                child: const Text(
                  '로그아웃',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 커스텀 ON/OFF 토글 버튼 (양쪽 모두 그라데이션 배경)
  Widget _buildCustomToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    const double w = 137;
    const double h = 31;
    const double pad = 2;
    const double pillW = 67; // 활성(하이라이트) 영역 너비
    const double pillH = 27;

    return Semantics(
      button: true,
      toggled: value,
      label: '알림 ${value ? '켜짐' : '꺼짐'}',
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              // 바탕(OFF/ON 공통)
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              // 활성 영역: ON이면 좌측, OFF면 우측으로 이동하는 그라데이션
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                left: value ? pad : null,
                right: value ? null : pad,
                top: pad,
                child: Container(
                  width: pillW,
                  height: pillH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFDE3397), // 밝은 핑크
                        Color(0xFFF46061),
                        Color(0xFFFEA440), // 밝은 주황
                      ],
                    ),
                  ),
                ),
              ),
              // 텍스트: 좌측 ON, 우측 OFF
              // 활성 쪽은 흰색/볼드, 비활성은 회색/보통
              Positioned.fill(
                child: Row(
                  children: [
                    // 왼쪽(ON)
                    Expanded(
                      child: Center(
                        child: Text(
                          'ON',
                          style: TextStyle(
                            color: value ? Colors.white : Colors.grey[300],
                            fontSize: 16,
                            fontWeight: value
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // 오른쪽(OFF)
                    Expanded(
                      child: Center(
                        child: Text(
                          'OFF',
                          style: TextStyle(
                            color: value ? Colors.grey[300] : Colors.white,
                            fontSize: 16,
                            fontWeight: value
                                ? FontWeight.w500
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 로그아웃 확인 다이얼로그 표시
  Future<void> _showLogoutDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xffC4C4C4),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),
              const Text(
                '정말 로그아웃하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 15),
              Container(height: 1, color: const Color(0xff939393)),
              const SizedBox(height: 10),
              // 예 버튼
              GestureDetector(
                onTap: () => Navigator.of(context).pop(true),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '확인',
                      style: TextStyle(
                        color: Color(0xff007AFF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      // 로그아웃 기능 구현
      // TODO: Firebase 로그아웃 로직 추가
      print('로그아웃 확인됨');
    }
  }
}
