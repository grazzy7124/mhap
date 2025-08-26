import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'camera_screen.dart';
import 'map_screen.dart';

/// 메인 페이지
/// 
/// 이 화면은 앱의 핵심 화면으로, 사용자가 로그인 후 보게 되는 메인 화면입니다.
/// 주요 기능:
/// - PageView를 사용한 탭 간 슬라이드 네비게이션
/// - 하단 네비게이션 바를 통한 탭 전환
/// - 프로필 메뉴 및 로그아웃 기능
/// - 각 탭별 화면 관리 (사진, 카메라, 지도)
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0; // 현재 선택된 탭 인덱스
  final PageController _pageController = PageController(); // 페이지 컨트롤러

  // 각 탭에 해당하는 화면들
  final List<Widget> _pages = [
    const PhotosTab(), // 사진 탭
    const CameraScreen(), // 카메라 탭
    const MapScreen(), // 지도 탭
  ];

  @override
  void dispose() {
    // 페이지 컨트롤러 정리
    _pageController.dispose();
    super.dispose();
  }

  /// 탭 변경 시 호출되는 메서드
  /// 
  /// 하단 네비게이션 바에서 탭을 선택했을 때 실행됩니다.
  /// PageView를 해당 탭으로 이동시키고 현재 인덱스를 업데이트합니다.
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 페이지 변경 시 호출되는 메서드
  /// 
  /// PageView에서 슬라이드로 페이지를 변경했을 때 실행됩니다.
  /// 현재 인덱스를 업데이트하여 하단 네비게이션 바와 동기화합니다.
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// 프로필 메뉴를 표시하는 메서드
  /// 
  /// 앱바의 프로필 아이콘을 탭했을 때 실행됩니다.
  /// 로그아웃, 프로필, 설정 등의 옵션을 제공합니다.
  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // 프로필 메뉴 옵션들
            _buildProfileMenuItem(
              icon: Icons.person,
              title: '프로필',
              onTap: () {
                Navigator.pop(context);
                // TODO: 프로필 화면으로 이동
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.settings,
              title: '설정',
              onTap: () {
                Navigator.pop(context);
                // TODO: 설정 화면으로 이동
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.help,
              title: '도움말',
              onTap: () {
                Navigator.pop(context);
                // TODO: 도움말 화면으로 이동
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.info,
              title: '정보',
              onTap: () {
                Navigator.pop(context);
                // TODO: 정보 화면으로 이동
              },
            ),
            const Divider(),
            _buildProfileMenuItem(
              icon: Icons.logout,
              title: '로그아웃',
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog();
              },
              isDestructive: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 프로필 메뉴 아이템을 생성하는 메서드
  /// 
  /// 각 메뉴 옵션의 UI를 생성합니다.
  /// 아이콘, 제목, 탭 이벤트, 그리고 위험한 액션인지 여부를 설정할 수 있습니다.
  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  /// 로그아웃 확인 다이얼로그를 표시하는 메서드
  /// 
  /// 사용자가 로그아웃을 선택했을 때 확인 다이얼로그를 표시합니다.
  /// 확인 시 로그아웃 처리를 진행합니다.
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  /// 로그아웃 처리를 수행하는 메서드
  /// 
  /// SharedPreferences에서 온보딩 완료 상태를 제거하고
  /// 온보딩 화면으로 이동합니다.
  /// 이는 사용자가 다시 로그인할 수 있도록 합니다.
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // 왼쪽에서 오른쪽으로 슬라이드하는 애니메이션 (로그아웃 효과)
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0.0), // 왼쪽에서 시작
                  end: Offset.zero, // 중앙으로 이동
                ).animate(animation),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      print('로그아웃 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 앱바 (프로필 메뉴 포함)
      appBar: AppBar(
        title: const Text(
          'Whatapp',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          // 프로필 메뉴 버튼
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: _showProfileMenu,
          ),
        ],
      ),
      
      // 메인 콘텐츠 (PageView)
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const PageScrollPhysics(), // 페이지 스크롤 물리 효과
        scrollDirection: Axis.horizontal, // 가로 방향 스크롤
        children: _pages,
      ),
      
      // 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed, // 3개 이상의 탭을 지원
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        items: const [
          // 사진 탭
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: '사진',
          ),
          // 카메라 탭
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: '카메라',
          ),
          // 지도 탭
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '지도',
          ),
        ],
      ),
    );
  }
}

/// 사진 탭
/// 
/// 이 위젯은 메인 페이지의 첫 번째 탭으로, 사용자와 친구들이 찍은 사진들을 표시합니다.
/// 주요 기능:
/// - 내 사진과 친구들의 사진을 구분하여 표시
/// - 친구별로 사진을 필터링할 수 있는 기능
/// - 사진 클릭 시 상세 정보 표시
class PhotosTab extends StatefulWidget {
  const PhotosTab({super.key});

  @override
  State<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends State<PhotosTab> with SingleTickerProviderStateMixin {
  late TabController _tabController; // 탭 컨트롤러

  @override
  void initState() {
    super.initState();
    // 탭 컨트롤러 초기화 (내 사진, 친구 사진 2개 탭)
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    // 탭 컨트롤러 정리
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 탭 바
        Container(
          color: Colors.green,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: '내 사진'),
              Tab(text: '친구 사진'),
            ],
          ),
        ),
        
        // 탭 뷰
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 내 사진 탭
              _buildMyPhotosTab(),
              // 친구 사진 탭
              _buildFriendPhotosTab(),
            ],
          ),
        ),
      ],
    );
  }

  /// 내 사진 탭을 구성하는 메서드
  /// 
  /// 사용자가 직접 찍은 사진들을 그리드 형태로 표시합니다.
  /// 현재는 임시 데이터를 사용하며, 향후 Firebase에서 실제 데이터를 가져올 예정입니다.
  Widget _buildMyPhotosTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2열 그리드
        crossAxisSpacing: 16, // 가로 간격
        mainAxisSpacing: 16, // 세로 간격
        childAspectRatio: 1, // 정사각형 비율
      ),
      itemCount: 10, // 임시로 10개 사진 표시
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '내 사진 ${index + 1}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 친구 사진 탭을 구성하는 메서드
  /// 
  /// 친구들이 찍은 사진들을 표시합니다.
  /// 친구별로 구분하여 표시하며, 각 친구의 사진을 클릭할 수 있습니다.
  Widget _buildFriendPhotosTab() {
    // 임시 친구 데이터
    final friends = ['김철수', '이영희', '박민수', '정수진'];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return _buildFriendTab(friend);
      },
    );
  }

  /// 친구별 사진 탭을 구성하는 메서드
  /// 
  /// 특정 친구의 사진들을 표시합니다.
  /// 친구 이름과 함께 사진들을 그리드 형태로 보여줍니다.
  Widget _buildFriendTab(String friendName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 친구 이름 헤더
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '$friendName의 사진',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          
          // 친구의 사진들 (그리드)
          GridView.builder(
            shrinkWrap: true, // ListView 내부에서 사용할 때 필요
            physics: const NeverScrollableScrollPhysics(), // 스크롤 비활성화
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3열 그리드
              crossAxisSpacing: 8, // 가로 간격
              mainAxisSpacing: 8, // 세로 간격
              childAspectRatio: 1, // 정사각형 비율
            ),
            itemCount: 6, // 임시로 6개 사진 표시
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 오버플로우 방지
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo,
                            size: 24,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 4),
                          Flexible( // 텍스트 오버플로우 방지
                            child: Text(
                              '${friendName[0]}${index + 1}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
