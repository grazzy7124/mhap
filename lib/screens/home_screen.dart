import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<FeedItem> _feedItems = [
    FeedItem(
      id: '1',
      userName: '김철수',
      userProfileImage: 'https://via.placeholder.com/50',
      locationName: '강남역 카페',
      imageUrl: 'https://via.placeholder.com/400x400',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 15,
      comments: 3,
    ),
    FeedItem(
      id: '2',
      userName: '이영희',
      userProfileImage: 'https://via.placeholder.com/50',
      locationName: '홍대 거리',
      imageUrl: 'https://via.placeholder.com/400x400',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      likes: 23,
      comments: 7,
    ),
    FeedItem(
      id: '3',
      userName: '박민수',
      userProfileImage: 'https://via.placeholder.com/50',
      locationName: '서울숲',
      imageUrl: 'https://via.placeholder.com/400x400',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      likes: 31,
      comments: 12,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'WhatApp',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // 알림 페이지로 이동
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 검색 페이지로 이동
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 피드 새로고침
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _feedItems.length,
          itemBuilder: (context, index) {
            return _buildFeedItem(_feedItems[index]);
          },
        ),
      ),
    );
  }

  Widget _buildFeedItem(FeedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: CachedNetworkImageProvider(
                    item.userProfileImage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatTimestamp(item.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    // 더보기 메뉴
                  },
                ),
              ],
            ),
          ),

          // 이미지
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              ),

              // 위치 정보 (좌측 하단)
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.locationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 액션 버튼들
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    item.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: item.isLiked ? Colors.red : null,
                  ),
                  onPressed: () {
                    setState(() {
                      item.isLiked = !item.isLiked;
                      if (item.isLiked) {
                        item.likes++;
                      } else {
                        item.likes--;
                      }
                    });
                  },
                ),
                Text(
                  '${item.likes}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    // 댓글 페이지로 이동
                  },
                ),
                Text(
                  '${item.comments}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    // 공유 기능
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}

class FeedItem {
  final String id;
  final String userName;
  final String userProfileImage;
  final String locationName;
  final String imageUrl;
  final DateTime timestamp;
  int likes;
  final int comments;
  bool isLiked;

  FeedItem({
    required this.id,
    required this.userName,
    required this.userProfileImage,
    required this.locationName,
    required this.imageUrl,
    required this.timestamp,
    required this.likes,
    required this.comments,
    this.isLiked = false,
  });
}
