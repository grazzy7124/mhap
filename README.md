# 🌍 **WhatApp - 위치 기반 소셜 포토 앱**

> **친구들과 함께 방문한 장소를 공유하고 추억을 기록하는 위치 기반 소셜 포토 애플리케이션**

## 📱 **앱 개요**

WhatApp은 사용자가 방문한 장소에 사진을 찍고, 친구들과 위치 정보를 공유하며, 지도에서 방문 기록을 시각적으로 확인할 수 있는 소셜 앱입니다.

### ✨ **주요 기능**
- 📸 **카메라 & 갤러리**: 장소별 사진 촬영 및 업로드
- 🗺️ **Google Maps 통합**: 실제 지도에서 방문 장소 표시
- 👥 **친구 관리**: 친구별 방문 장소 필터링 및 공유
- 🔐 **소셜 로그인**: Google, Apple 계정으로 간편 로그인
- 🎨 **아름다운 UI**: 슬라이드 전환과 애니메이션이 포함된 모던한 디자인

## 🏗️ **프로젝트 구조**

```
whatapp/
├── lib/                          # Flutter 소스 코드
│   ├── main.dart                 # 앱 진입점 및 라우팅
│   ├── firebase_options.dart     # Firebase 설정
│   ├── models/                   # 데이터 모델
│   │   ├── daily_route.dart      # 일일 경로 모델
│   │   ├── gps_route.dart        # GPS 경로 모델
│   │   └── visited_place.dart    # 방문 장소 모델
│   ├── screens/                  # 화면 UI
│   │   ├── splash_screen.dart    # 스플래시 화면 (지구 애니메이션)
│   │   ├── onboarding_screen.dart # 온보딩/로그인 화면
│   │   ├── main_page.dart        # 메인 페이지 (탭 네비게이션)
│   │   ├── camera_screen.dart    # 카메라 및 갤러리 화면
│   │   ├── map_screen.dart       # 지도 화면 (Google Maps)
│   │   ├── friends_route_screen.dart # 친구 경로 화면
│   │   ├── profile_screen.dart   # 프로필 화면
│   │   ├── shopping_screen.dart  # 쇼핑 화면 (이모지, 테마)
│   │   └── upload_screen.dart    # 사진 업로드 화면
│   ├── services/                 # 비즈니스 로직
│   │   ├── firebase_service.dart # Firebase 인증 및 데이터베이스
│   │   ├── daily_route_service.dart # 일일 경로 관리
│   │   ├── map_service.dart      # 지도 관련 서비스
│   │   └── friend_service.dart   # 친구 관리 서비스
│   ├── widgets/                  # 재사용 가능한 위젯
│   │   └── route_map_widget.dart # 경로 지도 위젯
│   └── utils/                    # 유틸리티
│       └── gps_route_generator.dart # GPS 경로 생성기
├── ios/                          # iOS 네이티브 코드
│   ├── Runner/                   # iOS 앱 설정
│   ├── Podfile                   # CocoaPods 의존성
│   └── GoogleService-Info.plist  # Firebase iOS 설정
├── android/                      # Android 네이티브 코드
│   ├── app/                      # Android 앱 설정
│   └── google-services.json      # Firebase Android 설정
└── pubspec.yaml                  # Flutter 의존성 관리
```

## 🚀 **시작하기**

### **필수 요구사항**
- Flutter SDK 3.0.0 이상
- Dart SDK 3.0.0 이상
- iOS 14.0 이상 / Android API 21 이상
- Xcode 14.0 이상 (iOS 개발용)
- Android Studio (Android 개발용)

### **설치 및 실행**

1. **프로젝트 클론**
```bash
git clone <repository-url>
cd whatapp
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **iOS 설정 (macOS)**
```bash
cd ios
pod install
cd ..
```

4. **앱 실행**
```bash
# 시뮬레이터/에뮬레이터에서 실행
flutter run

# 특정 디바이스에서 실행
flutter devices
flutter run -d <device-id>
```

## 🔧 **주요 기술 스택**

### **Frontend**
- **Flutter**: 크로스 플랫폼 UI 프레임워크
- **Dart**: 프로그래밍 언어
- **Material Design**: UI 디자인 시스템

### **Backend & Services**
- **Firebase**: 백엔드 서비스
  - **Authentication**: Google/Apple 소셜 로그인
  - **Firestore**: 실시간 데이터베이스
  - **Storage**: 사진 및 파일 저장
- **Google Maps**: 지도 및 위치 서비스

### **네이티브 통합**
- **iOS**: CocoaPods, Google Maps iOS SDK
- **Android**: Gradle, Google Maps Android SDK

## 📱 **화면별 상세 설명**

### **1. 스플래시 화면 (`splash_screen.dart`)**
- 🌍 **회전하는 지구 애니메이션**
- 📍 **사용자 GPS 위치에 핀 드롭 애니메이션**
- 🎨 **부드러운 색상 전환 효과**

### **2. 온보딩 화면 (`onboarding_screen.dart`)**
- 🔐 **소셜 로그인**: Google, Apple 계정
- 📝 **회원가입/로그인 폼**
- 🎨 **그라데이션 배경과 모던한 UI**

### **3. 메인 페이지 (`main_page.dart`)**
- 📱 **하단 탭 네비게이션**
- 🔄 **PageView를 통한 슬라이드 전환**
- 👤 **프로필 메뉴 및 로그아웃 기능**

### **4. 카메라 화면 (`camera_screen.dart`)**
- 📸 **카메라 촬영 및 갤러리 선택**
- 📍 **GPS 위치 태깅**
- 🖼️ **사진 미리보기 및 편집**

### **5. 지도 화면 (`map_screen.dart`)**
- 🗺️ **Google Maps 통합**
- 📍 **커스텀 핀과 마커**
- 👥 **친구별 필터링**
- 🔍 **자유로운 지도 탐색**
- 📱 **터치 제스처 지원**

## 🔐 **인증 시스템**

### **Google 로그인**
```dart
// Firebase Auth를 통한 Google 로그인
static Future<UserCredential> signInWithGoogle() async {
  final googleProvider = GoogleAuthProvider();
  return await auth.signInWithProvider(googleProvider);
}
```
## 🗺️ **지도 기능**

### **Google Maps 통합**
- **실시간 위치 추적**
- **커스텀 마커 및 핀**
- **사진 썸네일 오버레이**
- **위치 상세 정보 표시**

### **위치 데이터 구조**
```dart
class MapLocation {
  final double latitude;
  final double longitude;
  final String friendName;
  final String photoUrl;
  final String locationName;
  final DateTime visitDate;
}
```

## 📊 **데이터 모델**

### **방문 장소 (`visited_place.dart`)**
```dart
class VisitedPlace {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final DateTime visitDate;
  final String friendId;
}
```

### **일일 경로 (`daily_route.dart`)**
```dart
class DailyRoute {
  final String id;
  final DateTime date;
  final List<VisitedPlace> places;
  final double totalDistance;
}
```

## 🎨 **UI/UX 특징**

### **애니메이션**
- **슬라이드 전환**: 화면 간 부드러운 이동
- **페이드 인/아웃**: 자연스러운 등장/사라짐
- **스케일 애니메이션**: 버튼 및 카드 상호작용

### **디자인 시스템**
- **Material Design 3**: 최신 디자인 가이드라인
- **반응형 레이아웃**: 다양한 화면 크기 지원
- **다크/라이트 테마**: 사용자 선호도 지원

## 🔧 **개발 환경 설정**

### **iOS 개발**
1. **Xcode에서 `ios/Runner.xcworkspace` 열기**
2. **개발자 계정 설정**
3. **시뮬레이터 또는 실제 디바이스 연결**

### **Android 개발**
1. **Android Studio에서 프로젝트 열기**
2. **AVD 에뮬레이터 설정**
3. **Google Maps API 키 설정**

## 📋 **환경 변수 및 API 키**

### **필수 API 키**
- **Google Maps API Key**: `android/app/src/main/AndroidManifest.xml`
- **Firebase 설정**: `google-services.json`, `GoogleService-Info.plist`

### **권한 설정**
```xml
<!-- Android -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />

<!-- iOS -->
<key>NSCameraUsageDescription</key>
<string>사진 촬영을 위해 카메라 접근이 필요합니다.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>위치 기반 서비스를 위해 위치 접근이 필요합니다.</string>
```

## 🚀 **빌드 및 배포**

### **개발 빌드**
```bash
# iOS
flutter build ios --debug

# Android
flutter build apk --debug
```

### **프로덕션 빌드**
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
```

## 🐛 **문제 해결**

### **일반적인 문제들**

1. **CocoaPods 오류**
```bash
cd ios
pod deintegrate
rm -rf Pods Podfile.lock
pod install --repo-update
```

2. **Flutter 캐시 문제**
```bash
flutter clean
flutter pub get
```

3. **Google Maps 로딩 문제**
- API 키 확인
- 인터넷 연결 상태 확인
- 권한 설정 확인

## 🤝 **기여하기**

1. **Fork** 프로젝트
2. **Feature branch** 생성 (`git checkout -b feature/AmazingFeature`)
3. **Commit** 변경사항 (`git commit -m 'Add some AmazingFeature'`)
4. **Push** 브랜치 (`git push origin feature/AmazingFeature`)
5. **Pull Request** 생성

## 📄 **라이선스**

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 👥 **개발팀**

### **주요 개발자**
- **Jeong Tae Ju**: 프로젝트 리드, 전체 아키텍처 설계
- **박예은**: UI/UX 디자인, 프론트엔드 개발

### **기여 영역**
- **Jeong Tae Ju**: 
  - Flutter 앱 구조 설계
  - Firebase 백엔드 연동
  - Google Maps 통합
  - 인증 시스템 구현
  
- **박예은**:
  - 사용자 인터페이스 디자인
  - 애니메이션 및 전환 효과
  - 사용자 경험 최적화
  - 반응형 레이아웃 구현

## 🙏 **감사의 말**

- **Flutter Team**: 훌륭한 크로스 플랫폼 프레임워크 제공
- **Firebase Team**: 강력한 백엔드 서비스 제공
- **Google Maps Team**: 정확한 지도 서비스 제공

---

**⭐ 이 프로젝트가 도움이 되었다면 Star를 눌러주세요!**
