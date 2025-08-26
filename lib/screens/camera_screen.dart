import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _takePhoto() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
        _showLocationInputDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카메라 오류: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _showLocationInputDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('갤러리 오류: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLocationInputDialog() {
    final locationController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('장소 입력'),
        content: TextField(
          controller: locationController,
          decoration: const InputDecoration(
            labelText: '장소명',
            hintText: '예: 스타벅스 강남점',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (locationController.text.isNotEmpty) {
                Navigator.pop(context);
                _savePhotoWithLocation(locationController.text);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _savePhotoWithLocation(String location) {
    // TODO: Firebase에 사진과 위치 정보 저장
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$location에 사진이 저장되었습니다!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // 사진 초기화
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // 카메라 화면에서 뒤로가기 제스처 방지
      body: WillPopScope(
        onWillPop: () async {
          // 뒤로가기 버튼이나 제스처 시 확인 다이얼로그 표시
          return await _showExitDialog();
        },
        child: SafeArea(
          child: Column(
            children: [
              // 상단 앱바
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        // 이전 화면으로 돌아가기
                        Navigator.of(context).pop();
                      },
                    ),
                    const Text(
                      '사진 촬영',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                      onPressed: () {
                        // TODO: 플래시 토글
                      },
                    ),
                  ],
                ),
              ),
              
              // 메인 카메라 영역
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[900],
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '사진을 촬영하거나\n갤러리에서 선택하세요',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              
              // 하단 컨트롤 버튼들
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 갤러리 버튼
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _isLoading ? null : _pickFromGallery,
                      ),
                    ),
                    
                    // 촬영 버튼
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.grey[400]!, width: 4),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera,
                          color: Colors.black,
                          size: 40,
                        ),
                        onPressed: _isLoading ? null : _takePhoto,
                      ),
                    ),
                    
                    // 설정 버튼
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          // TODO: 카메라 설정
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // 로딩 인디케이터
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 앱 종료 확인 다이얼로그
  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 종료'),
        content: const Text('정말로 앱을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('종료'),
          ),
        ],
      ),
    ) ?? false;
  }
}
