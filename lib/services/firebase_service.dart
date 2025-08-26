import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;
  static FirebaseAuth? _auth;

  static FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  static FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // 사용자 인증 상태 확인
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  // 현재 사용자
  static User? get currentUser => auth.currentUser;

  // 로그인
  static Future<UserCredential> signInAnonymously() async {
    return await auth.signInAnonymously();
  }

  // 로그아웃
  static Future<void> signOut() async {
    await auth.signOut();
  }

  // 방문한 장소 저장
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

  // 방문한 장소 목록 가져오기
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

  // 친구들의 방문한 장소 가져오기
  static Stream<QuerySnapshot> getFriendsVisitedPlaces() {
    return firestore
        .collection('users')
        .snapshots();
  }
}
