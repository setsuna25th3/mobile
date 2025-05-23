import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  final supabase = Supabase.instance.client;

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
      final userId = SupabaseService.getCurrentUserId();
      
      if (userId == null) throw 'Không tìm thấy người dùng';
      
      final orders = await SupabaseService.getOrdersByUser(userId);
      
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
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

  // Định dạng ngày tháng
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Không có thông tin';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute < 10 ? '0${date.minute}' : date.minute}';
    } catch (e) {
      return dateString.length > 16 ? dateString.substring(0, 16) : dateString;
    }
  }

  void _showOrderDetailDialog(Map<String, dynamic> order) async {
    // Lấy chi tiết sản phẩm từ order_items
    List<Map<String, dynamic>> orderItems = [];
    double totalAmount = 0;
    
    try {
      // Lấy order items từ supabase với fallback
      final supabase = Supabase.instance.client;
      
      // Thử các relationship names khác nhau
      try {
        // Thử với foreign key constraint cụ thể
        orderItems = await supabase
            .from('order_items')
            .select('''
              *,
              products!order_items_product_id_fkey(
                id,
                ten,
                gia,
                image,
                category,
                mota,
                stock
              )
            ''')
            .eq('order_id', order['id']);
      } catch (e) {
        try {
          // Fallback: Thử với tên relationship khác
          orderItems = await supabase
              .from('order_items')
              .select('''
                *,
                products!fk_product_id(
                  id,
                  ten,
                  gia,
                  image,
                  category,
                  mota,
                  stock
                )
              ''')
              .eq('order_id', order['id']);
        } catch (e2) {
          // Fallback cuối: Manual join
          final rawOrderItems = await supabase
              .from('order_items')
              .select('*')
              .eq('order_id', order['id']);
          
          for (var item in rawOrderItems) {
            try {
              final product = await supabase
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
      
      // Tính tổng tiền từ order items
      totalAmount = orderItems.fold(0.0, (sum, item) {
        final quantity = item['quantity'] ?? 0;
        final price = item['price'] ?? 0;
        return sum + (quantity * price);
      });
      
    } catch (e) {
      // Fallback sử dụng total_amount từ order nếu không lấy được order_items
      if (order['total_amount'] != null) {
        if (order['total_amount'] is num) {
          totalAmount = (order['total_amount'] as num).toDouble();
        } else {
          try {
            totalAmount = double.parse(order['total_amount'].toString());
          } catch (_) {
            totalAmount = 0;
          }
        }
      }
    }
    
    String formatTotalAmount(double amount) {
      if (amount % 1 == 0) {
        return "${amount.toInt()}đ";
      } else {
        return "${amount.toStringAsFixed(2)}đ";
      }
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chi tiết đơn hàng\n#${_shortenId(order['id'] ?? '')}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin đơn hàng
                  Text('Ngày đặt: ${_formatDate(order['created_at'])}'),
                  Row(
                    children: [
                      const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Chip(
                        label: Text(_getStatusText(order['status'] ?? '')),
                        backgroundColor: _getStatusColor(order['status'] ?? ''),
                        labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Thông tin khách hàng
                  Text('Người nhận: ${order['customer_name'] ?? 'Vô danh'}'),
                  Text('Số điện thoại: ${order['phone'] ?? '...'}'),
                  Text('Địa chỉ: ${order['address'] ?? '...'}'),
                  
                  const SizedBox(height: 16),
                  const Text('Sản phẩm đã đặt:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  // Danh sách sản phẩm
                  if (orderItems.isNotEmpty) ...[
                    ...orderItems.map<Widget>((item) {
                      final product = item['products'];
                      final quantity = item['quantity'] ?? 0;
                      final price = item['price'] ?? 0;
                      final subtotal = quantity * price;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // Hình ảnh sản phẩm
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product != null && product['image'] != null 
                                  ? Image.network(
                                      product['image'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[300],
                                          child: Icon(Icons.image_not_supported),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[300],
                                      child: Icon(Icons.fastfood),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Thông tin sản phẩm
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product?['ten'] ?? 'Sản phẩm #${item['product_id']?.toString().substring(0, 8)}...',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Số lượng: $quantity'),
                                  Text('Đơn giá: ${formatTotalAmount(price.toDouble())}'),
                                  Text(
                                    'Thành tiền: ${formatTotalAmount(subtotal.toDouble())}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        'Không thể tải chi tiết sản phẩm',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  
                  // Tổng thanh toán
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tổng thanh toán:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        formatTotalAmount(totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
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
        );
      },
    );
  }

  // Rút gọn ID đơn hàng để hiển thị
  String _shortenId(String id) {
    if (id.length > 8) {
      return '${id.substring(0, 8)}...';
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          
              ? _buildErrorWidget()
              : _orders.isEmpty
                  ? _buildEmptyOrdersWidget()
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.separated(
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return ListTile(
                            leading: const Icon(Icons.receipt_long, color: Colors.green),
                            title: Text('Mã đơn: ${_shortenId(order['id'] ?? '')}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ngày: ${_formatDate(order['created_at'])}'),
                                Row(
                                  children: [
                                    const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Chip(
                                      label: Text(
                                        _getStatusText(order['status'] ?? ''), 
                                        style: const TextStyle(color: Colors.white, fontSize: 12)
                                      ),
                                      backgroundColor: _getStatusColor(order['status'] ?? ''),
                                      padding: EdgeInsets.zero,
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.visibility, size: 18),
                            onTap: () => _showOrderDetailDialog(order),
                          );
                        },
                      ),
                    ),
    );
  }
  
  Widget _buildEmptyOrdersWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long,
            size: 70,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa có đơn hàng nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy đặt hàng để xem lịch sử đơn hàng của bạn',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Mua sắm ngay'),
            onPressed: () {
              Navigator.of(context).pop(); // Return to previous screen
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 70,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Đã xảy ra lỗi',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            onPressed: _loadOrders,
          ),
        ],
      ),
    );
  }
} 