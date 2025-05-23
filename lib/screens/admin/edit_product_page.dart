import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> product;
  
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  XFile? xFile;
  String? imageUrl;
  TextEditingController txtId = TextEditingController();
  TextEditingController txtTen = TextEditingController();
  TextEditingController txtGia = TextEditingController();
  TextEditingController txtMota = TextEditingController();
  TextEditingController txtStock = TextEditingController();
  String selectedCategory = 'FOOD';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cập Nhật"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            children: [
              Container(
                height: 300,
                child: xFile == null 
                    ? Image.network(widget.product['image'] ?? "https://via.placeholder.com/150")
                    : Image.file(File(xFile!.path)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      var imagePicker = await ImagePicker().pickImage(
                        source: ImageSource.gallery
                      );
                      if (imagePicker != null) {
                        setState(() {
                          xFile = imagePicker;
                        });
                      }
                    },
                    child: const Text("Chọn ảnh")
                  ),
                  const SizedBox(width: 15),
                ],
              ),
              TextField(
                readOnly: true,
                controller: txtId,
                decoration: const InputDecoration(labelText: "Id"),
              ),
              TextField(
                controller: txtTen,
                decoration: const InputDecoration(labelText: "Tên"),
              ),
              TextField(
                controller: txtGia,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Giá"),
              ),
              TextField(
                controller: txtStock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Tồn kho"),
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: const [
                  DropdownMenuItem(value: 'FOOD', child: Text('Đồ ăn')),
                  DropdownMenuItem(value: 'DRINK', child: Text('Nước uống')),
                  DropdownMenuItem(value: 'SNACK', child: Text('Bánh kẹo')),
                ],
                onChanged: (value) => setState(() => selectedCategory = value!),
                decoration: const InputDecoration(labelText: 'Danh mục'),
              ),
              TextField(
                controller: txtMota,
                decoration: const InputDecoration(labelText: "Mô tả"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Đang cập nhật ${txtTen.text}..."),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                      
                      String? newImageUrl = widget.product['image'];
                      if (xFile != null) {
                        try {
                          final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}.jpg';
                          await Supabase.instance.client.storage
                              .from('images')
                              .upload(fileName, File(xFile!.path));
                          newImageUrl = Supabase.instance.client.storage
                              .from('images')
                              .getPublicUrl(fileName);
                        } catch (e) {
                          throw Exception('Upload failed');
                        }
                      }
                      
                      final productData = {
                        'ten': txtTen.text,
                        'gia': int.parse(txtGia.text),
                        'mota': txtMota.text,
                        'image': newImageUrl,
                        'category': selectedCategory,
                        'stock': int.parse(txtStock.text),
                      };
                      
                      await SupabaseService.updateProduct(widget.product['id'], productData);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Đã cập nhật ${txtTen.text}"),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                      Navigator.pop(context, true);
                    },
                    child: const Text("Cập nhật"),
                  ),
                  const SizedBox(width: 15)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    txtId.text = widget.product['id'].toString();
    txtTen.text = widget.product['ten'];
    txtGia.text = widget.product['gia'].toString();
    txtMota.text = widget.product['mota'] ?? "";
    txtStock.text = widget.product['stock']?.toString() ?? "0";
    selectedCategory = widget.product['category'] ?? 'FOOD';
  }
} 