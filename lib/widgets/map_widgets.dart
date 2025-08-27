import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
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
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
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
      top: 50,
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

/// 친구 필터 위젯
class FriendFilterWidget extends StatelessWidget {
  final String selectedFriend;
  final List<String> friends;
  final Function(String) onFriendSelected;

  const FriendFilterWidget({
    super.key,
    required this.selectedFriend,
    required this.friends,
    required this.onFriendSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            final isSelected = selectedFriend == friend;
            return GestureDetector(
              onTap: () => onFriendSelected(friend),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    friend == 'all' ? '전체' : friend,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
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

  const ReviewCard({
    super.key,
    required this.review,
    required this.isFirst,
  });

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
                    color: MapService.hueToColor(MapService.getMarkerColor(review.friendName)),
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
          Container(
            width: double.infinity,
            height: 250,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(0),
                bottom: Radius.circular(12),
              ),
              child: Image.network(
                review.photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.red, size: 50),
                  );
                },
              ),
            ),
          ),

          // 리뷰 코멘트 (있는 경우에만)
          if (review.comment != null && review.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                review.comment!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
