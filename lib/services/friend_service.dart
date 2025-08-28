// lib/services/friend_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  FriendService._();
  static final instance = FriendService._();

  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // friendRequests 컬렉션 레퍼런스
  CollectionReference<Map<String, dynamic>> get _reqCol =>
      _fs.collection('friendRequests');

  // friendships pairId 계산
  String _pairId(String a, String b) =>
      (a.compareTo(b) < 0) ? '${a}_$b' : '${b}_$a';

  /// 친구 요청 보내기
  Future<void> sendFriendRequest(String toUid) async {
    if (toUid == _uid) throw StateError('자기 자신에게 보낼 수 없습니다.');

    // 이미 친구면 막기
    final pid = _pairId(_uid, toUid);
    final friendsDoc = await _fs.collection('friendships').doc(pid).get();
    if (friendsDoc.exists) throw StateError('이미 친구입니다.');

    // 중복 요청 방지: pending 중인지 체크
    final dup = await _reqCol
        .where('fromUid', isEqualTo: _uid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) throw StateError('이미 보낸 친구 요청이 있습니다.');

    await _reqCol.add({
      'fromUid': _uid,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 배지용 카운트 증가 (옵션)
    _fs.collection('users').doc(toUid).update({
      'incomingRequestCount': FieldValue.increment(1),
    });
  }

  /// 친구 요청 취소 (보낸 사람)
  Future<void> cancelMyPendingRequest(String requestId) async {
    final doc = await _reqCol.doc(requestId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    if (data['fromUid'] != _uid || data['status'] != 'pending') {
      throw StateError('취소 권한이 없거나 대기 상태가 아닙니다.');
    }
    await _reqCol.doc(requestId).delete();
    // 배지 감소
    _fs.collection('users').doc(data['toUid']).update({
      'incomingRequestCount': FieldValue.increment(-1),
    });
  }

  /// 친구 요청 수락 (받은 사람)
  Future<void> acceptRequest(String requestId) async {
    final reqRef = _reqCol.doc(requestId);
    await _fs.runTransaction((tx) async {
      final snap = await tx.get(reqRef);
      if (!snap.exists) throw StateError('요청이 존재하지 않습니다.');
      final data = snap.data()!;
      if (data['toUid'] != _uid) throw StateError('수락 권한이 없습니다.');
      if (data['status'] != 'pending') return;

      // 1) 요청 상태 변경
      tx.update(reqRef, {
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // 2) friendships 생성
      final pid = _pairId(data['fromUid'], data['toUid']);
      final fsRef = _fs.collection('friendships').doc(pid);
      tx.set(fsRef, {
        'uids': [data['fromUid'], data['toUid']],
        'createdAt': FieldValue.serverTimestamp(),
      });

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
    }
    return ids;
  }
}
