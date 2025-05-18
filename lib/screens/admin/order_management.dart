import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

// Biến global để lưu trữ reference đến BuildContext hiện tại
final GlobalKey<ScaffoldMessengerState> orderManagementScaffoldKey = GlobalKey<ScaffoldMessengerState>();

class OrderManagement extends StatefulWidget {
  const OrderManagement({super.key});

  @override
  State<OrderManagement> createState() => _OrderManagementState();
}

class _OrderManagementState extends State<OrderManagement> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await SupabaseService.getAllOrders();
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải đơn hàng: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_searchQuery.isEmpty && _selectedStatus.isEmpty) {
      return _orders;
    }
    
    return _orders.where((order) {
      bool matchesSearch = _searchQuery.isEmpty || 
        order['id'].toString().contains(_searchQuery) || 
        (order['user_id'] ?? '').toString().contains(_searchQuery) ||
        (order['phone'] ?? '').toString().contains(_searchQuery) ||
        (order['address'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesStatus = _selectedStatus.isEmpty || order['status'] == _selectedStatus;
      
      return matchesSearch && matchesStatus;
    }).toList();
  }

  // Hàm cập nhật trạng thái đơn hàng
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      
      _loadOrders();
      
      // Sử dụng ScaffoldMessenger an toàn
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái đơn hàng thành công')),
        );
      }
    } catch (e) {
      // Sử dụng ScaffoldMessenger an toàn
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
        );
      }
    }
  }

  // Hiển thị thông tin chi tiết đơn hàng
  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chi tiết đơn hàng #${order['id']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('ID:', order['id'].toString()),
                _buildInfoRow('Ngày đặt:', _formatDate(order['created_at'])),
                _buildInfoRow('Khách hàng:', order['user_email'] ?? 'Không có thông tin'),
                _buildInfoRow('Số điện thoại:', order['phone'] ?? 'Không có'),
                _buildInfoRow('Địa chỉ:', order['address'] ?? 'Không có'),
                _buildInfoRow('Tổng tiền:', '${order['total_amount']} đ'),
                _buildInfoRow('Trạng thái:', _getStatusText(order['status'])),
                
                const SizedBox(height: 16),
                const Text('Các sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Hiển thị danh sách sản phẩm trong đơn hàng
                if (order['items'] != null && order['items'] is List)
                  ...List<Widget>.from(
                    (order['items'] as List).map((item) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Text('${item['quantity']}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(item['product_name'] ?? 'Sản phẩm')),
                            Text('${item['price']} đ'),
                          ],
                        ),
                      )
                    )
                  ),
                
                const SizedBox(height: 16),
                const Text('Cập nhật trạng thái:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Các nút cập nhật trạng thái
                Wrap(
                  spacing: 8,
                  children: [
                    _buildStatusButton('pending', 'Chờ xác nhận', order, Colors.orange),
                    _buildStatusButton('confirmed', 'Đã xác nhận', order, Colors.blue),
                    _buildStatusButton('shipping', 'Đang giao', order, Colors.purple),
                    _buildStatusButton('delivered', 'Đã giao hàng', order, Colors.teal),
                    _buildStatusButton('cancelled', 'Đã hủy', order, Colors.red),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  // Build hàng thông tin
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Build nút cập nhật trạng thái
  Widget _buildStatusButton(String status, String label, Map<String, dynamic> order, Color color) {
    bool isCurrentStatus = order['status'] == status;
    
    return ElevatedButton(
      onPressed: isCurrentStatus ? null : () {
        Navigator.of(context).pop();
        _updateOrderStatus(order['id'], status);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withOpacity(0.7),
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      child: Text(label),
    );
  }

  // Format date string
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Không có';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateString;
    }
  }

  // Chuyển đổi mã trạng thái thành text hiển thị
  String _getStatusText(String? status) {
    switch (status) {
      case 'pending': return 'Chờ xác nhận';
      case 'confirmed': return 'Đã xác nhận';
      case 'shipping': return 'Đang giao hàng';
      case 'delivered': return 'Đã giao hàng';
      case 'cancelled': return 'Đã hủy';
      default: return status ?? 'Không xác định';
    }
  }

  // Lấy màu cho trạng thái
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'shipping': return Colors.purple;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Đơn hàng'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm đơn hàng theo ID, SĐT, địa chỉ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Bộ lọc trạng thái
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Lọc theo trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedStatus.isEmpty ? null : _selectedStatus,
                  hint: const Text('Tất cả'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Tất cả')),
                    const DropdownMenuItem(value: 'pending', child: Text('Chờ xác nhận')),
                    const DropdownMenuItem(value: 'confirmed', child: Text('Đã xác nhận')),
                    const DropdownMenuItem(value: 'shipping', child: Text('Đang giao')),
                    const DropdownMenuItem(value: 'delivered', child: Text('Đã giao hàng')),
                    const DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? '';
                    });
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _loadOrders,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại'),
                ),
              ],
            ),
          ),
          
          // Thông tin hiển thị số lượng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Hiển thị ${_filteredOrders.length} đơn hàng',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Nội dung chính
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : _filteredOrders.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Không có đơn hàng nào',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        : _buildOrderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Text(
                  '#${order['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(order['status']),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14),
                    const SizedBox(width: 4),
                    Text(_formatDate(order['created_at'])),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14),
                    const SizedBox(width: 4),
                    Text(order['user_email'] ?? 'Không có thông tin người dùng'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14),
                    const SizedBox(width: 4),
                    Text(order['phone'] ?? 'Không có SĐT'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng tiền: ${order['total_amount']} đ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {
                _showOrderDetails(order);
              },
            ),
            onTap: () {
              _showOrderDetails(order);
            },
          ),
        );
      },
    );
  }
} 