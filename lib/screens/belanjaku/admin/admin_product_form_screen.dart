import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BelanjakuAdminProductFormScreen extends StatefulWidget {
  const BelanjakuAdminProductFormScreen({super.key, this.productId, this.initialData});
  final String? productId;
  final Map<String, dynamic>? initialData;
  @override State<BelanjakuAdminProductFormScreen> createState() => _BelanjakuAdminProductFormScreenState();
}
class _BelanjakuAdminProductFormScreenState extends State<BelanjakuAdminProductFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name, description, imageUrl, price, unit, stock;
  String category = 'Sayuran & Buah', status = 'coming_soon';
  bool active = true, saving = false, uploading = false;
  File? selectedImage;
  static const categories = ['Sayuran & Buah','Frozen Food','Sembako','Daging & Ayam','Minuman','Snack','Perlengkapan Rumah Tangga','Lainnya'];
  @override void initState() {
    super.initState();
    final d = widget.initialData ?? <String, dynamic>{};
    name = TextEditingController(text: d['name'] as String? ?? '');
    description = TextEditingController(text: d['description'] as String? ?? '');
    imageUrl = TextEditingController(text: d['imageUrl'] as String? ?? '');
    price = TextEditingController(text: d['price']?.toString() ?? '0');
    unit = TextEditingController(text: d['unit'] as String? ?? 'pcs');
    stock = TextEditingController(text: d['stock']?.toString() ?? '0');
    if (categories.contains(d['category'])) category = d['category'] as String;
    if (['available','coming_soon','out_of_stock'].contains(d['status'])) status = d['status'] as String;
    active = d['isActive'] != false;
  }
  @override void dispose() { name.dispose(); description.dispose(); imageUrl.dispose(); price.dispose(); unit.dispose(); stock.dispose(); super.dispose(); }

  Future<void> chooseImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
      if (picked != null && mounted) setState(() => selectedImage = File(picked.path));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto tidak dapat dipilih: $e'))); }
  }
  Future<void> uploadImage(String productId) async {
    if (selectedImage == null) return;
    setState(() => uploading = true);
    try {
      final ref = FirebaseStorage.instance.ref().child('belanjaku/products/$productId/main.jpg');
      final task = await ref.putFile(selectedImage!, SettableMetadata(contentType: 'image/jpeg'));
      imageUrl.text = await task.ref.getDownloadURL();
    } finally { if (mounted) setState(() => uploading = false); }
  }
  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final p = int.parse(price.text.trim()), s = int.parse(stock.text.trim());
      final doc = widget.productId == null ? FirebaseFirestore.instance.collection('belanjaku_products').doc() : FirebaseFirestore.instance.collection('belanjaku_products').doc(widget.productId);
      if (selectedImage != null) await uploadImage(doc.id);
      await doc.set({
        'name': name.text.trim(), 'description': description.text.trim(), 'imageUrl': imageUrl.text.trim(),
        'price': p, 'unit': unit.text.trim(), 'stock': s, 'category': category,
        'status': status == 'available' && s == 0 ? 'out_of_stock' : status,
        'isActive': active, 'updatedAt': FieldValue.serverTimestamp(),
        if (widget.productId == null) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk gagal disimpan: $e')));
    } finally { if (mounted) setState(() => saving = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.productId == null ? 'Tambah Produk' : 'Edit Produk')),
    body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nama produk'), validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Kategori'), items: categories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setState(() => category = v); }),
      const SizedBox(height: 12),
      TextFormField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi')),
      const SizedBox(height: 12),
      if (selectedImage != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(selectedImage!, height: 180, fit: BoxFit.cover))
      else if (imageUrl.text.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl.text, height: 180, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 80, child: Icon(Icons.broken_image_outlined)))),
      OutlinedButton.icon(onPressed: uploading ? null : chooseImage, icon: const Icon(Icons.photo_library_outlined), label: Text(uploading ? 'Mengunggah foto...' : 'Pilih / Ganti Foto Produk')),
      const SizedBox(height: 8),
      TextFormField(controller: imageUrl, decoration: const InputDecoration(labelText: 'URL foto (opsional, jika tidak upload)')),
      const SizedBox(height: 12),
      TextFormField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga (rupiah)'), validator: (v) { final n = int.tryParse(v ?? ''); return n == null || n < 0 ? 'Masukkan harga valid' : null; }),
      const SizedBox(height: 12),
      TextFormField(controller: unit, decoration: const InputDecoration(labelText: 'Satuan (ikat/kg/pack)'), validator: (v) => v == null || v.trim().isEmpty ? 'Satuan wajib diisi' : null),
      const SizedBox(height: 12),
      TextFormField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok'), validator: (v) { final n = int.tryParse(v ?? ''); return n == null || n < 0 ? 'Stok harus 0 atau lebih' : null; }),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Status'), items: const [
        DropdownMenuItem(value: 'coming_soon', child: Text('Segera Hadir')),
        DropdownMenuItem(value: 'available', child: Text('Tersedia')),
        DropdownMenuItem(value: 'out_of_stock', child: Text('Stok Habis')),
      ], onChanged: (v) { if (v != null) setState(() => status = v); }),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: active, onChanged: (v) => setState(() => active = v), title: const Text('Tampilkan di katalog')),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: saving || uploading ? null : save, child: Text(saving ? 'Menyimpan...' : 'Simpan Produk')),
    ])),
  );
}
