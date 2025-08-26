import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'map_screen.dart';
import 'shopping_screen.dart';
import 'onboarding_screen.dart';

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
  int _currentIndex = 1; // 기본 카메라 탭으로 시작 예시

  /// 페이지 컨트롤러 (탭과 동기화)
  final PageController _pageController = PageController(initialPage: 1);

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
      appBar: AppBar(
        title: const Text('Whatapp'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('로그아웃')),
            ],
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        children: const [
          ShoppingScreen(),
          CameraScreen(),
          MapScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: '쇼핑'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: '카메라'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
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
