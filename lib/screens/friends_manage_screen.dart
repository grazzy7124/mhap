import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/friend_models.dart';
import '../services/friend_service.dart';

/// 친구 관리 페이지 (SNS 기능 구현)
/// - 상단: 검정 AppBar + 뒤로가기
/// - 탭: 친구추가 / 내 친구 / 신청목록 (세그먼트 스타일)
/// - 배경: 핑크→오렌지 그라데이션
/// - 기능: 친구 검색, 친구 추가, 친구 삭제, 요청 수락/거절
class FriendsManageScreen extends StatefulWidget {
  const FriendsManageScreen({super.key});

  @override
  State<FriendsManageScreen> createState() => _FriendsManageScreenState();
}

class _FriendsManageScreenState extends State<FriendsManageScreen> {
  final TextEditingController _searchController = TextEditingController();
  UserSearchResult? _searchResult;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text(''),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SegmentedTabBar(),
            ),
          ),
        ),
        body: Container(
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
              // 1) 친구추가 탭
              _FriendAddTab(
                searchController: _searchController,
                searchResult: _searchResult,
                isSearching: _isSearching,
                onSearch: _performSearch,
                onSendRequest: _sendFriendRequest,
              ),

              // 2) 내 친구 탭
              const _MyFriendsTab(),

              // 3) 신청목록 탭
              const _FriendRequestsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResult = null;
    });

    try {
      final result = await FriendService.searchUserByUid(query);
      setState(() {
        _searchResult = result;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 오류: $e')),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(String toUserId) async {
    try {
      final success = await FriendService.sendFriendRequest(toUserId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('친구 요청을 보냈습니다!')),
        );
        // 검색 결과 업데이트
        _performSearch();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요청 전송 실패: $e')),
        );
      }
    }
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14), 
          topRight: Radius.circular(14)
        ),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFFDD3397),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10), 
            topRight: Radius.circular(10)
          ),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xffC8C8C8),
        tabs: const [
          Tab(text: '친구추가'),
          Tab(text: '내 친구'),
          Tab(text: '신청목록'),
        ],
      ),
    );
  }
}

/// 친구 추가 탭
class _FriendAddTab extends StatelessWidget {
  final TextEditingController searchController;
  final UserSearchResult? searchResult;
  final bool isSearching;
  final VoidCallback onSearch;
  final Function(String) onSendRequest;

  const _FriendAddTab({
    required this.searchController,
    required this.searchResult,
    required this.isSearching,
    required this.onSearch,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          // 검색 입력창
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: Color(0xffD9D9D9),
              borderRadius: BorderRadius.circular(27),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'ID 검색',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, 
                  vertical: 15
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: onSearch,
                ),
              ),
              onSubmitted: (_) => onSearch(),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 검색 결과 또는 안내 메시지
          Expanded(
            child: _buildSearchContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    if (isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (searchResult == null) {
      return const Center(
        child: Text(
          '유저 ID를 입력하고 검색해보세요',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return _SearchResultCard(
      result: searchResult!,
      onSendRequest: onSendRequest,
    );
  }
}

/// 검색 결과 카드
class _SearchResultCard extends StatelessWidget {
  final UserSearchResult result;
  final Function(String) onSendRequest;

  const _SearchResultCard({
    required this.result,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 프로필 정보
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: result.photoURL != null 
                      ? NetworkImage(result.photoURL!) 
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: result.photoURL == null 
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${result.uid}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 상태 및 액션 버튼
            if (result.isAlreadyFriend)
              const _StatusChip(
                label: '이미 친구',
                color: Colors.green,
                icon: Icons.check_circle,
              )
            else if (result.hasPendingRequest)
              const _StatusChip(
                label: '요청 대기중',
                color: Colors.orange,
                icon: Icons.schedule,
              )
            else
              _PillButton(
                label: '친구 추가',
                onPressed: () => onSendRequest(result.uid),
                color: const Color(0xFFDD3397),
              ),
          ],
        ),
      ),
    );
  }
}

/// 상태 칩
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// 내 친구 탭
class _MyFriendsTab extends StatelessWidget {
  const _MyFriendsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Friend>>(
      stream: FriendService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '오류가 발생했습니다: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return const Center(
            child: Text(
              '아직 친구가 없습니다',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: friends.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _FriendRow(friend: friends[index]);
          },
        );
      },
    );
  }
}

/// 친구 한 줄
class _FriendRow extends StatelessWidget {
  final Friend friend;

  const _FriendRow({required this.friend});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: friend.photoURL != null 
            ? NetworkImage(friend.photoURL!) 
            : null,
        backgroundColor: Colors.white24,
        child: friend.photoURL == null 
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        friend.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        '친구 추가: ${_formatDate(friend.addedAt)}',
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: _PillButton(
        label: '삭제',
        onPressed: () => _showDeleteDialog(context),
        color: Colors.white70,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text('${friend.displayName}님을 친구에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteFriend(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFriend(BuildContext context) async {
    try {
      final success = await FriendService.removeFriend(friend.uid);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('친구가 삭제되었습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }
}

/// 친구 요청 탭
class _FriendRequestsTab extends StatelessWidget {
  const _FriendRequestsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FriendRequest>>(
      stream: FriendService.getIncomingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '오류가 발생했습니다: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Text(
              '받은 친구 요청이 없습니다',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _FriendRequestRow(request: requests[index]);
          },
        );
      },
    );
  }
}

/// 친구 요청 한 줄
class _FriendRequestRow extends StatelessWidget {
  final FriendRequest request;

  const _FriendRequestRow({required this.request});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: request.fromUserPhotoURL != null 
            ? NetworkImage(request.fromUserPhotoURL!) 
            : null,
        backgroundColor: Colors.white24,
        child: request.fromUserPhotoURL == null 
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        request.fromUserDisplayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        '요청: ${_formatDate(request.createdAt)}',
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          _PillButton(
            label: '수락',
            onPressed: () => _acceptRequest(context),
            color: Colors.white70,
          ),
          _PillButton(
            label: '삭제',
            onPressed: () => _rejectRequest(context),
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _acceptRequest(BuildContext context) async {
    try {
      final success = await FriendService.acceptFriendRequest(request.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('친구 요청을 수락했습니다!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수락 실패: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(BuildContext context) async {
    try {
      final success = await FriendService.rejectFriendRequest(request.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('친구 요청을 거절했습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('거절 실패: $e')),
        );
      }
    }
  }
}

/// 시안처럼 작은 pill 버튼
class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _PillButton({
    required this.label, 
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: color ?? Colors.white70,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}
