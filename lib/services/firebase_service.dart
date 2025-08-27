// lib/services/firebase_service.dart
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// google_sign_in 패키지 없이 Firebase Auth의 OAuth Provider 사용
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
    // Firebase Auth의 GoogleAuthProvider로 직접 로그인
    final googleProvider = GoogleAuthProvider();
    googleProvider.setCustomParameters({
      'prompt': 'select_account',
    });

    // Web에서는 리다이렉트 대신 팝업 사용하여 sessionStorage 문제 회피
    final UserCredential userCred = kIsWeb
        ? await auth.signInWithPopup(googleProvider)
        : await auth.signInWithProvider(googleProvider);
    await ensureUserProfile(userCred.user);
    return userCred;
  }

  // ----------------------------
  // Apple Login (iOS/macOS)
  // ----------------------------
  static Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCred = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCred = OAuthProvider('apple.com').credential(
      idToken: appleCred.identityToken,
      rawNonce: rawNonce,
    );

    final userCred = await auth.signInWithCredential(oauthCred);

    final user = userCred.user;
    // 최초 로그인 시 표시명 비어있으면 보완
    if (user != null && (user.displayName == null || user.displayName!.isEmpty)) {
      final fn = appleCred.givenName ?? '';
      final ln = appleCred.familyName ?? '';
      final name = (fn + ' ' + ln).trim();
      if (name.isNotEmpty) {
        await user.updateDisplayName(name);
      }
    }

    await ensureUserProfile(userCred.user);
    return userCred;
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

  // ----------------------------
  // Apple nonce helpers
  // ----------------------------
  static String _generateNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
