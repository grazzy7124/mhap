import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';

/// 카메라 화면
///
/// 이 화면은 사용자가 사진을 찍거나 갤러리에서 사진을 선택할 수 있는 화면입니다.
/// 주요 기능:
/// - 카메라로 사진 촬영
/// - 갤러리에서 사진 선택
/// - GPS 위치 정보 수집
/// - 사진과 위치 정보를 Firebase에 업로드 (현재는 TODO 상태)
/// - 플래시 토글 및 카메라 설정 (현재는 TODO 상태)
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker(); // 이미지 선택기

  // 현재 상태 관리
  bool _isLoading = false; // 로딩 상태
  bool _isFlashOn = false; // 플래시 상태
  Position? _currentPosition; // 현재 GPS 위치
  String? _locationName; // 위치 이름 (현재는 TODO 상태)

  // 카메라 관련 상태
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  String? _selectedImagePath; // 선택된 이미지 경로
  
  // 사용 가능한 카메라 목록과 현재 카메라
  List<CameraDescription>? _availableCameras;
  CameraDescription? _currentCamera;
  
  // 촬영 시 화면 플래시 효과
  bool _showCaptureFlash = false;

  @override
  void initState() {
    super.initState();
    // 화면 초기화 시 위치 권한 확인 및 현재 위치 가져오기
    _checkLocationPermission();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      _availableCameras = cameras;
      // 후면 카메라 우선 선택
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _currentCamera = back;
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _cameraController = controller;
      _initializeControllerFuture = controller.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('카메라 초기화 실패: $e');
    }
  }

  /// 위치 권한을 확인하고 현재 위치를 가져오는 메서드
  ///
  /// 이 메서드는 앱이 시작될 때 실행되며:
  /// 1. 위치 권한이 허용되었는지 확인합니다
  /// 2. 권한이 없다면 사용자에게 요청합니다
  /// 3. 권한이 허용되면 현재 위치를 가져옵니다
  Future<void> _checkLocationPermission() async {
    try {
      // 위치 서비스가 활성화되어 있는지 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // 위치 서비스가 비활성화된 경우 사용자에게 알림
        if (mounted) {
          _showLocationServiceDialog();
        }
        return;
      }

      // 위치 권한 상태 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // 권한이 거부된 경우 사용자에게 요청
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // 권한이 여전히 거부된 경우
          if (mounted) {
            _showPermissionDeniedDialog();
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // 권한이 영구적으로 거부된 경우
        if (mounted) {
          _showPermissionPermanentlyDeniedDialog();
        }
        return;
      }

      // 권한이 허용된 경우 현재 위치 가져오기
      await _getCurrentLocation();
    } catch (e) {
      print('위치 권한 확인 오류: $e');
      if (mounted) {
        _showErrorDialog('위치 권한 확인 중 오류가 발생했습니다: $e');
      }
    }
  }

  /// 현재 위치를 가져오는 메서드
  ///
  /// GPS를 통해 현재 위치 정보를 가져와서 상태에 저장합니다.
  /// 위치 정보는 사진과 함께 Firebase에 업로드될 예정입니다.
  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 현재 위치 가져오기 (높은 정확도, 10초 타임아웃)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      print('현재 위치 가져오기 오류: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showErrorDialog('현재 위치를 가져올 수 없습니다: $e');
      }
    }
  }

  /// 카메라로 사진을 촬영하는 메서드
  ///
  /// 기기의 카메라를 열어 사진을 촬영합니다.
  /// 촬영된 사진은 임시 파일로 저장되고, 위치 정보와 함께 처리됩니다.
  Future<void> _takePhoto() async {
    try {
      setState(() {
        _isLoading = true;
        _showCaptureFlash = true; // 플래시 효과 시작
      });
      // 짧은 플래시 표시
      await Future.delayed(const Duration(milliseconds: 120));
      setState(() {
        _showCaptureFlash = false;
      });

      XFile? photo;
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        await _initializeControllerFuture;
        photo = await _cameraController!.takePicture();
      } else {
        // fallback: 기존 picker 사용
        photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          preferredCameraDevice: CameraDevice.rear,
        );
      }

      if (photo != null) {
        setState(() {
          _selectedImagePath = photo!.path;
          _isLoading = false;
        });

        // TODO: 사진과 위치 정보를 Firebase에 업로드
        await _processPhoto(photo.path);

        // GPS 좌표를 주소로 변환
        String? resolvedAddress;
        if (_currentPosition != null) {
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            );
            if (placemarks.isNotEmpty) {
              Placemark place = placemarks.first;
              resolvedAddress = '${place.administrativeArea} ${place.subLocality} ${place.thoroughfare}'.trim();
              if (resolvedAddress.isEmpty) {
                resolvedAddress = '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
              }
            }
          } catch (e) {
            print('주소 변환 실패: $e');
            resolvedAddress = '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
          }
        }

        // 촬영 후 리뷰 작성 화면으로 이동
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          '/review',
          arguments: {
            'imagePath': photo.path,
            'address': resolvedAddress,
          },
        );
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('사진 촬영 오류: $e');
      setState(() {
        _isLoading = false;
        _showCaptureFlash = false;
      });

      if (mounted) {
        _showErrorDialog('사진 촬영 중 오류가 발생했습니다: $e');
      }
    }
  }

  /// 갤러리에서 사진을 선택하는 메서드
  ///
  /// 기기의 갤러리(사진 앱)를 열어 기존 사진을 선택합니다.
  /// 선택된 사진은 위치 정보와 함께 처리됩니다.
  Future<void> _pickFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 갤러리에서 사진 선택
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // 이미지 품질 (0-100)
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image!.path;
          _isLoading = false;
        });

        // TODO: 사진과 위치 정보를 Firebase에 업로드
        await _processPhoto(image.path);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('갤러리에서 사진 선택 오류: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showErrorDialog('갤러리에서 사진을 선택할 수 없습니다: $e');
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// 선택된 사진을 처리하는 메서드
  ///
  /// 촬영되거나 선택된 사진을 처리합니다.
  /// 현재는 TODO 상태이며, 향후 Firebase에 업로드하는 기능을 구현할 예정입니다.
  Future<void> _processPhoto(String imagePath) async {
    try {
      // TODO: Firebase에 사진과 위치 정보 업로드
      // 1. 이미지를 Firebase Storage에 업로드
      // 2. 위치 정보와 함께 Firestore에 메타데이터 저장
      // 3. 업로드 완료 후 사용자에게 알림

      await Future.delayed(const Duration(seconds: 2)); // 임시 딜레이

      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('사진이 성공적으로 업로드되었습니다!'),
        //     backgroundColor: Colors.green,
        //   ),
        // );

        // 선택된 이미지 초기화
        setState(() {
          _selectedImagePath = null;
        });
      }
    } catch (e) {
      print('사진 처리 오류: $e');
      if (mounted) {
        _showErrorDialog('사진 처리 중 오류가 발생했습니다: $e');
      }
    }
  }

  /// 플래시를 토글하는 메서드
  ///
  /// 카메라의 플래시를 켜거나 끕니다.
  /// 현재는 TODO 상태이며, 실제 카메라 플래시 제어 기능을 구현할 예정입니다.
  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });

    // TODO: 실제 카메라 플래시 제어 구현
    print('플래시 ${_isFlashOn ? "켜짐" : "꺼짐"}');
  }

  /// 카메라 전환 메서드
  Future<void> _switchCamera() async {
    try {
      if (_availableCameras == null || _availableCameras!.isEmpty) return;
      final bool isBack = _currentCamera?.lensDirection == CameraLensDirection.back;
      final CameraDescription next = _availableCameras!.firstWhere(
        (c) => isBack ? c.lensDirection == CameraLensDirection.front : c.lensDirection == CameraLensDirection.back,
        orElse: () => _availableCameras!.first,
      );
      if (_cameraController != null) {
        await _cameraController!.dispose();
      }
      _currentCamera = next;
      final controller = CameraController(
        next,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      setState(() {
        _cameraController = controller;
        _initializeControllerFuture = controller.initialize();
      });
    } catch (e) {
      debugPrint('카메라 전환 실패: $e');
    }
  }

  /// 위치 서비스 비활성화 다이얼로그를 표시하는 메서드
  ///
  /// 사용자의 위치 서비스가 비활성화되어 있을 때 표시됩니다.
  /// 설정으로 이동할 수 있는 옵션을 제공합니다.
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 서비스 비활성화'),
        content: const Text('사진에 위치 정보를 추가하려면 위치 서비스를 활성화해야 합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  /// 위치 권한 거부 다이얼로그를 표시하는 메서드
  ///
  /// 사용자가 위치 권한을 거부했을 때 표시됩니다.
  /// 권한을 다시 요청할 수 있는 옵션을 제공합니다.
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 권한 거부'),
        content: const Text('사진에 위치 정보를 추가하려면 위치 권한이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkLocationPermission();
            },
            child: const Text('권한 다시 요청'),
          ),
        ],
      ),
    );
  }

  /// 위치 권한 영구 거부 다이얼로그를 표시하는 메서드
  ///
  /// 사용자가 위치 권한을 영구적으로 거부했을 때 표시됩니다.
  /// 앱 설정에서 수동으로 권한을 허용해야 합니다.
  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 권한 영구 거부'),
        content: const Text('위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 수동으로 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('앱 설정으로 이동'),
          ),
        ],
      ),
    );
  }

  /// 오류 다이얼로그를 표시하는 메서드
  ///
  /// 다양한 오류 상황에서 사용자에게 오류 메시지를 표시합니다.
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 메인 카메라 UI
          Column(
            children: [
              // 상단 툴바
              Container(
                padding: const EdgeInsets.only(top: 120, left: 20, right: 20),
              ),

              // 카메라 프리뷰 영역
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      // color: Colors.white.withOpacity(0.3),s
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: (_cameraController != null)
                      ? FutureBuilder<void>(
                          future: _initializeControllerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _isLoading ? null : _takePhoto,
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRect(
                                          child: FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              width: _cameraController!.value.previewSize?.width ?? 1080,
                                              height: _cameraController!.value.previewSize?.height ?? 1920,
                                              child: CameraPreview(_cameraController!),
                                            ),
                                          ),
                                        ),
                                        // 4:3 프레임 테두리
                                        IgnorePointer(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.white70, width: 2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                        // 라이트 그리드 (3x3)
                                        IgnorePointer(
                                          child: CustomPaint(
                                            painter: _GridOverlayPainter(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.camera_alt, color: Colors.white54, size: 48),
                              SizedBox(height: 12),
                              Text('카메라 초기화 중...', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                ),
              ),

              // 하단 컨트롤 버튼들
              Container(
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 갤러리 버튼
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: Image.asset('assets/images/gallery.png'),
                        onPressed: _isLoading ? null : _pickFromGallery,
                      ),
                    ),

                    // 촬영 버튼
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          width: 4,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: _isLoading ? null : _takePhoto,
                        child: Image.asset('assets/images/Shutter.png'),
                      ),
                    ),

                    // 카메라 전환 버튼
                    Container(
                      width: 60,
                      height: 60,
                      child: IconButton(
                        icon: Image.asset('assets/images/Camera flip.png'),
                        onPressed: _isLoading ? null : _switchCamera,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 로딩 오버레이
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

          // 캡처 플래시 오버레이
          if (_showCaptureFlash)
            Container(color: Colors.white.withOpacity(0.7)),

          // 선택된 이미지 표시 (임시)
          if (_selectedImagePath != null)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_selectedImagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 그리드 오버레이를 그리는 CustomPainter
class _GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    // 세로 2줄 (3x3 그리드)
    final double v1 = size.width / 3;
    final double v2 = v1 * 2;
    canvas.drawLine(Offset(v1, 0), Offset(v1, size.height), line);
    canvas.drawLine(Offset(v2, 0), Offset(v2, size.height), line);

    // 가로 2줄
    final double h1 = size.height / 3;
    final double h2 = h1 * 2;
    canvas.drawLine(Offset(0, h1), Offset(size.width, h1), line);
    canvas.drawLine(Offset(0, h2), Offset(size.width, h2), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
