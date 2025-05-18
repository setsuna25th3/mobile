class NguoiNhan {
  final String id;
  final String ten;
  final String soDienThoai;
  final String diaChi;
  final String? ghiChu;
  
  NguoiNhan({
    required this.id,
    required this.ten,
    required this.soDienThoai,
    required this.diaChi,
    this.ghiChu,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
      'soDienThoai': soDienThoai,
      'diaChi': diaChi,
      'ghiChu': ghiChu,
    };
  }
  
  factory NguoiNhan.fromJson(Map<String, dynamic> map) {
    return NguoiNhan(
      id: map['id'] as String,
      ten: map['ten'] as String,
      soDienThoai: map['soDienThoai'] as String,
      diaChi: map['diaChi'] as String,
      ghiChu: map['ghiChu'] as String?,
    );
  }
}

class ThongTinNguoiNhan {
  final String tenNguoiNhan;
  final String diaChi;
  final String soDienThoai;
  
  ThongTinNguoiNhan({
    required this.tenNguoiNhan,
    required this.diaChi,
    required this.soDienThoai,
  });
  
  Future<void> luuThongTinNguoiNhan() async {
    // Lưu thông tin người nhận vào Supabase hoặc local storage
  }
} 