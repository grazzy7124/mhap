import 'dart:io';
import 'package:flutter/material.dart';

class ReviewFormScreen extends StatefulWidget {
  final String? initialImagePath;

  const ReviewFormScreen({super.key, this.initialImagePath});

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _placeNameController.dispose();
    _reviewController.dispose();
    super.dispose();
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
              aspectRatio: 16 / 9,
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

            // 2) 주소 입력
            const Text('주소', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: '주소를 입력하세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
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
              onPressed: () {
                // TODO: 저장 로직 연동 (Firestore + Storage)
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('리뷰가 임시로 저장되었습니다.')),
                );
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}


