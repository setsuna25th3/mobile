import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import 'cart_screen.dart';
import '../../services/supabase_service.dart';

// Alias tạm thời để giữ khả năng tương thích
class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GioHangFruitStore();
  }
}

class PageDetailProduct extends StatelessWidget {
  final Product sp;
  final controller = Get.find<ProductController>();

  PageDetailProduct({super.key, required this.sp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết sản phẩm"),
        backgroundColor: Colors.green,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GioHangFruitStore(),
                    ),
                  );
                },
              ),
              Positioned(
                top: 5,
                right: 5,
                child: GetX<ProductController>(
                  builder: (controller) {
                    if (controller.slmh == 0) return SizedBox();
                    return Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        "${controller.slmh}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product image
            SizedBox(
              height: 250,
              child: sp.image != null
                  ? Image.network(
                      sp.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error, size: 100),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 100),
                    ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sp.ten,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildCategoryChip(sp.category),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Mô tả:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sp.moTa,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Giá: ${sp.gia.toStringAsFixed(0)}đ",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        "Tồn kho: ${sp.stock}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () => _handleAddToCart(context),
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text(
                          "Thêm vào giỏ hàng",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _handleAddToCart(BuildContext context) async {
    if (!SupabaseService.isLoggedIn()) {
      Navigator.of(context).pushNamed('/login');
      return;
    }
    final success = await controller.addGioHang(sp);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã thêm ${sp.ten} vào giỏ hàng"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCategoryChip(ProductCategory category) {
    Color chipColor;
    String label;
    
    switch(category) {
      case ProductCategory.FOOD:
        chipColor = Colors.orange;
        label = 'Đồ ăn';
        break;
      case ProductCategory.DRINK:
        chipColor = Colors.blue;
        label = 'Nước uống';
        break;
      case ProductCategory.SNACK:
        chipColor = Colors.purple;
        label = 'Bánh kẹo';
        break;
    }
    
    return Chip(
      backgroundColor: chipColor.withOpacity(0.2),
      label: Text(
        label,
        style: TextStyle(fontSize: 14, color: chipColor),
      ),
    );
  }
} 