import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/product.dart';

// Biến global để lưu trữ reference đến BuildContext hiện tại
final GlobalKey<ScaffoldMessengerState> productManagementScaffoldKey = GlobalKey<ScaffoldMessengerState>();

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  late TabController _tabController;
  final List<String> _categories = ['TẤT CẢ', 'ĐỒ ĂN', 'NƯỚC UỐNG', 'BÁNH KẸO'];
  String _selectedCategory = 'TẤT CẢ';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadProducts();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = _categories[_tabController.index];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
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
        _errorMessage = 'Lỗi khi tải sản phẩm: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await supabase.from('products').delete().eq('id', productId);
      _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa sản phẩm thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa sản phẩm: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = _products.where((product) => 
      (product['ten'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (product['mota'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
    
    if (_selectedCategory != 'TẤT CẢ') {
      String categoryFilter = '';
      switch (_selectedCategory) {
        case 'ĐỒ ĂN': categoryFilter = 'FOOD'; break;
        case 'NƯỚC UỐNG': categoryFilter = 'DRINK'; break;
        case 'BÁNH KẸO': categoryFilter = 'SNACK'; break;
      }
      
      if (categoryFilter.isNotEmpty) {
        filtered = filtered.where((product) => 
          (product['category'] ?? '').toUpperCase() == categoryFilter
        ).toList();
      }
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sản phẩm'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
        ),
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : _filteredProducts.isEmpty
                        ? _buildEmptyState()
                        : _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.green.shade50,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hiển thị ${_filteredProducts.length} sản phẩm',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: _loadProducts,
                    icon: const Icon(Icons.refresh, color: Colors.green),
                    label: const Text('Tải lại', style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.green),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: const Text(
              'Không có sản phẩm nào',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return Container(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: _filteredProducts.length,
          itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index]),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final categoryName = _getCategoryName(product['category'] ?? 'FOOD');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: _buildProductImage(product),
          title: Text(
            product['ten'] ?? 'Không có tên',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product['mota'] ?? 'Không có mô tả',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildCategoryChip(categoryName, product['category'] ?? 'FOOD'),
                  const SizedBox(width: 8),
                  Text(
                    '${product['gia'] ?? 0}đ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStockChip(product['stock'] ?? 0),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showEditProductDialog(product),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmationDialog(product['id']),
              ),
            ],
          ),
          onTap: () => _showEditProductDialog(product),
        ),
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: product['hinh_anh'] != null
            ? Image.network(
                product['hinh_anh'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
                  );
                },
              )
            : const Center(
                child: Icon(Icons.fastfood, size: 24, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(category),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStockChip(int stock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStockColor(stock),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Tồn: $stock',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category.toUpperCase()) {
      case 'FOOD': return 'Đồ ăn';
      case 'DRINK': return 'Đồ uống';
      case 'SNACK': return 'Bánh kẹo';
      default: return 'Khác';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'FOOD': return Colors.green;
      case 'DRINK': return Colors.blue;
      case 'SNACK': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Color _getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock < 10) return Colors.orange;
    return Colors.teal;
  }

  void _showDeleteConfirmationDialog(String productId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _deleteProduct(productId);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() => _showProductDialog(null);
  void _showEditProductDialog(Map<String, dynamic> product) => _showProductDialog(product);

  void _showProductDialog(Map<String, dynamic>? product) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: product?['ten'] ?? '');
    final _priceController = TextEditingController(text: product?['gia']?.toString() ?? '');
    final _descriptionController = TextEditingController(text: product?['mota'] ?? '');
    final _imageUrlController = TextEditingController(text: product?['image'] ?? '');
    final _stockController = TextEditingController(text: product?['stock']?.toString() ?? '0');
    String selectedCategory = product?['category'] ?? 'FOOD';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(product == null ? 'Thêm Sản phẩm' : 'Sửa Sản phẩm'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                  validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập tên sản phẩm' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Giá (VNĐ)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Vui lòng nhập giá sản phẩm';
                    if (int.tryParse(value!) == null) return 'Giá không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Số lượng tồn kho'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Vui lòng nhập số lượng tồn kho';
                    if (int.tryParse(value!) == null) return 'Số lượng không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: [
                    DropdownMenuItem(value: 'FOOD', child: Text(_getCategoryName('FOOD'))),
                    DropdownMenuItem(value: 'DRINK', child: Text(_getCategoryName('DRINK'))),
                    DropdownMenuItem(value: 'SNACK', child: Text(_getCategoryName('SNACK'))),
                  ],
                  onChanged: (value) => selectedCategory = value!,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'URL hình ảnh'),
                ),
                if (_imageUrlController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _imageUrlController.text,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Text('Không thể tải hình ảnh'));
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final productData = {
                  'ten': _nameController.text,
                  'gia': int.parse(_priceController.text),
                  'mota': _descriptionController.text,
                  'image': _imageUrlController.text,
                  'category': selectedCategory,
                  'stock': int.parse(_stockController.text),
                };
                
                Navigator.of(dialogContext).pop();
                setState(() => _isLoading = true);
                
                try {
                  if (product == null) {
                    await supabase.from('products').insert(productData);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thêm sản phẩm thành công')),
                      );
                    }
                  } else {
                    await supabase
                        .from('products')
                        .update(productData)
                        .eq('id', product['id']);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cập nhật sản phẩm thành công')),
                      );
                    }
                  }
                  _loadProducts();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
} 