import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import '../../services/supabase_service.dart';
import 'detail_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'order_history_screen.dart';

// Type alias cho dễ đọc
typedef CartScreen = GioHangFruitStore;

class HomePageFood extends StatelessWidget {
  HomePageFood({Key? key}) : super(key: key);
  final controller = Get.put(ProductController());

  @override
  Widget build(BuildContext context) {
    // Sync cart nếu user đã login
    if (SupabaseService.isLoggedIn()) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await controller.syncCartFromDatabase();
      });
    }
    
    final searchController = TextEditingController();
    String searchQuery = '';
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cửa hàng Đồ ăn"),
        backgroundColor: Colors.green,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  if (SupabaseService.isLoggedIn()) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CartScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(context).pushNamed('/login');
                  }
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: FutureBuilder<Map<String, dynamic>?>(
                future: SupabaseService.getCurrentUser(),
                builder: (context, snapshot) {
                  String userName = 'Khách';
                  String greeting = 'Xin chào!';
                  
                  if (SupabaseService.isLoggedIn() && snapshot.hasData && snapshot.data != null) {
                    userName = snapshot.data!['full_name'] ?? 'Người dùng';
                    greeting = 'Xin chào,';
                  } else if (!SupabaseService.isLoggedIn()) {
                    greeting = 'Chào mừng!';
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          SupabaseService.isLoggedIn() ? Icons.person : Icons.person_outline,
                          size: 35,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        greeting,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (SupabaseService.isLoggedIn()) ...[
                        Text(
                          userName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          'Vui lòng đăng nhập',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Trang chủ'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // Giỏ hàng luôn hiển thị
            ListTile(
              leading: Stack(
                children: [
                  Icon(Icons.shopping_cart),
                  if (controller.slmh > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${controller.slmh}',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text('Giỏ hàng'),
              onTap: () {
                Navigator.pop(context);
                if (SupabaseService.isLoggedIn()) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => CartScreen()));
                } else {
                  Navigator.of(context).pushNamed('/login');
                }
              },
            ),
            // Tài khoản của tôi luôn hiển thị
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Tài khoản của tôi'),
              onTap: () {
                Navigator.pop(context);
                if (SupabaseService.isLoggedIn()) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProfileScreen()));
                } else {
                  Navigator.of(context).pushNamed('/login');
                }
              },
            ),
            // Lịch sử đơn hàng luôn hiển thị
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Lịch sử đơn hàng'),
              onTap: () {
                Navigator.pop(context);
                if (SupabaseService.isLoggedIn()) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => OrderHistoryScreen()));
                } else {
                  Navigator.of(context).pushNamed('/login');
                }
              },
            ),
            Divider(),
            if (SupabaseService.isLoggedIn()) ... [
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  
                  // Clear the cart before logging out
                  if (Get.isRegistered<ProductController>()) {
                    final productController = Get.find<ProductController>();
                    await productController.xoahet(); // Clear the cart
                  }
                  
                  await SupabaseService.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => HomePageFood()),
                    (route) => false,
                  );
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(Icons.login, color: Colors.green),
                title: Text('Đăng nhập', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/login');
                },
              ),
            ],
          ],
        ),
      ),
      body: GetBuilder<ProductController>(
        init: controller,
        builder: (_) {
          final filtered = searchController.text.isEmpty
              ? controller.dssp
              : controller.dssp.where((sp) =>
                  sp.ten.toLowerCase().contains(searchController.text.toLowerCase()) ||
                  sp.moTa.toLowerCase().contains(searchController.text.toLowerCase())
                ).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: searchController,
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                searchController.clear();
                                controller.update();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => controller.update(),
                  ),
                ),
              ),
              if (searchController.text.isNotEmpty)
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text("Không có sản phẩm nào"))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(),
                          itemBuilder: (context, index) {
                            final sp = filtered[index];
                            return ListTile(
                              leading: sp.image != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        sp.image!,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.image_not_supported),
                                      ),
                                    )
                                  : const Icon(Icons.image_not_supported, size: 40),
                              title: Text(sp.ten, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${sp.gia} đ', style: TextStyle(color: Colors.green)),
                                  if (sp.stock != null) Text('Tồn kho: ${sp.stock}', style: TextStyle(fontSize: 12, color: Colors.orange)),
                                ],
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PageDetailProduct(sp: sp),
                                ),
                              ),
                              trailing: ElevatedButton.icon(
                                icon: const Icon(Icons.add_shopping_cart, size: 18),
                                label: const Text('Thêm vào giỏ'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onPressed: () => _handleAddToCart(context, sp),
                              ),
                            );
                          },
                        ),
                )
              else ...[
          _buildCategoryBar(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GetX<ProductController>(
                builder: (controller) {
                  if (controller.dssp.isEmpty) {
                    return Center(child: Text("Không có sản phẩm nào"));
                  }
                  return GridView.builder(
                    itemCount: controller.dssp.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      var sp = controller.dssp[index];
                      return Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PageDetailProduct(sp: sp),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: sp.image != null
                                          ? Image.network(
                                        sp.image!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.error, size: 50),
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(child: CircularProgressIndicator());
                                        },
                                      )
                                          : const Icon(Icons.image_not_supported, size: 50),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  sp.ten,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _getCategoryChip(sp.category),
                                          if (sp.stock != null) ...[
                                            SizedBox(width: 8),
                                            Chip(
                                              label: Text('Tồn: ${sp.stock}', style: TextStyle(fontSize: 10, color: Colors.white)),
                                              backgroundColor: Colors.orange,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ],
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${sp.gia} đ",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add_shopping_cart, color: Colors.green),
                                      onPressed: () => _handleAddToCart(context, sp),
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
                },
              ),
            ),
          ),
        ],
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _handleAddToCart(BuildContext context, Product product) async {
    if (!SupabaseService.isLoggedIn()) {
      Navigator.of(context).pushNamed('/login');
      return;
    }
    
    final success = await controller.addGioHang(product);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã thêm ${product.ten} vào giỏ hàng"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Không thể thêm ${product.ten} vào giỏ hàng"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  Widget _buildCategoryBar(BuildContext context) {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        children: [
          _buildCategoryButton(null, 'Tất cả'),
          SizedBox(width: 10),
          _buildCategoryButton(ProductCategory.FOOD, 'Đồ ăn'),
          SizedBox(width: 10),
          _buildCategoryButton(ProductCategory.DRINK, 'Nước uống'),
          SizedBox(width: 10),
          _buildCategoryButton(ProductCategory.SNACK, 'Bánh kẹo'),
        ],
      ),
    );
  }
  
  Widget _buildCategoryButton(ProductCategory? category, String label) {
    return Obx(() {
      final isSelected = controller.selectedCategory == category;
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
        ),
        onPressed: () {
          controller.setCategory(category);
        },
        child: Text(label),
      );
    });
  }
  
  Widget _getCategoryChip(ProductCategory category) {
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
        style: TextStyle(fontSize: 10, color: chipColor),
      ),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<void> {
  final ProductController controller;

  CustomSearchDelegate({required this.controller});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = controller.dssp.where((sp) => sp.ten.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        var sp = results[index];
        return ListTile(
          title: Text(sp.ten),
          subtitle: Text(_getCategoryName(sp.category)),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PageDetailProduct(sp: sp),
              ),
            );
          },
        );
      },
    );
  }
  
  String _getCategoryName(ProductCategory category) {
    switch(category) {
      case ProductCategory.FOOD: return 'Đồ ăn';
      case ProductCategory.DRINK: return 'Nước uống';
      case ProductCategory.SNACK: return 'Bánh kẹo';
    }
  }
} 