import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import '../../services/supabase_service.dart';
import 'detail_screen.dart';
import 'cart_screen.dart';

class FoodStoreApp extends StatelessWidget {
  const FoodStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MySupabaseConnect(
        errorMessage: "Lỗi rồi!",
        connectingMessage: "Đang kết nối",
        builder: (context) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialBinding: FoodStoreBinding(),
          home: HomePageFood(),
        ),
    );
  }
}

class HomePageFood extends StatelessWidget {
  HomePageFood({Key? key}) : super(key: key);
  final controller = Get.put(ProductController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cửa hàng Đồ ăn"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: CustomSearchDelegate(controller: controller));
            },
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CartScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart),
                  GetX<ProductController>(
                    builder: (controller) {
                      return Text(
                        "${controller.slmh}",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
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
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${sp.gia} vnd",
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
      ),
    );
  }
  
  Future<void> _handleAddToCart(BuildContext context, Product product) async {
    final success = await controller.addGioHang(product);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã thêm ${product.ten} vào giỏ hàng"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
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