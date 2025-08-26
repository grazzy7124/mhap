import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/gps_route.dart';
import '../utils/gps_route_generator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<VisitedPlace> _visitedPlaces = [
    VisitedPlace(
      id: '1',
      name: '강남역 카페',
      imageUrl: 'https://via.placeholder.com/200x200',
      visitDate: DateTime.now().subtract(const Duration(days: 1)),
      latitude: 37.5668,
      longitude: 126.9785,
    ),
    VisitedPlace(
      id: '2',
      name: '홍대 거리',
      imageUrl: 'https://via.placeholder.com/200x200',
      visitDate: DateTime.now().subtract(const Duration(days: 3)),
      latitude: 37.5580,
      longitude: 126.9255,
    ),
    VisitedPlace(
      id: '3',
      name: '서울숲',
      imageUrl: 'https://via.placeholder.com/200x200',
      visitDate: DateTime.now().subtract(const Duration(days: 5)),
      latitude: 37.5445,
      longitude: 127.0550,
    ),
    VisitedPlace(
      id: '4',
      name: '이태원',
      imageUrl: 'https://via.placeholder.com/200x200',
      visitDate: DateTime.now().subtract(const Duration(days: 7)),
      latitude: 37.5344,
      longitude: 126.9941,
    ),
  ];

  final List<GPSRoute> _dailyRoutes = [];

  @override
  void initState() {
    super.initState();
    _generateDailyRoutes();
  }

  void _generateDailyRoutes() {
    final routes = GPSRouteGenerator.getPredefinedRoutes();
    setState(() {
      _dailyRoutes.addAll(routes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // 프로필 헤더
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.green,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.green.shade400, Colors.green.shade700],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 프로필 이미지
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundImage: CachedNetworkImageProvider(
                            'https://via.placeholder.com/100',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 사용자 이름
                      const Text(
                        '정태주',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // 사용자 상태
                      Text(
                        '활발한 탐험가',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  // 설정 페이지로 이동
                },
              ),
            ],
          ),

          // 통계 정보
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.place,
                    label: '방문 장소',
                    value: '${_visitedPlaces.length}',
                  ),
                  _buildStatItem(
                    icon: Icons.route,
                    label: '총 거리',
                    value: '${_calculateTotalDistance()}km',
                  ),
                  _buildStatItem(
                    icon: Icons.photo_camera,
                    label: '총 사진',
                    value: '${_calculateTotalPhotos()}',
                  ),
                ],
              ),
            ),
          ),

          // 방문한 장소들
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '방문한 장소들',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // 전체 장소 보기
                    },
                    child: const Text('전체 보기'),
                  ),
                ],
              ),
            ),
          ),

          // 장소 그리드
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildPlaceCard(_visitedPlaces[index]);
              }, childCount: _visitedPlaces.length),
            ),
          ),

          // 일일 동선 기록
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '일일 동선 기록',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      _showRouteHistory();
                    },
                    child: const Text('전체 보기'),
                  ),
                ],
              ),
            ),
          ),

          // 동선 기록 목록
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildRouteCard(_dailyRoutes[index]);
            }, childCount: _dailyRoutes.length),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPlaceCard(VisitedPlace place) {
    return Container(
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
          // 장소 이미지
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(place.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 장소 정보
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(place.visitDate),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(GPSRoute route) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // 날짜 정보
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${route.date.day}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  '${route.date.month}월',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // 동선 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.route, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${route.totalDistance}km',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(route.totalDuration),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.place, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text('${route.routePoints.length}개 장소'),
                    const SizedBox(width: 16),
                    Icon(Icons.photo_camera, color: Colors.purple, size: 16),
                    const SizedBox(width: 4),
                    Text('${route.photos}장 사진'),
                  ],
                ),
              ],
            ),
          ),

          // 상세 보기 버튼
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              _showRouteDetail(route);
            },
          ),
        ],
      ),
    );
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

  double _calculateTotalDistance() {
    return _dailyRoutes.fold(0.0, (sum, route) => sum + route.totalDistance);
  }

  int _calculateTotalPhotos() {
    return _dailyRoutes.fold(0, (sum, route) => sum + route.photos.length);
  }

  void _showRouteHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
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

              const Text(
                '동선 기록 히스토리',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _dailyRoutes.length,
                  itemBuilder: (context, index) {
                    return _buildRouteCard(_dailyRoutes[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                            '${_formatDate(route.date)} 동선',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            route.name,
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
                    _buildStatItem(
                      icon: Icons.route,
                      label: '거리',
                      value: '${route.totalDistance.toStringAsFixed(1)}km',
                    ),
                    _buildStatItem(
                      icon: Icons.access_time,
                      label: '시간',
                      value: _formatDuration(route.totalDuration),
                    ),
                    _buildStatItem(
                      icon: Icons.place,
                      label: '장소',
                      value: '${route.routePoints.length}개',
                    ),
                    _buildStatItem(
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
                              image: NetworkImage(
                                'https://picsum.photos/400/300?random=map',
                              ),
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
                                    color: index == 0
                                        ? Colors.green
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: index == 0
                                      ? const Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                          size: 10,
                                        )
                                      : null,
                                ),

                                // 장소명
                                if (index < 3) // 처음 3개만 표시
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
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
                        }),
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
                                  color: index == 0
                                      ? Colors.green
                                      : Colors.blue,
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

  // GPS 좌표 변환 메서드들
  double _getRelativeX(double longitude) {
    // 서울 지역 경도 범위: 126.5 ~ 127.2
    const double minLon = 126.5;
    const double maxLon = 127.2;
    const double padding = 0.1;

    final normalizedLon =
        (longitude - (minLon - padding)) /
        ((maxLon + padding) - (minLon - padding));
    return normalizedLon.clamp(0.0, 1.0) * 300;
  }

  double _getRelativeY(double latitude) {
    // 서울 지역 위도 범위: 37.4 ~ 37.7
    const double minLat = 37.4;
    const double maxLat = 37.7;
    const double padding = 0.05;

    final normalizedLat =
        (latitude - (minLat - padding)) /
        ((maxLat + padding) - (minLat - padding));
    return (1.0 - normalizedLat.clamp(0.0, 1.0)) * 120;
  }
}

// GPS 경로 그리기 클래스
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

class VisitedPlace {
  final String id;
  final String name;
  final String imageUrl;
  final DateTime visitDate;
  final double latitude;
  final double longitude;

  VisitedPlace({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.visitDate,
    required this.latitude,
    required this.longitude,
  });
}
