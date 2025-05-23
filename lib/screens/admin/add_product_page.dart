import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  XFile? xFile;
  TextEditingController txtTen = TextEditingController();
  TextEditingController txtGia = TextEditingController();
  TextEditingController txtMota = TextEditingController();
  TextEditingController txtStock = TextEditingController();
  String selectedCategory = 'FOOD';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thêm SP"),
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
                    ? const Icon(Icons.image, size: 50) 
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
                      if (xFile != null) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Đang thêm ${txtTen.text}..."),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                        
                        // Upload image
                        String? imageUrl;
                        try {
                          final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}.jpg';
                          await Supabase.instance.client.storage
                              .from('images')
                              .upload(fileName, File(xFile!.path));
                          imageUrl = Supabase.instance.client.storage
                              .from('images')
                              .getPublicUrl(fileName);
                        } catch (e) {
                          throw Exception('Upload failed');
                        }
                        
                        // Add product
                        final productData = {
                          'ten': txtTen.text,
                          'gia': int.parse(txtGia.text),
                          'mota': txtMota.text,
                          'image': imageUrl,
                          'category': selectedCategory,
                          'stock': int.parse(txtStock.text),
                        };
                        
                        await SupabaseService.addProduct(productData);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Đã thêm ${txtTen.text}"),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text("Thêm"),
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
} 