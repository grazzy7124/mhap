import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

class ReviewFormScreen extends StatefulWidget {
  final String? initialImagePath;

  const ReviewFormScreen({super.key, this.initialImagePath});

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();

  bool _isSaving = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _checkFirebaseStorage();
  }

  /// Firebase Storage 상태 확인
  void _checkFirebaseStorage() {
    try {
      print('🔥 Firebase Storage 상태 확인 중...');
      print('📦 Storage 인스턴스: $_storage');
      print('🔗 Storage 앱: ${_storage.app.name}');
      print('📁 기본 버킷: ${_storage.app.options.storageBucket}');

      // Storage 참조 테스트
      final testRef = _storage.ref().child('test');
      print('✅ Storage 참조 생성 성공: ${testRef.fullPath}');
    } catch (e) {
      print('❌ Firebase Storage 초기화 오류: $e');
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 별점 선택 상태
  int _selectedRating = 0;

  @override
  void dispose() {
    _placeNameController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  /// 이미지 압축 및 최적화
  Future<File> _compressImage(File file) async {
    try {
      // 간단한 압축: 파일 크기가 5MB 이상일 때만 압축
      final fileSize = await file.length();
      if (fileSize < 5 * 1024 * 1024) {
        // 5MB 미만이면 그대로 반환
        return file;
      }

      // 여기에 실제 이미지 압축 로직을 추가할 수 있습니다
      // 현재는 파일을 그대로 반환
      print('🖼️ 이미지 압축: ${fileSize ~/ (1024 * 1024)}MB -> 압축 생략');
      return file;
    } catch (e) {
      print('⚠️ 이미지 압축 실패: $e');
      return file; // 압축 실패 시 원본 반환
    }
  }

  /// Firebase Storage에 이미지 업로드 (강화된 버전)
  Future<String> _uploadImageToFirebase(File imageFile, String userId) async {
    try {
      print('🔥 Firebase Storage 업로드 시작...');
      print('👤 사용자 ID: $userId');
      print('✅ Firebase Storage 인스턴스 확인됨');

      // 2. 파일 유효성 검사
      if (!await imageFile.exists()) {
        throw Exception('이미지 파일이 존재하지 않습니다: ${imageFile.path}');
      }

      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception('이미지 파일 크기가 0바이트입니다');
      }

      print('📁 파일 정보: ${imageFile.path}');
      print(
        '📏 파일 크기: $fileSize bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)',
      );

      // 3. Firebase Storage 참조 생성
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'reviews/$userId/${timestamp}_${imageFile.path.split('/').last}';
      final storageRef = _storage.ref().child(fileName);

      print('🚀 Firebase Storage 참조 생성: $fileName');
      print('🔗 Storage 경로: ${storageRef.fullPath}');

      // 4. 이미지 압축
      final compressedFile = await _compressImage(imageFile);
      print('🔄 압축 완료: ${await compressedFile.length()} bytes');

      // 5. 업로드 실행
      print('📤 파일 업로드 시작...');
      final uploadTask = storageRef.putFile(compressedFile);

      // 6. 업로드 진행률 모니터링
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📊 업로드 진행률: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // 7. 업로드 완료 대기
      final snapshot = await uploadTask;
      print('✅ 업로드 완료!');
      print('📊 최종 바이트: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');

      // 8. 다운로드 URL 가져오기
      print('🔗 다운로드 URL 가져오는 중...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('🔗 다운로드 URL: $downloadUrl');

      // 9. URL 유효성 검사
      if (!downloadUrl.startsWith('https://firebasestorage.googleapis.com/')) {
        throw Exception('업로드된 URL이 Firebase Storage 형식이 아닙니다: $downloadUrl');
      }

      print('🎉 Firebase Storage 업로드 성공!');
      print('📸 최종 이미지 URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Firebase Storage 업로드 실패: $e');
      print('❌ 에러 타입: ${e.runtimeType}');
      print('❌ 에러 메시지: ${e.toString()}');
      print('❌ 스택 트레이스: ${StackTrace.current}');

      // Firebase 관련 에러 상세 분석
      if (e.toString().contains('permission')) {
        print('🚫 권한 문제: Firebase Storage 규칙을 확인하세요');
      } else if (e.toString().contains('network')) {
        print('🌐 네트워크 문제: 인터넷 연결을 확인하세요');
      } else if (e.toString().contains('quota')) {
        print('💾 용량 문제: Firebase Storage 할당량을 확인하세요');
      }

      rethrow; // 에러를 상위로 전파
    }
  }

  /// 로컬에 이미지 복사하여 저장
  Future<String> _saveImageLocally(File imageFile, String userId) async {
    try {
      // 1. 앱 문서 디렉토리 가져오기
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');

      // 2. images 디렉토리가 없으면 생성
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // 3. 고유한 파일명 생성
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_$timestamp.jpg';
      final localPath = '${imagesDir.path}/$fileName';

      // 4. 이미지 복사
      await imageFile.copy(localPath);

      print('💾 로컬에 이미지 저장 완료: $localPath');
      return localPath;
    } catch (e) {
      print('❌ 로컬 이미지 저장 실패: $e');
      // 실패 시 원본 경로 반환
      return imageFile.path;
    }
  }

  /// 확인 버튼을 눌렀을 때 표시할 다이얼로그
  Future<void> _pickIcon() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xff000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SizedBox(
            width: 300,
            height: 350,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 40),
                  const Text(
                    '아이콘을 선택하세요!',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 59, // 가로 간격
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(); // 다이얼로그 닫기
                          _saveReview(selectedIcon: 'item1'); // 아이콘1 선택
                        },
                        child: Image.asset(
                          'assets/images/item1.png',
                          width: 70,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(); // 다이얼로그 닫기
                          _saveReview(selectedIcon: 'item2'); // 아이콘2 선택
                        },
                        child: Image.asset(
                          'assets/images/item2.png',
                          width: 70,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 53),
                  Wrap(
                    spacing: 59, // 가로 간격
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(); // 다이얼로그 닫기
                          _saveReview(selectedIcon: 'item3'); // 아이콘3 선택
                        },
                        child: Image.asset(
                          'assets/images/item3.png',
                          width: 70,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(); // 다이얼로그 닫기
                          _saveReview(selectedIcon: 'item4'); // 아이콘4 선택
                        },
                        child: Image.asset(
                          'assets/images/item4.png',
                          width: 70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 리뷰를 Firestore에 저장하는 메서드
  Future<void> _saveReview({String? selectedIcon}) async {
    if (_placeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('장소 이름을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      final String? imagePath =
          widget.initialImagePath ??
          (ModalRoute.of(context)?.settings.arguments is Map
              ? (ModalRoute.of(context)!.settings.arguments as Map)['imagePath']
                    as String?
              : null);

      final String? address = ModalRoute.of(context)?.settings.arguments is Map
          ? (ModalRoute.of(context)!.settings.arguments as Map)['address']
                as String?
          : null;

      if (imagePath == null) {
        throw Exception('이미지가 없습니다.');
      }

      // 1. 이미지를 Firebase Storage에 업로드 또는 로컬에 저장
      String imageUrl = '';

      try {
        final file = File(imagePath);
        print('📸 이미지 업로드 시작: ${file.path}');

        // Firebase Storage 업로드 시도
        try {
          imageUrl = await _uploadImageToFirebase(file, user.uid);
          print('✅ Firebase Storage 업로드 완료: $imageUrl');
        } catch (firebaseError) {
          print('❌ Firebase Storage 업로드 실패: $firebaseError');
          print('🔄 로컬 저장 방식으로 전환...');

          // Firebase Storage 실패 시 로컬에 저장
          imageUrl = await _saveImageLocally(file, user.uid);
          print('💾 로컬 저장 완료: $imageUrl');

          // 사용자에게 알림
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Firebase Storage 업로드 실패, 로컬에 저장되었습니다'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        print('❌ 이미지 처리 완전 실패: $e');

        // 완전 실패 시 원본 경로 사용
        imageUrl = imagePath;
        print('⚠️ 원본 경로 사용: $imageUrl');

        // 에러 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이미지 처리 실패: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }

      // 카메라에서 전달된 좌표 사용 (필수)
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final double? latFromCamera = (args?['lat'] as num?)?.toDouble();
      final double? lngFromCamera = (args?['lng'] as num?)?.toDouble();
      if (latFromCamera == null || lngFromCamera == null) {
        throw Exception('촬영 좌표를 찾을 수 없습니다. 카메라에서 위치 권한을 허용했는지 확인하세요.');
      }

      // 3. Firestore에 리뷰 저장 (GeoPoint만)
      final Map<String, dynamic> reviewData = {
        'userId': user.uid,
        'userEmail': user.email,
        'userName':
            user.displayName ?? user.email?.split('@')[0] ?? 'Unknown User',
        'placeName': _placeNameController.text.trim(),
        'review': _reviewController.text.trim(), // 리뷰 텍스트 추가
        'imageUrl': imageUrl,
        'rating': _selectedRating,
        'selectedIcon': selectedIcon ?? 'item1',
        'location': GeoPoint(latFromCamera, lngFromCamera),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likes': 0, // 좋아요 수 초기화
        'comments': 0, // 댓글 수 초기화
      };

      await _firestore.collection('reviews').add(reviewData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리뷰가 성공적으로 저장되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );

        // 리뷰 저장 완료 후 메인 페이지의 지도 탭으로 이동
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/main', // 메인 페이지로 이동
          arguments: {'initialTab': 1}, // 1 = 지도 탭 (0: 카메라, 1: 지도, 2: 쇼핑)
          (route) => false, // 모든 이전 화면 제거
        );
      }
    } catch (e) {
      print('리뷰 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('리뷰 저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? imagePath =
        widget.initialImagePath ??
        (ModalRoute.of(context)?.settings.arguments is Map
            ? (ModalRoute.of(context)!.settings.arguments as Map)['imagePath']
                  as String?
            : null);

    final starGradient = const LinearGradient(
      colors: [
        Color(0xFFDE3397), // 빨강
        Color(0xFFF46061), // 주황
        Color(0xFFFEA440), // 노랑
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Row(
          children: [
            SizedBox(width: 22.05),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Image.asset('assets/images/Vector.png', width: 18.89),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _pickIcon,
            child: Text(
              '확인',
              style: TextStyle(
                color: _isSaving ? Colors.grey : Color(0xff007AFF),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) 상단 이미지 미리보기
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: imagePath != null && imagePath.isNotEmpty
                    ? Image.file(File(imagePath), fit: BoxFit.cover)
                    : const Center(child: Text('이미지가 없습니다')),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 2) 주소 표시 (카메라에서 전달받은 주소)
                  Container(
                    width: 290,
                    height: 45,
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    decoration: BoxDecoration(
                      color: Color(0xffD9D9D9),
                      borderRadius: BorderRadius.circular(22.5),
                    ),
                    child: Row(
                      children: [
                        Image.asset('assets/images/map_icon.png', width: 21),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            imagePath != null && imagePath.isNotEmpty
                                ? (ModalRoute.of(context)?.settings.arguments
                                          is Map
                                      ? (ModalRoute.of(
                                                      context,
                                                    )!.settings.arguments
                                                    as Map)['address']
                                                as String? ??
                                            '위치 정보 없음'
                                      : '위치 정보 없음')
                                : '위치 정보 없음',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 3) 장소 이름 입력
                  TextField(
                    controller: _placeNameController,
                    decoration: InputDecoration(
                      hintText: '나만의 장소 이름을 입력하세요!',
                      hintStyle: TextStyle(color: Color(0xffBBBBBB)),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                  // 4) 별점 선택
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(5, (index) {
                      final isSelected = index < _selectedRating;
                      return Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: isSelected
                                ? ShaderMask(
                                    shaderCallback: (bounds) =>
                                        starGradient.createShader(
                                          Rect.fromLTWH(
                                            0,
                                            0,
                                            bounds.width,
                                            bounds.height,
                                          ),
                                        ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      size: 26,
                                      color: Colors
                                          .white, // ShaderMask가 이 색을 그라데이션으로 덮어씌움
                                    ),
                                  )
                                : const Icon(
                                    Icons.star_rounded,
                                    size: 26,
                                    color: Color(0xFFF2F2F7),
                                  ),
                          ),
                        ),
                      );
                    }),
                  ),
                  // 5) 리뷰 내용 입력
                  TextField(
                    controller: _reviewController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: '내용 입력',
                      hintStyle: TextStyle(color: Color(0xffD2D2D2)),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
