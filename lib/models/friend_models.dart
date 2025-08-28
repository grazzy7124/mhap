import 'package:cloud_firestore/cloud_firestore.dart';

/// 친구 정보를 담는 데이터 클래스
class Friend {
  final String uid;
  final String displayName;
  final String? photoURL;
  final DateTime addedAt;

  Friend({
    required this.uid,
    required this.displayName,
    this.photoURL,
    required this.addedAt,
  });

  factory Friend.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      uid: doc.id, // 이 문서의 ID가 친구의 UID
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoURL': photoURL,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}

/// 친구 요청 정보를 담는 데이터 클래스
class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUserDisplayName;
  final String? fromUserPhotoURL;
  final String toUserId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime? updatedAt;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserDisplayName,
    this.fromUserPhotoURL,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUserDisplayName: data['fromUserDisplayName'] ?? '',
      fromUserPhotoURL: data['fromUserPhotoURL'],
      toUserId: data['toUserId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromUserDisplayName': fromUserDisplayName,
      'fromUserPhotoURL': fromUserPhotoURL,
      'toUserId': toUserId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

/// 사용자 검색 결과를 담는 데이터 클래스
class UserSearchResult {
  final String uid;
  final String displayName;
  final String? photoURL;
  final bool isAlreadyFriend;
  final bool hasPendingRequest;

  UserSearchResult({
    required this.uid,
    required this.displayName,
    this.photoURL,
    this.isAlreadyFriend = false,
    this.hasPendingRequest = false,
  });

  factory UserSearchResult.fromFirestore(DocumentSnapshot doc, {
    bool isAlreadyFriend = false,
    bool hasPendingRequest = false,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSearchResult(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      isAlreadyFriend: isAlreadyFriend,
      hasPendingRequest: hasPendingRequest,
    );
  }
}
