import 'package:flutter/material.dart';
import '../models/daily_route.dart';

class RouteMapWidget extends StatelessWidget {
  final DailyRoute route;
  final double height;
  final bool showDetails;

  const RouteMapWidget({
    super.key,
    required this.route,
    this.height = 300,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${route.date.month}월 ${route.date.day}일 동선',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                if (showDetails)
                  Text(
                    '${route.routePoints.length}개 지점',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
              ],
            ),
          ),

          // 지도 영역 (플레이스홀더)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '지도가 여기에 표시됩니다',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '실제 구현에서는 Google Maps나 다른 지도 API를 사용합니다',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 동선 요약 정보
          if (showDetails)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // 총 거리
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.straighten,
                      label: '총 거리',
                      value: '${route.totalDistance.toStringAsFixed(1)}m',
                    ),
                  ),

                  // 구분선
                  Container(height: 40, width: 1, color: Colors.grey.shade300),

                  // 총 시간
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.access_time,
                      label: '총 시간',
                      value: _formatDuration(route.totalDuration),
                    ),
                  ),

                  // 구분선
                  Container(height: 40, width: 1, color: Colors.grey.shade300),

                  // 지점 수
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.location_on,
                      label: '지점 수',
                      value: '${route.routePoints.length}개',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade600),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else {
      return '${minutes}분';
    }
  }
}
