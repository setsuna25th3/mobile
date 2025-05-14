import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import '../../models/nguoi_nhan.dart';
import '../../services/supabase_service.dart';

class GioHang_Fruit_store extends StatelessWidget {
  const GioHang_Fruit_store({super.key});

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
                  itemCount: controller.slmh,
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

class ThongTinThanhToanScreen extends StatelessWidget {
  final double tongThanhToan;

  const ThongTinThanhToanScreen({Key? key, required this.tongThanhToan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tenNguoiNhanController = TextEditingController();
    final diaChiController = TextEditingController();
    final soDienThoaiController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin thanh toán"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
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
            Text("Tổng thanh toán: $tongThanhToan VND", style: TextStyle(fontSize: 25),),
            // Nút xác nhận thanh toán
            ElevatedButton(
              onPressed: () async {
                // Kiểm tra xem các trường thông tin đã được nhập hay chưa
                if (tenNguoiNhanController.text.isEmpty ||
                    diaChiController.text.isEmpty ||
                    soDienThoaiController.text.isEmpty) {
                  // Nếu có bất kỳ trường nào chưa được nhập, hiển thị thông báo yêu cầu nhập đủ thông tin
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
                  // Nếu tất cả các trường đã được nhập đủ, thực hiện hành động thanh toán
                  final thongTinNguoiNhan = ThongTinNguoiNhan(
                    tenNguoiNhan: tenNguoiNhanController.text,
                    diaChi: diaChiController.text,
                    soDienThoai: soDienThoaiController.text,
                  );
                  
                  await thongTinNguoiNhan.luuThongTinNguoiNhan();

                  // Lưu thông tin hóa đơn vào Supabase
                  await supabase.from('hoa_don').insert({
                    'tenNguoiNhan': tenNguoiNhanController.text,
                    'diaChi': diaChiController.text,
                    'soDienThoai': soDienThoaiController.text,
                    'tongThanhToan': tongThanhToan,
                  });

                  // Xóa giỏ hàng sau khi thanh toán
                  Get.find<ProductController>().xoahet();

                  // Hiển thị thông báo thanh toán thành công
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Thanh toán thành công"),
                      content: const Text("Cảm ơn bạn đã mua hàng!"),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context); // Quay về trang giỏ hàng
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    ),
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
} 