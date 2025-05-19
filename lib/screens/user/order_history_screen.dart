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

  // Thêm hàm cập nhật trạng thái đơn hàng
  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await SupabaseService.updateOrderStatus(orderId, status);
      // Tải lại danh sách đơn hàng sau khi cập nhật
      await _loadOrders();
      // Hiển thị thông báo thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng')),
        );
      }
    } catch (e) {
      // Hiển thị thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
        );
      }
    }
  }
  
  // Tạo nút cập nhật trạng thái
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
  
  // Hiển thị hộp thoại xác nhận hủy đơn hàng
  void _showCancelConfirmation(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy đơn hàng'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng hộp thoại xác nhận
              _updateOrderStatus(orderId, 'cancelled');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Có, hủy đơn hàng'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailDialog(Map<String, dynamic> order) async {
    // Chỉ lấy thông tin tổng tiền, bỏ phần xử lý danh sách sản phẩm
    double totalAmount = 0;
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
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxWidth: 400, 
              maxHeight: 480, // Giảm chiều cao vì bỏ phần danh sách sản phẩm
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
          mainAxisSize: MainAxisSize.min,
              children: [
                // Header với title và icon close
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chi tiết đơn hàng\n#${_shortenId(order['id'] ?? '')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                
                // Trạng thái đơn hàng
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Trạng thái đơn hàng:",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(order['created_at']),
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order['status'] ?? ''),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(order['status'] ?? ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Thông tin khách hàng
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      const Text(
                        "Thông tin khách hàng",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
            const SizedBox(height: 8),
            Row(
              children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              "Người nhận:",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Text(
                              order['customer_name'] ?? 'Vô danh',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              "Số điện thoại:",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Text(
                              order['phone'] ?? '...',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              "Địa chỉ:",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Text(
                              order['address'] ?? '...',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Khoảng trống
                const Spacer(),
                
                // Tổng thanh toán
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tổng thanh toán:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        order['total_amount']?.toString() ?? formatTotalAmount(totalAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Nút đóng
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
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

  // Hàng hiển thị thông tin
  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Add refresh button
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
                            title: Text('Mã đơn: ${order['id'] ?? ''}'),
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