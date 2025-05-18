import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
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

  void _showOrderDetailDialog(Map<String, dynamic> order) async {
    // Lấy chi tiết đơn hàng nếu cần (ở đây giả sử order đã có đủ thông tin)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã đơn: ${order['id'] ?? ''}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(_getStatusText(order['status'] ?? ''), style: TextStyle(color: Colors.white)),
                  backgroundColor: _getStatusColor(order['status'] ?? ''),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Ngày đặt: ${order['created_at']?.toString().substring(0, 16) ?? ''}'),
            if (order['address'] != null) Text('Địa chỉ: ${order['address']}'),
            if (order['phone'] != null) Text('SĐT: ${order['phone']}'),
            if (order['total_amount'] != null) Text('Tổng tiền: ${order['total_amount']} đ'),
            // Có thể bổ sung danh sách sản phẩm nếu có
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _orders.isEmpty
                  ? const Center(child: Text('Bạn chưa có đơn hàng nào'))
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.separated(
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return ListTile(
                            leading: Icon(Icons.receipt_long, color: Colors.green),
                            title: Text('Mã đơn: ${order['id'] ?? ''}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ngày: ${order['created_at']?.toString().substring(0, 16) ?? ''}'),
                                Row(
                                  children: [
                                    const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Chip(
                                      label: Text(_getStatusText(order['status'] ?? ''), style: TextStyle(color: Colors.white)),
                                      backgroundColor: _getStatusColor(order['status'] ?? ''),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Icon(Icons.visibility, size: 18),
                            onTap: () => _showOrderDetailDialog(order),
                          );
                        },
                      ),
                    ),
    );
  }
} 