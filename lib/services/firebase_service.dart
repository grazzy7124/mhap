// lib/services/firebase_service.dart
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// google_sign_in 패키지 없이 Firebase Auth의 OAuth Provider 사용

import 'package:flutter/foundation.dart';

/// FirebaseService: Firebase 초기화 + 인증 전용
/// - initialize()
/// - authStateChanges/currentUser/signOut()
/// - signInWithGoogle(), signInWithApple()
/// - ensureUserProfile(): users/{uid} 생성/갱신
class FirebaseService {
  static FirebaseFirestore? _firestore;
  static FirebaseAuth? _auth;
  static bool _isInitialized = false;

  static FirebaseFirestore get firestore =>
      _firestore ??= FirebaseFirestore.instance;

  static FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;

  static Future<void> initialize({FirebaseOptions? options}) async {
    // 이미 초기화된 경우 중복 초기화 방지
    if (_isInitialized && Firebase.apps.isNotEmpty) {
      debugPrint('Firebase already initialized, skipping...');
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        if (options != null) {
          await Firebase.initializeApp(options: options);
          debugPrint('Firebase initialized with custom options');
        } else {
          // options가 없으면 기본 설정으로 초기화
          await Firebase.initializeApp();
          debugPrint('Firebase initialized with default options');
        }
      } else {
        debugPrint('Firebase already initialized, skipping...');
      }

      // Firebase가 실제로 초기화되었는지 확인
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase initialization failed - no apps available');
      }

      // Web 환경에서 리다이렉트 세션 저장 문제 방지: LOCAL 지속성 사용
      if (kIsWeb) {
        try {
          await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
        } catch (_) {
          // ignore persistence errors on non-web
        }
      }

      _isInitialized = true;
      debugPrint('Firebase service initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  static Stream<User?> get authStateChanges => auth.authStateChanges();

  static User? get currentUser => auth.currentUser;

  static Future<void> signOut() => auth.signOut();

  // ----------------------------
  // Google Login
  // ----------------------------
  static Future<UserCredential> signInWithGoogle() async {
    try {
      debugPrint('Starting Google sign in...');

      // Firebase가 초기화되었는지 확인
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase가 초기화되지 않았습니다. 앱을 다시 시작해주세요.');
      }

      // Firebase Auth의 GoogleAuthProvider로 직접 로그인
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      debugPrint('Google provider created, attempting sign in...');

      // Web에서는 리다이렉트 대신 팝업 사용하여 sessionStorage 문제 회피
      final UserCredential userCred = kIsWeb
          ? await auth.signInWithPopup(googleProvider)
          : await auth.signInWithProvider(googleProvider);

      debugPrint('Google sign in successful: ${userCred.user?.email}');

      await ensureUserProfile(userCred.user);
      return userCred;
    } catch (e) {
      debugPrint('Google sign in error: $e');

      // iOS에서 Google 로그인 실패 시 더 자세한 오류 정보 제공
      if (Platform.isIOS) {
        if (e.toString().contains('network')) {
          throw Exception('네트워크 연결을 확인해주세요.');
        } else if (e.toString().contains('cancelled')) {
          throw Exception('로그인이 취소되었습니다.');
        } else if (e.toString().contains('popup')) {
          throw Exception('팝업이 차단되었습니다. 팝업 차단을 해제해주세요.');
        } else if (e.toString().contains('configuration')) {
          throw Exception('Firebase 설정 오류입니다. 앱을 재시작해주세요.');
        }
      }
      throw Exception('Google 로그인 오류: $e');
    }
  }

  // ----------------------------
  // users/{uid} 프로필 생성/갱신
  // ----------------------------
  static Future<void> ensureUserProfile(User? user) async {
    if (user == null) return;

    final ref = firestore.collection('users').doc(user.uid);
    final snap = await ref.get();

    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'updatedAt': now,
    };

    // displayName과 photoURL은 값이 있을 때만 업데이트
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      data['displayName'] = user.displayName;
    }
    if (user.photoURL != null) {
      data['photoURL'] = user.photoURL;
    }

    if (snap.exists) {
      // 기존 문서가 있는 경우: merge 옵션으로 업데이트
      await ref.set(data, SetOptions(merge: true));
    } else {
      // 새 문서 생성: 기본값과 함께 생성
      await ref.set({
        'displayName': user.displayName ?? '사용자',
        'photoURL': user.photoURL,
        'friendCount': 0,
        'incomingRequestCount': 0,
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }
}
