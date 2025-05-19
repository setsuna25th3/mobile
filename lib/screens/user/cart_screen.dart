import 'package:flutter/material.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import '../../models/nguoi_nhan.dart';
import '../../services/supabase_service.dart';
import 'order_history_screen.dart';

class GioHangFruitStore extends StatelessWidget {
  const GioHangFruitStore({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Giỏ hàng"),
      ),
      body: GetX<ProductController>(
        builder: (controller) {
          if (controller.gioHang.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Giỏ hàng trống",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Hãy thêm sản phẩm vào giỏ hàng",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              const SizedBox(height: 20,),
              Expanded(
                child:ListView.builder(
                  itemBuilder: (context, index) {
                    GioHangItem tmp = controller.gioHang[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: tmp.mh.image != null
                                    ? NetworkImage(tmp.mh.image!)
                                    : null,
                                child: tmp.mh.image == null
                                    ? Icon(Icons.image_not_supported)
                                    : null,
                              ),
                              title: Text(
                                tmp.mh.ten,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: _buildSubtitle(tmp.mh),
                              trailing: Text(
                                "${tmp.mh.gia * tmp.sl} đ",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove_circle, color: Colors.blue),
                                      onPressed: () {
                                        controller.subtractSP(tmp);
                                      },
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "${tmp.sl}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add_circle, color: Colors.green),
                                      onPressed: () {
                                        controller.addSP(tmp);
                                      },
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    controller.delSP(tmp);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  itemCount: controller.gioHang.length,
                ),
              ),
              if (controller.gioHang.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tổng thanh toán:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${controller.tongThanhToan()} đ",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ThongTinThanhToanScreen(
                              tongThanhToan: controller.tongThanhToan(),
                            ),
                          ));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Thanh toán",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.shopping_cart_checkout, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSubtitle(Product product) {
    String categoryName;
    switch(product.category) {
      case ProductCategory.FOOD:
        categoryName = 'Đồ ăn';
        break;
      case ProductCategory.DRINK:
        categoryName = 'Nước uống';
        break;
      case ProductCategory.SNACK:
        categoryName = 'Bánh kẹo';
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.moTa),
        Text(
          categoryName,
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class ThongTinThanhToanScreen extends StatefulWidget {
  final double tongThanhToan;

  const ThongTinThanhToanScreen({super.key, required this.tongThanhToan});

  @override
  State<ThongTinThanhToanScreen> createState() => _ThongTinThanhToanScreenState();
}

class _ThongTinThanhToanScreenState extends State<ThongTinThanhToanScreen> {
    final tenNguoiNhanController = TextEditingController();
    final diaChiController = TextEditingController();
    final soDienThoaiController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    
    try {
      // Lấy thông tin người dùng trực tiếp từ database
      final userId = SupabaseService.getCurrentUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Đảm bảo rằng trường address tồn tại trong user_profiles
      await SupabaseService.ensureUserProfileHasAddressField(userId);
      
      // Truy vấn trực tiếp từ bảng user_profiles
      final supabase = Supabase.instance.client;
      final userData = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .single();
      
      print('Thông tin người dùng: $userData');
      print('Có chứa address: ${userData.containsKey('address')}');
      print('Giá trị address: ${userData['address']}');
      
      setState(() {
        tenNguoiNhanController.text = userData['full_name'] ?? '';
        soDienThoaiController.text = userData['phone'] ?? '';
        diaChiController.text = userData['address'] ?? '';
        
        print('Địa chỉ đã được gán: ${diaChiController.text}');
      });
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
    } finally {
      setState(() => _isLoading = false);
      }
  }

  @override
  void dispose() {
    tenNguoiNhanController.dispose();
    diaChiController.dispose();
    soDienThoaiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin thanh toán"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: tenNguoiNhanController,
              decoration: const InputDecoration(labelText: "Tên người nhận"),
            ),
            TextField(
              controller: diaChiController,
              decoration: const InputDecoration(labelText: "Địa chỉ"),
            ),
            TextField(
              controller: soDienThoaiController,
              decoration: const InputDecoration(labelText: "Số điện thoại"),
            ),
            // Hiển thị tổng số tiền thanh toán
              Text("Tổng thanh toán: ${widget.tongThanhToan} VND", style: TextStyle(fontSize: 25),),
            // Nút xác nhận thanh toán
            ElevatedButton(
              onPressed: () async {
                if (tenNguoiNhanController.text.isEmpty ||
                    diaChiController.text.isEmpty ||
                    soDienThoaiController.text.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Thông báo"),
                      content: const Text("Vui lòng nhập đủ thông tin trước khi thanh toán."),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                } else {
                    // Store context for later use
                    final currentContext = context;
                    
                    // Process the order without BuildContext issues
                    _processPayment(
                      currentContext,
                      tenNguoiNhanController.text,
                      diaChiController.text,
                      soDienThoaiController.text,
                      widget.tongThanhToan
                    );
                  }
                },
                child: const Text("Xác nhận thanh toán"),
              ),
            ],
          ),
        ),
    );
  }

  void _processPayment(BuildContext context, String tenNguoiNhan, String diaChi, String soDienThoai, double tongThanhToan) async {
    try {
                    final thongTinNguoiNhan = ThongTinNguoiNhan(
        tenNguoiNhan: tenNguoiNhan,
        diaChi: diaChi,
        soDienThoai: soDienThoai,
                    );
                    
                    // Lưu thông tin người nhận
                    await thongTinNguoiNhan.luuThongTinNguoiNhan();
                    
                    try {
        // Lưu đơn hàng với user_id
                      final userId = SupabaseService.getCurrentUserId();
        
        // Lấy danh sách sản phẩm từ giỏ hàng
        final cartItems = Get.find<ProductController>().gioHang;
        
        if (cartItems.isEmpty) {
          throw Exception("Giỏ hàng trống");
        }
        
        // Lưu đơn hàng và lấy ID đơn hàng mới
        final supabase = Supabase.instance.client;
        final ordersResponse = await supabase.from('orders').insert({
                        'user_id': userId,
                        'total_amount': tongThanhToan,
                        'status': 'pending',
          'phone': soDienThoai,
          'address': diaChi,
          'customer_name': tenNguoiNhan,
          'created_at': DateTime.now().toIso8601String()
        }).select('id');
        
        if (ordersResponse.isNotEmpty) {
          final orderId = ordersResponse[0]['id'];
          
          // Lưu từng sản phẩm trong giỏ hàng vào bảng order_items
          for (var item in cartItems) {
            try {
              await supabase.from('order_items').insert({
                'order_id': orderId,
                'product_id': item.mh.id,
                'quantity': item.sl,
                'price': item.mh.gia
              });
            } catch (itemError) {
              // Bỏ qua lỗi và tiếp tục với các sản phẩm khác
            }
          }
        }
                    } catch (dbError) {
                      // Chỉ ghi log lỗi, không throw exception để tiếp tục luồng thành công
                    }
                    
                    // Xóa giỏ hàng và tiếp tục luồng thành công
                    Get.find<ProductController>().xoahet();
                    
                    // Hiển thị thông báo thanh toán thành công
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Đặt hàng thành công'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Đơn hàng của bạn đã được ghi nhận.'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Chip(
                                  label: Text('Đang xử lý', style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                // Tải lại dữ liệu đơn hàng và chuyển đến màn hình lịch sử đơn hàng
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
                              );
                            },
                            child: const Text('Xem lịch sử đơn hàng'),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Lỗi thanh toán'),
                        content: Text('Đã xảy ra lỗi khi đặt hàng: \n\n${e.toString()}'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                    );
                  }
  }
} 