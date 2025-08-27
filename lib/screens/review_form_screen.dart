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

  @override
  void dispose() {
    _placeNameController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  /// 리뷰를 Firestore에 저장하는 메서드
  Future<void> _saveReview() async {
    if (_placeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장소 이름을 입력해주세요.'), backgroundColor: Colors.red),
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

      final String? imagePath = widget.initialImagePath ??
          (ModalRoute.of(context)?.settings.arguments is Map
              ? (ModalRoute.of(context)!.settings.arguments as Map)['imagePath'] as String?
              : null);

      final String? address = ModalRoute.of(context)?.settings.arguments is Map
          ? (ModalRoute.of(context)!.settings.arguments as Map)['address'] as String?
          : null;

      if (imagePath == null) {
        throw Exception('이미지가 없습니다.');
      }

      // 1. 이미지를 Firebase Storage에 업로드
      String imageUrl = '';
      if (imagePath.startsWith('file://') || imagePath.startsWith('/')) {
        final File imageFile = File(imagePath);
        final String fileName = 'reviews/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = _storage.ref().child(fileName);
        final UploadTask uploadTask = storageRef.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      } else {
        imageUrl = imagePath; // 이미 URL인 경우
      }

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

      // 3. Firestore에 리뷰 저장
      await _firestore.collection('reviews').add({
        'userId': user.uid,
        'userEmail': user.email,
        'placeName': _placeNameController.text.trim(),
        'address': address ?? '위치 정보 없음',
        'latitude': latitude,
        'longitude': longitude,
        'reviewText': _reviewController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰가 성공적으로 저장되었습니다!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('리뷰 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리뷰 저장 중 오류가 발생했습니다: $e'), backgroundColor: Colors.red),
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
    final String? imagePath = widget.initialImagePath ??
        (ModalRoute.of(context)?.settings.arguments is Map
            ? (ModalRoute.of(context)!.settings.arguments as Map)['imagePath'] as String?
            : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰 작성'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) 상단 이미지 미리보기
            AspectRatio(
              aspectRatio: 4 / 3,
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

            // 2) 주소 표시 (카메라에서 전달받은 주소)
            const Text('주소', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      imagePath != null && imagePath.isNotEmpty
                          ? (ModalRoute.of(context)?.settings.arguments is Map
                              ? (ModalRoute.of(context)!.settings.arguments as Map)['address'] as String? ?? '위치 정보 없음'
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
            const SizedBox(height: 16),

            // 3) 장소 이름 입력
            const Text('장소 이름', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _placeNameController,
              decoration: InputDecoration(
                hintText: '장소 이름을 입력하세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),

            // 4) 리뷰 내용 입력
            const Text('리뷰 내용', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: '리뷰 내용을 입력하세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _saveReview,
              child: _isSaving 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}


