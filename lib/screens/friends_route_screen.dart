import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/gps_route.dart';
import '../utils/gps_route_generator.dart';

class FriendsRouteScreen extends StatefulWidget {
  const FriendsRouteScreen({super.key});

  @override
  State<FriendsRouteScreen> createState() => _FriendsRouteScreenState();
}

class _FriendsRouteScreenState extends State<FriendsRouteScreen> {
  int _selectedDateIndex = 0;
  final List<String> _dates = ['오늘', '어제', '2일 전', '3일 전', '이번 주'];

  final List<GPSRoute> _friendRoutes = [];

  @override
  void initState() {
    super.initState();
    _generateFriendRoutes();
  }

  void _generateFriendRoutes() {
    final routes = GPSRouteGenerator.getPredefinedRoutes();
    setState(() {
      _friendRoutes.addAll(routes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '친구 동선',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // 필터 옵션
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 날짜 선택 탭
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _dates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final date = entry.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDateIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedDateIndex == index
                            ? Colors.green
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        date,
                        style: TextStyle(
                          color: _selectedDateIndex == index
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: _selectedDateIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 친구 동선 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _friendRoutes.length,
              itemBuilder: (context, index) {
                return _buildFriendRouteCard(_friendRoutes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRouteCard(GPSRoute route) {
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
          // 동선 정보 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.route, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(route.date),
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

          // 동선 요약 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildRouteInfo(
                  icon: Icons.route,
                  label: '거리',
                  value: '${route.totalDistance}km',
                ),
                const SizedBox(width: 24),
                _buildRouteInfo(
                  icon: Icons.access_time,
                  label: '시간',
                  value: _formatDuration(route.totalDuration),
                ),
                const SizedBox(width: 24),
                _buildRouteInfo(
                  icon: Icons.photo_camera,
                  label: '사진',
                  value: '${route.photos.length}장',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 동선 지도 (간단한 표현)
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // 동선 경로 표시
                CustomPaint(
                  size: const Size(double.infinity, double.infinity),
                  painter: GPSRoutePainter(route.routePoints),
                ),

                // 위치 핀들
                ...route.routePoints
                    .map(
                      (point) => Positioned(
                        left: _getRelativeX(point.longitude),
                        top: _getRelativeY(point.latitude),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 사진들
          if (route.photos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '촬영된 사진들',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: route.photos.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(route.photos[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 액션 버튼들
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showRouteDetail(route);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('상세 동선 보기'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _likeRoute(route);
                    },
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('좋아요'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  double _getRelativeX(double longitude) {
    // 서울 지역 경도 범위: 126.5 ~ 127.2
    // 화면 너비에 맞게 정규화
    const double minLon = 126.5;
    const double maxLon = 127.2;
    const double padding = 0.1; // 여백

    final normalizedLon =
        (longitude - (minLon - padding)) /
        ((maxLon + padding) - (minLon - padding));
    return normalizedLon.clamp(0.0, 1.0) * 300; // 300은 컨테이너 너비
  }

  double _getRelativeY(double latitude) {
    // 서울 지역 위도 범위: 37.4 ~ 37.7
    // 화면 높이에 맞게 정규화
    const double minLat = 37.4;
    const double maxLat = 37.7;
    const double padding = 0.05; // 여백

    final normalizedLat =
        (latitude - (minLat - padding)) /
        ((maxLat + padding) - (minLat - padding));
    return (1.0 - normalizedLat.clamp(0.0, 1.0)) * 120; // 120은 컨테이너 높이, Y축은 반전
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else {
      return '${difference.inDays}일 전';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}시간 ${duration.inMinutes % 60}분';
    } else {
      return '${duration.inMinutes}분';
    }
  }

  void _showRouteDetail(GPSRoute route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 제목
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.route, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(route.date),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 동선 요약 정보
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRouteInfo(
                      icon: Icons.route,
                      label: '거리',
                      value: '${route.totalDistance.toStringAsFixed(1)}km',
                    ),
                    _buildRouteInfo(
                      icon: Icons.access_time,
                      label: '시간',
                      value: _formatDuration(route.totalDuration),
                    ),
                    _buildRouteInfo(
                      icon: Icons.place,
                      label: '장소',
                      value: '${route.routePoints.length}개',
                    ),
                    _buildRouteInfo(
                      icon: Icons.photo_camera,
                      label: '사진',
                      value: '${route.photos.length}장',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 지도 영역
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // 지도 배경 (간단한 표현)
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            image: const DecorationImage(
                              image: NetworkImage('https://picsum.photos/400/300?random=map'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        
                        // 동선 경로
                        CustomPaint(
                          size: const Size(double.infinity, double.infinity),
                          painter: GPSRoutePainter(route.routePoints),
                        ),
                        
                        // 위치 핀들
                        ...route.routePoints.asMap().entries.map((entry) {
                          final index = entry.key;
                          final point = entry.value;
                          return Positioned(
                            left: _getRelativeX(point.longitude),
                            top: _getRelativeY(point.latitude),
                            child: Column(
                              children: [
                                // 핀
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: index == 0 ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: index == 0
                                      ? const Icon(Icons.play_arrow, color: Colors.white, size: 10)
                                      : null,
                                ),
                                
                                // 장소명
                                if (index < 3) // 처음 3개만 표시
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      point.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 동선 포인트 목록
              Container(
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: route.routePoints.length,
                  itemBuilder: (context, index) {
                    final point = route.routePoints[index];
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == 0 ? Colors.green : Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  point.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            point.formattedTime,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            point.coordinates,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _likeRoute(GPSRoute route) {
    // TODO: 좋아요 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('좋아요 기능은 추후 구현 예정입니다.'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class GPSRoutePainter extends CustomPainter {
  final List<GPSRoutePoint> routePoints;

  GPSRoutePainter(this.routePoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.length < 2) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < routePoints.length; i++) {
      final point = routePoints[i];

      // 서울 지역 좌표 범위에 맞게 정규화
      const double minLon = 126.5;
      const double maxLon = 127.2;
      const double minLat = 37.4;
      const double maxLat = 37.7;
      const double padding = 0.1;

      final x =
          ((point.longitude - (minLon - padding)) /
                  ((maxLon + padding) - (minLon - padding)))
              .clamp(0.0, 1.0) *
          size.width;
      final y =
          (1.0 -
              ((point.latitude - (minLat - padding)) /
                      ((maxLat + padding) - (minLat - padding)))
                  .clamp(0.0, 1.0)) *
          size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
