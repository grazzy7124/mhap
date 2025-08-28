import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 별점 선택 상태
  int _selectedRating = 0;

  @override
  void dispose() {
    _placeNameController.dispose();
    _reviewController.dispose();
    super.dispose();
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
            width: 300, height: 350,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 40,),
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

      // 1. 이미지를 Firebase Storage에 업로드 (오류 방지를 위해 로컬 경로만 사용)
      String imageUrl = '';
      
      // Firebase Storage 오류로 인해 로컬 경로만 사용
      imageUrl = imagePath;
      print('이미지 경로 사용: $imageUrl');

      // 2. 주소를 좌표로 변환 (지도 표시용)
      double? latitude;
      double? longitude;
      if (address != null && address != '위치 정보 없음') {
        try {
          List<Location> locations = await locationFromAddress(address);
          if (locations.isNotEmpty) {
            latitude = locations.first.latitude;
            longitude = locations.first.longitude;
          }
        } catch (e) {
          print('주소를 좌표로 변환 실패: $e');
        }
      }

      // 3. Firestore에 리뷰 저장 (선택된 아이콘 포함)
      await _firestore.collection('reviews').add({
        'userId': user.uid,
        'userEmail': user.email,
        'placeName': _placeNameController.text.trim(),
        'address': address ?? '위치 정보 없음',
        'latitude': latitude,
        'longitude': longitude,
        'reviewText': _reviewController.text.trim(),
        'imageUrl': imageUrl,
        'rating': _selectedRating, // 별점 추가
        'selectedIcon': selectedIcon ?? 'item1', // 선택된 아이콘 (기본값: item1)
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

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

    final _starGradient = const LinearGradient(
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
                color: _isSaving ? Colors.grey : Color(0xff007AFF)
              )
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
                                        _starGradient.createShader(
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
