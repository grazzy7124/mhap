// lib/services/friend_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_models.dart';

/// 친구 관련 기능을 담당하는 서비스 클래스
class FriendService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 사용자 UID 가져오기
  static String? get currentUserId => _auth.currentUser?.uid;

  /// 사용자 검색 (UID로)
  static Future<UserSearchResult?> searchUserByUid(String uid) async {
    if (uid.isEmpty) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      final currentUid = currentUserId;
      if (currentUid == null) return null;



      // 이미 친구인지 확인
      final isAlreadyFriend = await _isAlreadyFriend(currentUid, uid);
      
      // 이미 요청을 보냈는지 확인
      final hasPendingRequest = await _hasPendingRequest(currentUid, uid);

      return UserSearchResult.fromFirestore(
        doc,
        isAlreadyFriend: isAlreadyFriend,
        hasPendingRequest: hasPendingRequest,
      );
    } catch (e) {
      print('사용자 검색 오류: $e');
      return null;
    }
  }


  /// 친구 요청 보내기
  static Future<bool> sendFriendRequest(String toUserId) async {
    final currentUid = currentUserId;
    if (currentUid == null || currentUid == toUserId) return false;

    try {
      // 이미 친구인지 확인
      if (await _isAlreadyFriend(currentUid, toUserId)) {
        throw Exception('이미 친구입니다.');
      }

      // 이미 요청을 보냈는지 확인
      if (await _hasPendingRequest(currentUid, toUserId)) {
        throw Exception('이미 친구 요청을 보냈습니다.');
      }

      // 사용자 정보 가져오기
      final userDoc = await _firestore.collection('users').doc(currentUid).get();
      if (!userDoc.exists) throw Exception('사용자 정보를 찾을 수 없습니다.');

      final userData = userDoc.data() as Map<String, dynamic>;

      // 친구 요청 생성
      await _firestore.collection('friendRequests').add({
        'fromUserId': currentUid,
        'fromUserDisplayName': userData['displayName'] ?? '',
        'fromUserPhotoURL': userData['photoURL'],
        'toUserId': toUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('친구 요청 전송 오류: $e');
      rethrow;
    }
  }

  /// 친구 요청 수락
  static Future<bool> acceptFriendRequest(String requestId) async {
    final currentUid = currentUserId;
    if (currentUid == null) return false;

    try {
      final requestRef = _firestore.collection('friendRequests').doc(requestId);
      final requestDoc = await requestRef.get();
      
      if (!requestDoc.exists) return false;
      
      final requestData = requestDoc.data() as Map<String, dynamic>;
      if (requestData['toUserId'] != currentUid) return false;

      // 요청 상태를 accepted로 변경
      await requestRef.update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 현재 사용자 정보 가져오기
      final currentUserDoc = await _firestore.collection('users').doc(currentUid).get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;

      // 친구 관계 생성 (단순한 구조)
      // friends 컬렉션에 친구 관계 문서 생성
      final friendshipId = _generateFriendshipId(currentUid, requestData['fromUserId']);
      
      await _firestore.collection('friends').doc(friendshipId).set({
        'user1Id': currentUid,
        'user1DisplayName': currentUserData['displayName'] ?? '사용자',
        'user1PhotoURL': currentUserData['photoURL'],
        'user2Id': requestData['fromUserId'],
        'user2DisplayName': requestData['fromUserDisplayName'],
        'user2PhotoURL': requestData['fromUserPhotoURL'],
        'createdAt': FieldValue.serverTimestamp(),
      });

<<<<<<< HEAD
      // 3) 카운터 업데이트(옵션)
      final fromRef = _fs.collection('users').doc(data['fromUid']);
      final toRef = _fs.collection('users').doc(data['toUid']);
      tx.update(fromRef, {'friendCount': FieldValue.increment(1)});
      tx.update(toRef, {
        'friendCount': FieldValue.increment(1),
        'incomingRequestCount': FieldValue.increment(-1),
      });
    });
  }

  /// 친구 요청 거절 (받은 사람)
  Future<void> rejectRequest(String requestId) async {
    final reqRef = _reqCol.doc(requestId);
    await _fs.runTransaction((tx) async {
      final snap = await tx.get(reqRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      if (data['toUid'] != _uid) throw StateError('거절 권한이 없습니다.');
      if (data['status'] != 'pending') return;

      tx.update(reqRef, {
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      final toRef = _fs.collection('users').doc(_uid);
      tx.update(toRef, {'incomingRequestCount': FieldValue.increment(-1)});
    });
  }

  /// 친구 끊기
  Future<void> unfriend(String otherUid) async {
    final pid = _pairId(_uid, otherUid);
    final ref = _fs.collection('friendships').doc(pid);
    await _fs.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      tx.delete(ref);
      tx.update(_fs.collection('users').doc(_uid), {
        'friendCount': FieldValue.increment(-1),
      });
      tx.update(_fs.collection('users').doc(otherUid), {
        'friendCount': FieldValue.increment(-1),
      });
    });
  }

  /// 받은 요청 목록(pending)
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingInbox() {
    return _reqCol
        .where('toUid', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 보낸 요청 목록(pending)
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingOutbox() {
    return _reqCol
        .where('fromUid', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 내 친구들의 uid 집합 조회(단발)
  Future<Set<String>> getFriendIdsOnce() async {
    final snap = await _fs
        .collection('friendships')
        .where('uids', arrayContains: _uid)
        .get();

    final ids = <String>{};
    for (final d in snap.docs) {
      final List<dynamic> u = d['uids'];
      for (final id in u) {
        if (id != _uid) ids.add(id as String);
      }
=======
      return true;
    } catch (e) {
      print('친구 요청 수락 오류: $e');
      return false;
    }
  }

  /// 친구 요청 거절
  static Future<bool> rejectFriendRequest(String requestId) async {
    final currentUid = currentUserId;
    if (currentUid == null) return false;

    try {
      final requestRef = _firestore.collection('friendRequests').doc(requestId);
      final requestDoc = await requestRef.get();
      
      if (!requestDoc.exists) return false;
      
      final requestData = requestDoc.data() as Map<String, dynamic>;
      if (requestData['toUserId'] != currentUid) return false;

      // 요청 상태를 rejected로 변경
      await requestRef.update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('친구 요청 거절 오류: $e');
      return false;
    }
  }

  /// 친구 삭제
  static Future<bool> removeFriend(String friendUid) async {
    final currentUid = currentUserId;
    if (currentUid == null) return false;

    try {
      // 친구 관계 문서 찾기 및 삭제
      final friendshipId = _generateFriendshipId(currentUid, friendUid);
      await _firestore.collection('friends').doc(friendshipId).delete();
      return true;
    } catch (e) {
      print('친구 삭제 오류: $e');
      return false;
    }
  }

  /// 친구 목록 스트림 가져오기
  static Stream<List<Friend>> getFriendsStream() {
    final currentUid = currentUserId;
    if (currentUid == null) return Stream.value([]);

    return _firestore
        .collection('friends')
        .where('user1Id', isEqualTo: currentUid)
        .snapshots()
        .asyncMap((snapshot) async {
          final friends = <Friend>[];
          
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            friends.add(Friend(
              uid: data['user2Id'],
              displayName: data['user2DisplayName'] ?? '',
              photoURL: data['user2PhotoURL'],
              addedAt: (data['createdAt'] as Timestamp).toDate(),
            ));
          }

          // user2Id가 currentUid인 경우도 처리
          final reverseSnapshot = await _firestore
              .collection('friends')
              .where('user2Id', isEqualTo: currentUid)
              .get();
          
          for (final doc in reverseSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            friends.add(Friend(
              uid: data['user1Id'],
              displayName: data['user1DisplayName'] ?? '',
              photoURL: data['user1PhotoURL'],
              addedAt: (data['createdAt'] as Timestamp).toDate(),
            ));
          }

          return friends;
        });
  }

  /// 받은 친구 요청 목록 스트림 가져오기
  static Stream<List<FriendRequest>> getIncomingRequestsStream() {
    final currentUid = currentUserId;
    if (currentUid == null) return Stream.value([]);

    return _firestore
        .collection('friendRequests')
        .where('toUserId', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromFirestore(doc))
            .toList());
  }

  // ==================== Private Methods ====================

  /// 친구 관계 ID 생성 (정렬된 UID 조합)
  static String _generateFriendshipId(String uid1, String uid2) {
    final sortedUids = [uid1, uid2]..sort();
    return '${sortedUids[0]}_${sortedUids[1]}';
  }

  /// 이미 친구인지 확인
  static Future<bool> _isAlreadyFriend(String uid1, String uid2) async {
    try {
      final friendshipId = _generateFriendshipId(uid1, uid2);
      final doc = await _firestore.collection('friends').doc(friendshipId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 이미 친구 요청을 보냈는지 확인
  static Future<bool> _hasPendingRequest(String fromUid, String toUid) async {
    try {
      final query = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: fromUid)
          .where('toUserId', isEqualTo: toUid)
          .where('status', isEqualTo: 'pending')
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
>>>>>>> dbe0374290c10e1e1023d4300805b8fa146b1b26
    }
  }
}
