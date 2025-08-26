import 'package:flutter/material.dart';

/// 업로드 페이지
///
/// 카메라/갤러리에서 선택한 사진을 캡션/위치와 함께 업로드하는 화면의 기본 골격입니다.
/// 실제 업로드/스토리지 연동은 Firebase 구현 단계에서 추가됩니다.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _captionController = TextEditingController();
  String? _pickedImagePath; // TODO: image_picker로 채우기
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // TODO: image_picker로 구현
    setState(() {
      _pickedImagePath = 'demo://picked';
    });
  }

  Future<void> _upload() async {
    if (_pickedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 사진을 선택해주세요.')),
      );
      return;
    }
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isUploading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업로드가 완료되었습니다.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사진 업로드')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: _pickedImagePath == null
                    ? Center(
                        child: TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('사진 선택'),
                        ),
                      )
                    : const Center(child: Icon(Icons.photo, size: 64)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '캡션을 입력하세요 (선택)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _upload,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_isUploading ? '업로드 중...' : '업로드'),
            ),
          ],
        ),
      ),
    );
  }
}
