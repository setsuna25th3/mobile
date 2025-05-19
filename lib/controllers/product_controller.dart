import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../models/product.dart';
import '../models/product_repository.dart';

class ProductController extends GetxController {
  final _dssp = <Product>[].obs;
  final _gioHang = <GioHangItem>[].obs;
  final _selectedCategory = Rx<ProductCategory?>(null);
  
  ProductController() {
    // Login functionality removed
  }

  List<Product> get dssp => _dssp.value;
  List<GioHangItem> get gioHang => _gioHang.value;
  ProductCategory? get selectedCategory => _selectedCategory.value;
  
  // Always return true since login is removed
  bool get isLoggedIn => true;
  String get userName => "Khách hàng";

  int get slmh => gioHang.fold(0, (sum, item) => sum + item.sl);

  @override
  void onReady() {
    super.onReady();
    docDL();
  }

  void setCategory(ProductCategory? category) {
    _selectedCategory.value = category;
    docDL();
  }

  bool check_giohang(Product f) {
    for (var x in _gioHang) {
      if (x.mh.id == f.id) return true;
    }
    return false;
  }

  int find_index_GH(GioHangItem gh) {
    for (int i = 0; i < _gioHang.length; ++i) {
      if (_gioHang[i] == gh) return i;
    }
    return -1;
  }

  void addSP(GioHangItem gh) {
    int index = find_index_GH(gh);
    if (index != -1) {
      _gioHang[index].sl++;
      _gioHang.refresh();
    }
  }

  void subtractSP(GioHangItem gh) {
    int index = find_index_GH(gh);
    if (index != -1) {
      _gioHang[index].sl--;
      if (_gioHang[index].sl == 0) _gioHang.removeAt(index);
      _gioHang.refresh();
    }
  }

  void delSP(GioHangItem gh) {
    int index = find_index_GH(gh);
    if (index != -1) {
      _gioHang.removeAt(index);
      _gioHang.refresh();
    }
  }

  double tongThanhToan() {
    double s = 0;
    for (var x in _gioHang) {
      s += x.sl * x.mh.gia;
    }
    return s;
  }

  Future<void> xoahet() async {
    try {
      // Xóa giỏ hàng ở cơ sở dữ liệu
      final userId = SupabaseService.getCurrentUserId();
      if (userId != null) {
        await supabase
          .from('cart_items')
          .delete()
          .eq('user_id', userId);
      }
    } catch (e) {
      // Xử lý lỗi
    } finally {
      // Xóa giỏ hàng local
      _gioHang.clear();
      _gioHang.refresh();
    }
  }

  Future<bool> addGioHang(Product f) async {
    try {
      // Thêm vào giỏ hàng local
      int index = _gioHang.indexWhere((item) => item.mh.id == f.id);
      if (index == -1) {
        _gioHang.add(GioHangItem(mh: f, sl: 1));
      } else {
        _gioHang[index].sl++;
      }
      _gioHang.refresh();
      
      // Đồng bộ với cơ sở dữ liệu Supabase
      final result = await SupabaseService.addToCart(f.id, 1);
      
      return true;
    } catch (e) {
      // Vẫn trả về true để không ảnh hưởng đến trải nghiệm người dùng
      return true;
    }
  }

  Future<void> docDL() async {
    try {
      if (_selectedCategory.value == null) {
        var list = await ProductSnapshot.getAll2();
        _dssp.value = list.map((productSnap) => productSnap.product).toList();
      } else {
        var list = await ProductSnapshot.getByCategory2(_selectedCategory.value!);
        _dssp.value = list.map((productSnap) => productSnap.product).toList();
      }
      
      _dssp.refresh();
    } catch (e) {
      // Handle error silently
    }
  }
}

class FoodStoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ProductController());
  }
}

showMySnackBar(BuildContext context, String thongBao, int thoiGian) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(thongBao),
        duration: Duration(seconds: thoiGian),
      )
  );
} 