import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/map_models.dart';
import '../services/map_service.dart';

/// 마커 위젯 생성 (RepaintBoundary로 감싸서 비트맵 변환 가능하게)
class MarkerWidget extends StatelessWidget {
  final String friendName;
  final GlobalKey markerKey;

  const MarkerWidget({
    super.key,
    required this.friendName,
    required this.markerKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: markerKey,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: MapService.hueToColor(MapService.getMarkerColor(friendName)),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Image.asset(
              MapService.getFriendIconAsset(friendName),
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

/// 현재 위치 상태 오버레이
class CurrentLocationOverlay extends StatelessWidget {
  final Position? currentPosition;
  final bool isLocationLoading;

  const CurrentLocationOverlay({
    super.key,
    required this.currentPosition,
    required this.isLocationLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 56,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.my_location,
                  color: currentPosition != null ? Colors.green : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '현재 위치',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: currentPosition != null ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isLocationLoading
                  ? '확인 중...'
                  : currentPosition != null
                  ? '위치 확인됨'
                  : '위치를 확인할 수 없습니다',
              style: TextStyle(
                fontSize: 10,
                color: currentPosition != null ? Colors.grey[600] : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 친구 필터 위젯 (프로필 아이콘 기반)
class FriendFilterWidget extends StatelessWidget {
  final String selectedFriend;
  final List<String> friends;
  final Function(String) onFriendSelected;
  final VoidCallback onFriendsManage;

  const FriendFilterWidget({
    super.key,
    required this.selectedFriend,
    required this.friends,
    required this.onFriendSelected,
    required this.onFriendsManage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60, // 전체보기와 친구 위젯 높이 통일
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        itemCount:
            2 + friends.where((f) => f != 'all').length, // 전체보기 + 친구관리 + 친구들
        itemBuilder: (context, index) {
          if (index == 0) {
            // 전체 보기 버튼
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onFriendSelected('all'),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: selectedFriend == 'all'
                        ? Colors.blue
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedFriend == 'all'
                          ? Colors.blue
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.grid_view,
                    color: selectedFriend == 'all'
                        ? Colors.white
                        : Colors.grey[600],
                    size: 24,
                  ),
                ),
              ),
            );
          } else if (index == 1) {
            // 친구 관리 버튼
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onFriendsManage,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            );
          } else {
            // 친구들 프로필 아이콘
            final friendIndex = index - 2;
            final friend = friends
                .where((f) => f != 'all')
                .toList()[friendIndex];
            final isSelected = selectedFriend == friend;

            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onFriendSelected(friend),
                child: Stack(
                  children: [
                    // 프로필 이미지 (배경 없음)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                      ),
                      child: ClipOval(child: _buildFriendProfileImage(friend)),
                    ),
                    // 선택 표시
                    if (isSelected)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  /// 친구 프로필 이미지 생성
  Widget _buildFriendProfileImage(String friendName) {
    // 실제 프로필 이미지가 있다면 사용, 없으면 기본 아이콘 사용
    return FutureBuilder<String?>(
      future: _getFriendProfileImage(friendName),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // 실제 프로필 이미지가 있는 경우
          return Image.network(
            snapshot.data!,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultProfileIcon(friendName);
            },
          );
        } else {
          // 기본 프로필 아이콘 사용
          return _buildDefaultProfileIcon(friendName);
        }
      },
    );
  }

  /// 기본 프로필 아이콘 생성
  Widget _buildDefaultProfileIcon(String friendName) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getFriendColor(friendName),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          friendName.substring(0, 1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 친구별 색상 반환
  Color _getFriendColor(String friendName) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    final index = friendName.hashCode % colors.length;
    return colors[index];
  }

  /// 친구 프로필 이미지 URL 가져오기 (Firestore에서)
  Future<String?> _getFriendProfileImage(String friendName) async {
    try {
      // TODO: Firestore에서 친구 프로필 이미지 가져오기
      // 현재는 더미 데이터 반환
      final dummyProfiles = {
        '기노은':
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
        '권하민':
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        '정태주':
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        '박예은':
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
        '이찬민':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
      };

      return dummyProfiles[friendName];
    } catch (e) {
      return null;
    }
  }
}

/// 지도 컨트롤 버튼들
class MapControlButtons extends StatelessWidget {
  final VoidCallback onMyLocation;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final Position? currentPosition;

  const MapControlButtons({
    super.key,
    required this.onMyLocation,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton.small(
            onPressed: onMyLocation,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.my_location,
              color: currentPosition != null ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            onPressed: onZoomIn,
            backgroundColor: Colors.white,
            child: const Icon(Icons.add, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            onPressed: onZoomOut,
            backgroundColor: Colors.white,
            child: const Icon(Icons.remove, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// 리뷰 카드 위젯 (인스타그램 스타일)
class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isFirst;

  const ReviewCard({super.key, required this.review, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 리뷰 헤더 (유저 정보 + 시간)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 유저 아바타
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: MapService.hueToColor(
                      MapService.getMarkerColor(review.friendName),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      review.friendName[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 유저 이름
                Expanded(
                  child: Text(
                    review.friendName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // 시간
                Text(
                  MapService.formatTimestamp(review.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // 사진
          SizedBox(
            width: double.infinity,
            height: 250,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(0),
                bottom: Radius.circular(12),
              ),
              child: review.photoUrl.isNotEmpty
                  ? Image.network(
                      review.photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(
                          '🖼️ 이미지 로딩 실패: ${review.photoUrl} - $error',
                        );
                        return Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 30,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '이미지 로딩 실패',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 50,
                        ),
                      ),
                    ),
            ),
          ),

          // 장소 이름과 별점
          if (review.placeName != null || review.rating != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // 장소 이름
                  if (review.placeName != null)
                    Expanded(
                      child: Text(
                        review.placeName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  // 별점
                  if (review.rating != null)
                    Row(
                      children: List.generate(5, (index) {
                        final isSelected = index < review.rating!;
                        return Icon(
                          isSelected ? Icons.star : Icons.star_border,
                          size: 18,
                          color: isSelected ? Colors.amber : Colors.grey[400],
                        );
                      }),
                    ),
                ],
              ),
            ),

          // 리뷰 코멘트 (있는 경우에만)
          if (review.comment != null && review.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                review.comment!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),

          // 좋아요, 댓글, 공유, 저장 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 좋아요
                GestureDetector(
                  onTap: () {
                    // TODO: 좋아요 기능 구현
                    print('좋아요: ${review.id}');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${review.likes}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // 댓글
                GestureDetector(
                  onTap: () {
                    // TODO: 댓글 기능 구현
                    print('댓글: ${review.id}');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${review.comments}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // 공유
                GestureDetector(
                  onTap: () {
                    // TODO: 공유 기능 구현
                    print('공유: ${review.id}');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '공유',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 저장
                GestureDetector(
                  onTap: () {
                    // TODO: 저장 기능 구현
                    print('저장: ${review.id}');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '저장',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
