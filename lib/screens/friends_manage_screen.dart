import 'package:flutter/material.dart';

/// 친구 관리 페이지
///
/// 친구 검색, 추가/삭제, 차단 등 관리 기능을 위한 화면의 기본 골격입니다.
/// 실제 데이터 연동은 Firebase 구현 단계에서 추가됩니다.
class FriendsManageScreen extends StatelessWidget {
  const FriendsManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '뒤로 가기',
        ),
        title: const Text('친구 관리'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 검색 바
          TextField(
            decoration: InputDecoration(
              hintText: '친구 검색',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // 내 친구 섹션 (더미)
          const Text(
            '내 친구',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...List.generate(5, (i) => _FriendTile(name: '친구 ${i + 1}')),

          const Divider(height: 32),

          // 친구 추천 섹션 (더미)
          const Text(
            '추천 친구',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...List.generate(3, (i) => _RecommendedFriendTile(name: '추천 ${i + 1}')),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final String name;
  const _FriendTile({required this.name});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name),
        trailing: Wrap(spacing: 8, children: [
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            onPressed: () {},
            tooltip: '최근 위치 보기',
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () {},
            tooltip: '친구 삭제',
          ),
        ]),
      ),
    );
  }
}

class _RecommendedFriendTile extends StatelessWidget {
  final String name;
  const _RecommendedFriendTile({required this.name});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_add_alt)),
        title: Text(name),
        trailing: ElevatedButton(
          onPressed: () {},
          child: const Text('추가'),
        ),
      ),
    );
  }
}
