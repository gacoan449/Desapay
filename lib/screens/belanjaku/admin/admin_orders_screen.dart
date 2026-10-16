import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BelanjakuAdminOrdersScreen extends StatelessWidget {
  const BelanjakuAdminOrdersScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pesanan Belanjaku')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('belanjaku_orders').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text('Pesanan tidak dapat dimuat. Akun admin diperlukan.'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) return const Center(child: Text('Belum ada pesanan. Checkout masih belum diaktifkan.'));
        return ListView.builder(itemCount: snap.data!.docs.length, itemBuilder: (context, i) {
          final d = snap.data!.docs[i]; final data = d.data();
          return ListTile(
            leading: const Icon(Icons.receipt_long, color: Color(0xFF0866D9)),
            title: Text('Pesanan #${d.id}'),
            subtitle: Text('${data['status'] ?? 'Menunggu'} • ${data['itemCount'] ?? 0} item'),
            trailing: Text('Rp ${data['total'] ?? 0}'),
          );
        });
      },
    ),
  );
}
