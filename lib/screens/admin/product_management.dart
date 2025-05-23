import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../services/supabase_service.dart';
import 'add_product_page.dart';
import 'edit_product_page.dart';

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});
  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await SupabaseService.getAllProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi khi tải sản phẩm: $e';
      });
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text("Bạn muốn xóa ${product['ten']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.deleteProduct(product['id']);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã xóa ${product['ten']}")));
        _loadProducts(); // Refresh danh sách
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _navigateToAddProduct() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddProductPage()),
    );
    if (result == true) _loadProducts(); // Refresh nếu thêm thành công
  }

  void _navigateToEditProduct(Map<String, dynamic> product) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EditProductPage(product: product)),
    );
    if (result == true) _loadProducts(); // Refresh nếu sửa thành công
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Sản phẩm"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadProducts, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _products.isEmpty
                  ? const Center(child: Text('Chưa có sản phẩm nào'))
                  : Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: ListView.separated(
                        itemBuilder: (context, index) {
                          var product = _products[index];
                          return Slidable(
                            key: ValueKey(product['id']),
                            endActionPane: ActionPane(
                              extentRatio: 0.7,
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) => _navigateToEditProduct(product),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: 'Sửa',
                                ),
                                SlidableAction(
                                  onPressed: (_) => _deleteProduct(product),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete_forever,
                                  label: 'Xóa',
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Image.network(
                                    product['image'] ?? "https://via.placeholder.com/150",
                                    height: 80,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 80),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${product['id']} - ${product['ten']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text("${product['gia']}đ", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                      Text(product['mota'] ?? ""),
                                      Text("Tồn: ${product['stock'] ?? 0}"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => const Divider(thickness: 1.5),
                        itemCount: _products.length,
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        child: const Icon(Icons.add),
      ),
    );
  }
} 