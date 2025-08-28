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

  static FirebaseFirestore get firestore =>
      _firestore ??= FirebaseFirestore.instance;

  static FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;

  static Future<void> initialize({FirebaseOptions? options}) async {
    // 이미 초기화된 경우 중복 초기화 방지
    if (Firebase.apps.isNotEmpty) {
      debugPrint('Firebase already initialized, skipping...');
      return;
    }

    await Firebase.initializeApp(options: options);
    // Web 환경에서 리다이렉트 세션 저장 문제 방지: LOCAL 지속성 사용
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } catch (_) {
        // ignore persistence errors on non-web
      }
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
      // Firebase Auth의 GoogleAuthProvider로 직접 로그인
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      // Web에서는 리다이렉트 대신 팝업 사용하여 sessionStorage 문제 회피
      final UserCredential userCred = kIsWeb
          ? await auth.signInWithPopup(googleProvider)
          : await auth.signInWithProvider(googleProvider);
      await ensureUserProfile(userCred.user);
      return userCred;
    } catch (e) {
      // iOS에서 Google 로그인 실패 시 더 자세한 오류 정보 제공
      if (Platform.isIOS) {
        if (e.toString().contains('network')) {
          throw Exception('네트워크 연결을 확인해주세요.');
        } else if (e.toString().contains('cancelled')) {
          throw Exception('로그인이 취소되었습니다.');
        } else if (e.toString().contains('popup')) {
          throw Exception('팝업이 차단되었습니다. 팝업 차단을 해제해주세요.');
        }
      }
      throw Exception('Google 로그인 오류: $e');
    }
  }

  // ----------------------------
  // users/{uid} 프로필 생성/업데이트
  // ----------------------------
  static Future<void> ensureUserProfile(User? user) async {
    if (user == null) return;

    final ref = firestore.collection('users').doc(user.uid);
    final snap = await ref.get();

    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL,
      'updatedAt': now,
    };

    if (snap.exists) {
      await ref.set(data, SetOptions(merge: true));
    } else {
      await ref.set({
        ...data,
        'friendCount': 0,
        'incomingRequestCount': 0,
        'createdAt': now,
      }, SetOptions(merge: true));
    }
  }
}
