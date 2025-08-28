import 'package:flutter/material.dart';

/// 친구 관리 페이지 (UI 시안 반영)
/// - 상단: 검정 AppBar + 뒤로가기
/// - 탭: 친구추가 / 내 친구 / 신청목록 (세그먼트 스타일)
/// - 배경: 핑크→오렌지 그라데이션
/// - 목록: 아바타 + 이름 + [추가][차단] pill 버튼
class FriendsManageScreen extends StatelessWidget {
  const FriendsManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final names = ['기노은', '정태주', '박예은'];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          centerTitle: false,
          title: const Text(''), // 시안처럼 타이틀 노출 X
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SegmentedTabBar(),
            ),
          ),
        ),
        body: Container(
          // 그라데이션 배경
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFDD3397), 
                Color(0xFFF46061),
                Color(0xffFEA440)
              ],
            ),
          ),
          child: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              // 1) 친구추가 탭 (시안 리스트)
              ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: names.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  return _FriendAddRow(name: names[i]);
                },
              ),

              // 2) 내 친구 (플레이스홀더)
              _PlaceholderCenter(label: '내 친구'),

              // 3) 신청목록 (플레이스홀더)
              _PlaceholderCenter(label: '신청목록'),
            ],
          ),
        ),
      ),
    );
  }
}

/// 세그먼트 형태의 TabBar
class _SegmentedTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFD9D9D9);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
      ),
      // padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        // 선택된 탭 배경(핑크) + pill
        indicator: BoxDecoration(
          color: const Color(0xFFDD3397),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xffC8C8C8),
        tabs: const [
          Tab(text: '친구추가'),
          Tab(text: '내 친구'),
          Tab(text: '신청목록'),
        ],
      ),
    );
  }
}

/// 친구 한 줄(아바타 + 이름 + [추가][차단])
class _FriendAddRow extends StatelessWidget {
  final String name;
  const _FriendAddRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white24,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          _PillButton(
            label: '추가',
            onPressed: () {},
          ),
          _PillButton(
            label: '차단',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

/// 시안처럼 작은 pill 버튼
class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PillButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white, // 연한 회색 느낌이면 Colors.white70 등으로 조절
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}

/// 다른 탭은 임시 센터 문구
class _PlaceholderCenter extends StatelessWidget {
  final String label;
  const _PlaceholderCenter({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
