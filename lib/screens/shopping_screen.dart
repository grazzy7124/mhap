import 'package:flutter/material.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: 80, // AppBar 높이를 늘려서 이미지가 잘리지 않도록 조정
        leading: Row(
          children: [
            SizedBox(width: 19.05,),
            GestureDetector(
              child: Image.asset(
                'assets/images/arrow_left.png',
                width: 18.89, height: 17.44,
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
            SizedBox(height: 20,),
            Image.asset(
              'assets/images/icon_shop.png'
            ),
          ],
        )
      ),
      body: Padding(
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
    );
  }

  /// 이미지 아이템을 구성하는 메서드
  Widget _buildImageItem(String imageAsset, int index) {
    return Container(
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
                        child: Icon(Icons.error, color: Colors.red, size: 40.0),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35.0),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 5,),
                    Image.asset(
                      'assets/images/coin.png',
                      width: 22, height: 18,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
