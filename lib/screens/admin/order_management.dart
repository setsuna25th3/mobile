import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class OrderManagement extends StatefulWidget {
  const OrderManagement({super.key});

  @override
  State<OrderManagement> createState() => _OrderManagementState();
}

class _OrderManagementState extends State<OrderManagement> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Lấy orders với user_profiles join (theo foreign key đã tạo)
      final ordersData = await supabase
          .from('orders')
          .select('''
            *,
            user_profiles!orders_user_profiles_fkey(
              id,
              full_name,
              phone,
              email
            )
          ''')
          .order('created_at', ascending: false);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(ordersData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi khi tải đơn hàng: $e';
      });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Đang xử lý';
      case 'confirmed': return 'Đã xác nhận';
      case 'delivered': return 'Đã giao';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng')),
      );

      // Tải lại danh sách
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) async {
    try {
      // Lấy order_items với products join (theo foreign key relationships)
      List<Map<String, dynamic>> orderItems = [];
      
      try {
        // Thử với relationship name đầu tiên
        orderItems = await Supabase.instance.client
            .from('order_items')
            .select('''
              *,
              products!order_items_product_id_fkey(
                id,
                ten,
                gia,
                image,
                category
              )
            ''')
            .eq('order_id', order['id']);
      } catch (e) {
        try {
          // Fallback: Thử với tên relationship khác
          orderItems = await Supabase.instance.client
              .from('order_items')
              .select('''
                *,
                products!fk_product_id(
                  id,
                  ten,
                  gia,
                  image,
                  category
                )
              ''')
              .eq('order_id', order['id']);
        } catch (e2) {
          // Fallback cuối: Manual join
          final rawOrderItems = await Supabase.instance.client
              .from('order_items')
              .select('*')
              .eq('order_id', order['id']);
          
          for (var item in rawOrderItems) {
            try {
              final product = await Supabase.instance.client
                  .from('products')
                  .select('*')
                  .eq('id', item['product_id'])
                  .single();
              
              orderItems.add({
                ...item,
                'products': product,
              });
            } catch (productError) {
              orderItems.add({
                ...item,
                'products': null,
              });
            }
          }
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Chi tiết đơn hàng\n#${_shortenId(order['id'])}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin khách hàng
                  Text('Khách hàng: ${order['customer_name'] ?? order['user_profiles']?['full_name'] ?? 'N/A'}'),
                  Text('Số điện thoại: ${order['phone'] ?? order['user_profiles']?['phone'] ?? 'N/A'}'),
                  Text('Email: ${order['user_profiles']?['email'] ?? 'N/A'}'),
                  Text('Địa chỉ: ${order['address'] ?? 'N/A'}'),
                  Text('Tổng tiền: ${order['total_amount']?.toStringAsFixed(0) ?? '0'}đ'),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Trạng thái đơn hàng
                  Row(
                    children: [
                      const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Chip(
                        label: Text(_getStatusText(order['status'])),
                        backgroundColor: _getStatusColor(order['status']).withOpacity(0.2),
                        labelStyle: TextStyle(color: _getStatusColor(order['status'])),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Text('Sản phẩm đã đặt:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  // Danh sách sản phẩm
                  ...orderItems.map<Widget>((item) {
                    final product = item['products'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product?['image'] ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product?['ten'] ?? 'Sản phẩm đã xóa', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Số lượng: ${item['quantity']}'),
                                Text('Đơn giá: ${item['price']?.toStringAsFixed(0) ?? '0'}đ'),
                                Text('Thành tiền: ${((item['quantity'] ?? 0) * (item['price'] ?? 0)).toStringAsFixed(0)}đ', 
                                     style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải chi tiết: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _shortenId(String id) {
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
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
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Chưa có đơn hàng nào', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final userProfile = order['user_profiles'];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(order['status']),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text('Đơn hàng #${_shortenId(order['id'])}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Khách: ${order['customer_name'] ?? userProfile?['full_name'] ?? 'N/A'}'),
                                Text('Tổng: ${order['total_amount']?.toStringAsFixed(0) ?? '0'}đ'),
                                Text('Ngày: ${_formatDateTime(order['created_at'])}'),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (status) => _updateOrderStatus(order['id'], status),
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'pending', child: Text('Đang xử lý')),
                                const PopupMenuItem(value: 'confirmed', child: Text('Đã xác nhận')),
                                const PopupMenuItem(value: 'delivered', child: Text('Đã giao')),
                                const PopupMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                              ],
                              child: Chip(
                                label: Text(_getStatusText(order['status'])),
                                backgroundColor: _getStatusColor(order['status']).withOpacity(0.2),
                                labelStyle: TextStyle(color: _getStatusColor(order['status'])),
                              ),
                            ),
                            onTap: () => _showOrderDetails(order),
                          ),
                        );
                      },
                    ),
    );
  }
} 