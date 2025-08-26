import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// FirebaseService
///
/// Firebase 초기화/인스턴스 접근, 인증(FirebaseAuth)과
/// Cloud Firestore에 방문 장소를 저장/조회하는 헬퍼입니다.
/// - initialize(): 앱 전체에서 1회 초기화를 권장합니다
/// - authStateChanges/currentUser: 인증 상태 스트림/현재 사용자
/// - saveVisitedPlace(): 내 방문 장소 추가
/// - getVisitedPlaces(): 내 방문 장소 스트림
/// - getFriendsVisitedPlaces(): 친구들(모든 사용자) 방문 장소 스트림 예시
class FirebaseService {
  static FirebaseFirestore? _firestore;
  static FirebaseAuth? _auth;

  /// Firestore 인스턴스(지연 초기화)
  static FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Auth 인스턴스(지연 초기화)
  static FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  /// Firebase 초기화(앱 당 1회 권장)
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  /// 인증 상태 스트림(로그인/로그아웃 이벤트 수신)
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  /// 현재 로그인 사용자
  static User? get currentUser => auth.currentUser;

  /// 익명 로그인(예시)
  static Future<UserCredential> signInAnonymously() async {
    return await auth.signInAnonymously();
  }

  /// 로그아웃
  static Future<void> signOut() async {
    await auth.signOut();
  }

  /// 방문한 장소 저장
  /// - 사용자별 하위 컬렉션(users/{uid}/visited_places)에 추가합니다.
  static Future<void> saveVisitedPlace({
    required String name,
    required double latitude,
    required double longitude,
    required String imageUrl,
    String? description,
  }) async {
    final user = currentUser;
    if (user == null) return;

    await firestore.collection('users').doc(user.uid).collection('visited_places').add({
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// 내 방문한 장소 스트림(최신순)
  static Stream<QuerySnapshot> getVisitedPlaces() {
    final user = currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('visited_places')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// 친구들의 방문 장소 스트림(데모용):
  /// - 실제 서비스에서는 친구 관계 컬렉션을 조인/필터링하세요.
  static Stream<QuerySnapshot> getFriendsVisitedPlaces() {
    return firestore.collection('users').snapshots();
  }
}
