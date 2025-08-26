import 'dart:math';
import '../models/gps_route.dart';

class GPSRouteGenerator {
  // 서울 지역 주요 장소들의 GPS 좌표
  static final Map<String, GPSLocation> _seoulLocations = {
    '강남역': GPSLocation(37.4979, 127.0276),
    '홍대입구': GPSLocation(37.5571, 126.9254),
    '서울숲': GPSLocation(37.5446, 127.0370),
    '이태원': GPSLocation(37.5344, 126.9941),
    '명동': GPSLocation(37.5636, 126.9834),
    '동대문': GPSLocation(37.5714, 127.0095),
    '잠실': GPSLocation(37.5139, 127.1006),
    '신촌': GPSLocation(37.5551, 126.9368),
    '건대입구': GPSLocation(37.5404, 127.0662),
    '합정': GPSLocation(37.5495, 126.9139),
    '망원': GPSLocation(37.5563, 126.9100),
    '상수': GPSLocation(37.5478, 126.9220),
    '광흥창': GPSLocation(37.5474, 126.9319),
    '대흥': GPSLocation(37.5478, 126.9420),
    '공덕': GPSLocation(37.5446, 126.9510),
    '용산': GPSLocation(37.5298, 126.9644),
    '한강진': GPSLocation(37.5392, 126.9860),
    '버티고개': GPSLocation(37.5480, 126.9870),
    '약수': GPSLocation(37.5546, 126.9830),
    '동대입구': GPSLocation(37.5590, 127.0050),
    '충무로': GPSLocation(37.5614, 127.0050),
    '을지로3가': GPSLocation(37.5660, 127.0080),
    '을지로4가': GPSLocation(37.5660, 127.0090),
    '동대문역사문화공원': GPSLocation(37.5650, 127.0090),
    '신당': GPSLocation(37.5650, 127.0160),
    '상왕십리': GPSLocation(37.5640, 127.0290),
    '왕십리': GPSLocation(37.5610, 127.0370),
    '한양대': GPSLocation(37.5550, 127.0430),
    '뚝섬': GPSLocation(37.5470, 127.0470),
    '성수': GPSLocation(37.5440, 127.0550),
    '건대입구': GPSLocation(37.5400, 127.0660),
    '구의': GPSLocation(37.5370, 127.0850),
    '강변': GPSLocation(37.5350, 127.0950),
    '잠실나루': GPSLocation(37.5200, 127.1030),
    '잠실': GPSLocation(37.5130, 127.1000),
    '잠실새내': GPSLocation(37.5110, 127.0860),
    '종합운동장': GPSLocation(37.5100, 127.0730),
    '삼성중앙': GPSLocation(37.5080, 127.0630),
    '선릉': GPSLocation(37.5040, 127.0490),
    '역삼': GPSLocation(37.5000, 127.0370),
    '강남': GPSLocation(37.4970, 127.0270),
    '교대': GPSLocation(37.4930, 127.0140),
    '남부터미널': GPSLocation(37.4850, 127.0160),
    '양재': GPSLocation(37.4840, 127.0340),
    '매봉': GPSLocation(37.4860, 127.0470),
    '도곡': GPSLocation(37.4900, 127.0550),
    '대치': GPSLocation(37.4940, 127.0630),
    '학여울': GPSLocation(37.4960, 127.0710),
    '대청': GPSLocation(37.4980, 127.0790),
    '일원': GPSLocation(37.5000, 127.0870),
    '수서': GPSLocation(37.5020, 127.0950),
    '가락시장': GPSLocation(37.5040, 127.1030),
    '문정': GPSLocation(37.5060, 127.1110),
    '장지': GPSLocation(37.5080, 127.1190),
    '복정': GPSLocation(37.5100, 127.1270),
    '남태령': GPSLocation(37.5120, 127.1350),
    '사당': GPSLocation(37.5140, 127.1430),
    '낙성대': GPSLocation(37.5160, 127.1510),
    '서울대입구': GPSLocation(37.5180, 127.1590),
    '봉천': GPSLocation(37.5200, 127.1670),
    '신림': GPSLocation(37.5220, 127.1750),
    '신대방': GPSLocation(37.5240, 127.1830),
    '구로디지털단지': GPSLocation(37.5260, 127.1910),
    '대림': GPSLocation(37.5280, 127.1990),
    '신도림': GPSLocation(37.5300, 127.2070),
    '문래': GPSLocation(37.5320, 127.2150),
    '영등포구청': GPSLocation(37.5340, 127.2230),
    '당산': GPSLocation(37.5360, 127.2310),
    '합정': GPSLocation(37.5490, 126.9130),
    '상수': GPSLocation(37.5470, 126.9220),
    '광흥창': GPSLocation(37.5470, 126.9310),
    '대흥': GPSLocation(37.5470, 126.9420),
    '공덕': GPSLocation(37.5440, 126.9510),
    '용산': GPSLocation(37.5290, 126.9640),
    '한강진': GPSLocation(37.5390, 126.9860),
    '버티고개': GPSLocation(37.5480, 126.9870),
    '약수': GPSLocation(37.5540, 126.9830),
    '동대입구': GPSLocation(37.5590, 127.0050),
    '충무로': GPSLocation(37.5610, 127.0050),
    '을지로3가': GPSLocation(37.5660, 127.0080),
    '을지로4가': GPSLocation(37.5660, 127.0090),
    '동대문역사문화공원': GPSLocation(37.5650, 127.0090),
    '신당': GPSLocation(37.5650, 127.0160),
    '상왕십리': GPSLocation(37.5640, 127.0290),
    '왕십리': GPSLocation(37.5610, 127.0370),
    '한양대': GPSLocation(37.5550, 127.0430),
    '뚝섬': GPSLocation(37.5470, 127.0470),
    '성수': GPSLocation(37.5440, 127.0550),
  };

  // 랜덤 동선 생성
  static GPSRoute generateRandomRoute({
    required String routeName,
    required DateTime date,
    int minPoints = 3,
    int maxPoints = 8,
  }) {
    final random = Random();
    final locationNames = _seoulLocations.keys.toList();
    final pointCount = random.nextInt(maxPoints - minPoints + 1) + minPoints;

    // 랜덤하게 장소들을 선택
    final selectedLocations = <String>[];
    for (int i = 0; i < pointCount; i++) {
      String location;
      do {
        location = locationNames[random.nextInt(locationNames.length)];
      } while (selectedLocations.contains(location));
      selectedLocations.add(location);
    }

    // GPS 포인트 생성
    final routePoints = <GPSRoutePoint>[];
    double totalDistance = 0.0;
    DateTime currentTime = date.add(const Duration(hours: 9)); // 오전 9시부터 시작

    for (int i = 0; i < selectedLocations.length; i++) {
      final locationName = selectedLocations[i];
      final location = _seoulLocations[locationName]!;

      // 이전 포인트와의 거리 계산
      if (i > 0) {
        final prevPoint = routePoints[i - 1];
        final distance = _calculateDistance(
          prevPoint.latitude,
          prevPoint.longitude,
          location.latitude,
          location.longitude,
        );
        totalDistance += distance;

        // 이동 시간 계산 (평균 속도 4km/h 가정)
        final travelTime = Duration(
          minutes: (distance * 15).round(),
        ); // 4km/h = 15분/km
        currentTime = currentTime.add(travelTime);
      }

      // 체류 시간 (10분~2시간)
      final stayTime = Duration(minutes: random.nextInt(110) + 10);
      currentTime = currentTime.add(stayTime);

      routePoints.add(
        GPSRoutePoint(
          latitude: location.latitude,
          longitude: location.longitude,
          name: locationName,
          timestamp: currentTime,
          accuracy: random.nextDouble() * 10 + 5, // 5-15m 정확도
          altitude: random.nextDouble() * 50 + 20, // 20-70m 고도
          speed: random.nextDouble() * 2 + 0.5, // 0.5-2.5 m/s
          heading: random.nextDouble() * 360, // 0-360도 방향
        ),
      );
    }

    final totalDuration = currentTime.difference(
      date.add(const Duration(hours: 9)),
    );

    return GPSRoute(
      id: 'route_${date.millisecondsSinceEpoch}',
      name: routeName,
      date: date,
      routePoints: routePoints,
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      photos: _generateRandomPhotos(routePoints.length),
    );
  }

  // 두 지점 간의 거리 계산 (Haversine 공식)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // 지구 반지름 (km)

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // 랜덤 사진 URL 생성
  static List<String> _generateRandomPhotos(int count) {
    final random = Random();
    final photos = <String>[];

    for (int i = 0; i < count; i++) {
      if (random.nextBool()) {
        // 50% 확률로 사진 추가
        photos.add(
          'https://picsum.photos/400/400?random=${random.nextInt(1000)}',
        );
      }
    }

    return photos;
  }

  // 미리 정의된 동선들
  static List<GPSRoute> getPredefinedRoutes() {
    final now = DateTime.now();

    return [
      generateRandomRoute(
        routeName: '강남 데이트 코스',
        date: now.subtract(const Duration(days: 0)),
        minPoints: 4,
        maxPoints: 6,
      ),
      generateRandomRoute(
        routeName: '홍대 문화 탐방',
        date: now.subtract(const Duration(days: 1)),
        minPoints: 3,
        maxPoints: 5,
      ),
      generateRandomRoute(
        routeName: '서울숲 산책',
        date: now.subtract(const Duration(days: 2)),
        minPoints: 2,
        maxPoints: 4,
      ),
      generateRandomRoute(
        routeName: '이태원 맛집 투어',
        date: now.subtract(const Duration(days: 3)),
        minPoints: 3,
        maxPoints: 5,
      ),
      generateRandomRoute(
        routeName: '명동 쇼핑',
        date: now.subtract(const Duration(days: 4)),
        minPoints: 2,
        maxPoints: 4,
      ),
    ];
  }

  // 특정 지역 주변 동선 생성
  static GPSRoute generateAreaRoute({
    required String areaName,
    required GPSLocation center,
    required double radius, // km
    required DateTime date,
    int pointCount = 5,
  }) {
    final random = Random();
    final routePoints = <GPSRoutePoint>[];
    double totalDistance = 0.0;
    DateTime currentTime = date.add(const Duration(hours: 9));

    // 중심점에서 시작
    routePoints.add(
      GPSRoutePoint(
        latitude: center.latitude,
        longitude: center.longitude,
        name: areaName,
        timestamp: currentTime,
        accuracy: random.nextDouble() * 10 + 5,
        altitude: random.nextDouble() * 50 + 20,
        speed: 0.0,
        heading: 0.0,
      ),
    );

    // 반경 내 랜덤 포인트들 생성
    for (int i = 1; i < pointCount; i++) {
      // 반경 내 랜덤 좌표 생성
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius;

      final dLat = distance / 111.0; // 1도 = 약 111km
      final dLon = distance / (111.0 * cos(center.latitude * pi / 180));

      final newLat = center.latitude + (random.nextBool() ? 1 : -1) * dLat;
      final newLon = center.longitude + (random.nextBool() ? 1 : -1) * dLon;

      // 이전 포인트와의 거리 계산
      final prevPoint = routePoints[i - 1];
      final distanceToPrev = _calculateDistance(
        prevPoint.latitude,
        prevPoint.longitude,
        newLat,
        newLon,
      );
      totalDistance += distanceToPrev;

      // 이동 시간 계산
      final travelTime = Duration(minutes: (distanceToPrev * 15).round());
      currentTime = currentTime.add(travelTime);

      // 체류 시간
      final stayTime = Duration(minutes: random.nextInt(110) + 10);
      currentTime = currentTime.add(stayTime);

      routePoints.add(
        GPSRoutePoint(
          latitude: newLat,
          longitude: newLon,
          name: '$areaName 주변 $i',
          timestamp: currentTime,
          accuracy: random.nextDouble() * 10 + 5,
          altitude: random.nextDouble() * 50 + 20,
          speed: random.nextDouble() * 2 + 0.5,
          heading: random.nextDouble() * 360,
        ),
      );
    }

    final totalDuration = currentTime.difference(
      date.add(const Duration(hours: 9)),
    );

    return GPSRoute(
      id: 'area_route_${date.millisecondsSinceEpoch}',
      name: '$areaName 탐방',
      date: date,
      routePoints: routePoints,
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      photos: _generateRandomPhotos(pointCount),
    );
  }
}

// GPS 위치 클래스
class GPSLocation {
  final double latitude;
  final double longitude;

  const GPSLocation(this.latitude, this.longitude);
}
