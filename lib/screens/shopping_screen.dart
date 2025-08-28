import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  int coin = 30;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 로컬 이미지 에셋 리스트
  final List<String> _imageAssets = [
    'assets/images/item1.png',
    'assets/images/item2.png',
    'assets/images/item3.png',
    'assets/images/item4.png',
    'assets/images/item5.png',
    'assets/images/item6.png',
    'assets/images/item7.png',
    'assets/images/item8.png',
  ];

  // 각 아이템의 가격 리스트 (개발자가 직접 수정 가능)
  final List<int> _itemPrices = [
    30, // item1 가격
    15, // item2 가격
    20, // item3 가격
    35, // item4 가격
    70, // item5 가격
    20, // item6 가격
    50, // item7 가격
    30, // item8 가격
  ];

  // 구매한 아이콘 리스트 (예시)
  final List<String> _purchasedIcons = [
    'assets/images/icon1.png',
    'assets/images/icon2.png',
    'assets/images/icon3.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserCoin();
  }

  /// 사용자의 coin 정보를 Firebase에서 로드
  Future<void> _loadUserCoin() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['coin'] != null) {
            setState(() {
              coin = data['coin'];
            });
          }
        }
      }
    } catch (e) {
      print('Coin 로드 오류: $e');
    }
  }

  /// 사용자의 coin Stream
  Stream<int> _getUserCoinStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.data()?['coin'] ?? 30);
    }
    return Stream.value(30);
  }

  /// 사용자의 coin을 업데이트
  Future<void> _updateUserCoin(int newCoin) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'coin': newCoin,
        });
        // StreamBuilder가 자동으로 업데이트하므로 setState 불필요
      }
    } catch (e) {
      print('Coin 업데이트 오류: $e');
    }
  }

  /// 아이템 구매 처리
  Future<void> _purchaseItem(int itemIndex) async {
    final itemPrice = _itemPrices[itemIndex];

    if (coin >= itemPrice) {
      final newCoin = coin - itemPrice;
      await _updateUserCoin(newCoin);

      // 구매 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('아이템을 구매했습니다! ($itemPrice코인 차감)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // 코인 부족 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('코인이 부족합니다!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 구매 확인 후 진행
  Future<void> _confirmAndPurchase(int itemIndex) async {
    final int price = _itemPrices[itemIndex];
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xffC4C4C4),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('구매하시겠습니까?'),
              SizedBox(height: 10),
              Container(height: 1, color: Color(0xff939393)),
              SizedBox(height: 10),
              // 예 버튼
              GestureDetector(
                onTap: () => Navigator.of(context).pop(true),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '예',
                      style: TextStyle(
                        color: Color(0xff0040DD),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6),
              Container(
                height: 1,
                width: MediaQuery.of(context).size.width * 0.6, // 명시적 너비 설정
                color: Color(0xff939393),
              ),
              SizedBox(height: 6),
              // 아니오 버튼
              GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6, // 명시적 너비 설정
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '아니오',
                      style: TextStyle(
                        color: Color(0xff0040DD),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // actions: [
          //   TextButton(
          //     onPressed: () => Navigator.of(context).pop(false),
          //     child: const Text('아니오'),
          //   ),
          //   ElevatedButton(
          //     onPressed: () => Navigator.of(context).pop(true),
          //     child: const Text('예'),
          //   ),
          // ],
        );
      },
    );

    if (confirmed == true) {
      await _purchaseItem(itemIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: 100, // AppBar 높이를 늘려서 이미지가 잘리지 않도록 조정
        leading: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 19.05),
            GestureDetector(
              child: Image.asset(
                'assets/images/arrow_left.png',
                width: 18.89,
                height: 17.44,
              ),
              onTap: () {
                // PageView에서 지도 탭(인덱스 1)으로 이동
                Navigator.pushReplacementNamed(
                  context,
                  '/main',
                  arguments: {'initialTab': 1}, // 지도 탭 인덱스
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        title: Column(
          children: [
            SizedBox(height: 20),
            Image.asset('assets/images/icon_shop.png'),
            SizedBox(height: 16),
            Image.asset('assets/images/appbar_underline.png'),
          ],
        ),
        actions: [
          StreamBuilder<int>(
            stream: _getUserCoinStream(),
            builder: (context, snapshot) {
              final currentCoin = snapshot.data ?? coin;
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 5),
                      Image.asset(
                        'assets/images/coin.png',
                        width: 22,
                        height: 18,
                      ),
                      SizedBox(width: 5),
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            colors: [
                              Color(0xFFDE3397), // 빨간색 계열
                              Color(0xFFF46061), // 주황색 계열
                              Color(0xFFFEA440), // 노란색 계열
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: Text(
                          '$currentCoin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2열 그리드
                crossAxisSpacing: 16.0, // 가로 간격
                mainAxisSpacing: 16.0, // 세로 간격
                childAspectRatio: 1.0, // 정사각형 비율
              ),
              itemCount: _imageAssets.length,
              itemBuilder: (context, index) {
                return _buildImageItem(_imageAssets[index], index);
              },
            ),
          ),

          // 우측 스와이프 제스처로 맵 이동
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 400) {
                  Navigator.pushReplacementNamed(
                    context,
                    '/main',
                    arguments: {'initialTab': 1},
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 이미지 아이템을 구성하는 메서드
  Widget _buildImageItem(String imageAsset, int index) {
    return GestureDetector(
      onTap: () => _confirmAndPurchase(index),
      child: Container(
        decoration: BoxDecoration(
          // color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade800, width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Column(
              children: [
                // 이미지
                Expanded(
                  child: Image.asset(
                    imageAsset,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade800,
                        child: const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 40.0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 18),
                // 하단 컨테이너 - width 63, height 27
                Container(
                  width: 63,
                  height: 27,
                  decoration: BoxDecoration(
                    // color: Colors.white,
                    borderRadius: BorderRadius.circular(35.0),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 5),
                      Image.asset(
                        'assets/images/coin.png',
                        width: 22,
                        height: 18,
                      ),
                      SizedBox(width: 5),
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            colors: [
                              Color(0xFFDE3397), // 빨간색 계열
                              Color(0xFFF46061), // 주황색 계열
                              Color(0xFFFEA440), // 노란색 계열
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: Text(
                          '${_itemPrices[index]}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // ShaderMask를 사용할 때는 흰색으로 설정
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 구매한 아이콘 아이템을 구성하는 메서드
  Widget _buildPurchasedIconItem(String iconAsset, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade800, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.asset(
          iconAsset,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade800,
              child: const Center(
                child: Icon(Icons.error, color: Colors.red, size: 40.0),
              ),
            );
          },
        ),
      ),
    );
  }
}
