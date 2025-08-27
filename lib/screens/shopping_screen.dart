import 'package:flutter/material.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['이모지', '프로필 이미지', '테마'];

  final List<ShopItem> _emojiItems = [
    ShopItem(
      id: 'emoji_1',
      name: '행복한 이모지',
      description: '기분 좋은 하루를 표현하는 이모지',
      price: 1000,
      imageUrl: '😊',
      isUnlocked: false,
    ),
    ShopItem(
      id: 'emoji_2',
      name: '여행 이모지',
      description: '새로운 장소를 탐험하는 이모지',
      price: 1500,
      imageUrl: '✈️',
      isUnlocked: false,
    ),
    ShopItem(
      id: 'emoji_3',
      name: '카페 이모지',
      description: '맛있는 커피와 함께하는 이모지',
      price: 1200,
      imageUrl: '☕',
      isUnlocked: false,
    ),
    ShopItem(
      id: 'emoji_4',
      name: '운동 이모지',
      description: '활동적인 하루를 표현하는 이모지',
      price: 1000,
      imageUrl: '💪',
      isUnlocked: false,
    ),
  ];

  final List<ShopItem> _profileItems = [
    ShopItem(
      id: 'profile_1',
      name: '클래식 프로필',
      description: '깔끔하고 세련된 프로필 이미지',
      price: 2000,
      imageUrl: '👤',
      isUnlocked: false,
    ),
    ShopItem(
      id: 'profile_2',
      name: '아트 프로필',
      description: '예술적인 느낌의 프로필 이미지',
      price: 2500,
      imageUrl: '🎨',
      isUnlocked: false,
    ),
    ShopItem(
      id: 'profile_3',
      name: '네이처 프로필',
      description: '자연을 테마로 한 프로필 이미지',
      price: 1800,
      imageUrl: '🌿',
      isUnlocked: false,
    ),
  ];

  final List<ShopItem> _themeItems = [
    ShopItem(
      id: 'theme_1',
      name: '다크 테마',
      description: '어두운 배경의 세련된 테마',
      price: 3000,
      imageUrl: '🌙',
      isUnlocked: false,
    ),
    ShopItem(
      id: 'theme_2',
      name: '컬러풀 테마',
      description: '화려한 색상의 활기찬 테마',
      price: 2800,
      imageUrl: '🌈',
      isUnlocked: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '쇼핑',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.black,),
            onPressed: () {
              Navigator.pushNamed(context, '/main'); // 👉 /main으로 이동
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black,),
            onPressed: () {
              // 장바구니 페이지로 이동
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 탭
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedCategoryIndex == index
                                ? Colors.green
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        category,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedCategoryIndex == index
                              ? Colors.green
                              : Colors.grey,
                          fontWeight: _selectedCategoryIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 상품 목록
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    List<ShopItem> items;
    switch (_selectedCategoryIndex) {
      case 0:
        items = _emojiItems;
        break;
      case 1:
        items = _profileItems;
        break;
      case 2:
        items = _themeItems;
        break;
      default:
        items = _emojiItems;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildProductCard(items[index]);
      },
    );
  }

  Widget _buildProductCard(ShopItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 상품 이미지
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  item.imageUrl,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),

          // 상품 정보
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.price}원',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: item.isUnlocked
                            ? null
                            : () {
                                _purchaseItem(item);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: item.isUnlocked
                              ? Colors.grey
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          item.isUnlocked ? '보유' : '구매',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _purchaseItem(ShopItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('구매 확인'),
        content: Text('${item.name}을(를) ${item.price}원에 구매하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item.isUnlocked = true;
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} 구매 완료!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('구매'),
          ),
        ],
      ),
    );
  }
}

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String imageUrl;
  bool isUnlocked;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isUnlocked = false,
  });
}
