import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_product_form_screen.dart';

class BelanjakuAdminProductsScreen extends StatelessWidget {
  const BelanjakuAdminProductsScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Produk Belanjaku')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BelanjakuAdminProductFormScreen())),
      icon: const Icon(Icons.add), label: const Text('Tambah Produk')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('belanjaku_products').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text('Katalog admin tidak dapat dibuka. Pastikan akun memiliki akses admin.'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Belum ada produk. Tekan Tambah Produk untuk memulai.'));
        return ListView.separated(padding: const EdgeInsets.all(12), itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = docs[i]; final d = doc.data();
            return Card(child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEAF3FF), child: Icon(Icons.inventory_2_outlined, color: Color(0xFF0866D9))),
              title: Text(d['name'] as String? ?? '(Tanpa nama)'),
              subtitle: Text('${d['category'] ?? 'Lainnya'} • Stok ${d['stock'] ?? 0} • ${d['status'] ?? 'coming_soon'}'),
              trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BelanjakuAdminProductFormScreen(productId: doc.id, initialData: d)))),
            ));
          });
      },
    ),
  );
}
