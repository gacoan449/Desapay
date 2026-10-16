import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class BelanjakuCourierHomeScreen extends StatelessWidget {
  const BelanjakuCourierHomeScreen({super.key});

  Future<void> _act(BuildContext context, String orderId, String action, {bool codCollected = false}) async {
    try {
      await FirebaseFunctions.instanceFor(region: 'asia-southeast2')
          .httpsCallable('belanjakuCourierUpdateOrder')
          .call({'orderId': orderId, 'action': action, 'codCollected': codCollected});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status pesanan berhasil diperbarui.')));
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Status gagal diperbarui.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan. Silakan coba lagi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Silakan login kembali.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda Kurir Belanjaku')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('belanjaku_orders').where('courierUid', isEqualTo: user.uid).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Pesanan tidak dapat dimuat. Pastikan indeks Firestore tersedia.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.where((d) => !['COMPLETED', 'CANCELLED'].contains(d.data()['status'])).toList()
            ..sort((a, b) => (b.data()['createdAt'] as Timestamp?)?.compareTo((a.data()['createdAt'] as Timestamp?) ?? Timestamp(0, 0)) ?? 0);
          if (docs.isEmpty) return const Center(child: Text('Belum ada tugas pengantaran.'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i], d = doc.data();
              final status = d['status'] as String? ?? 'ASSIGNED';
              final payment = d['paymentMethod'] as String? ?? 'COD';
              String? action;
              String label = '';
              if (status == 'ASSIGNED') { action = 'ACCEPT'; label = 'Terima tugas'; }
              if (status == 'ACCEPTED') { action = 'PICK_UP'; label = 'Barang sudah diambil'; }
              if (status == 'PICKED_UP') { action = 'START_DELIVERY'; label = 'Mulai antar'; }
              if (status == 'ON_DELIVERY') { action = 'DELIVER'; label = payment == 'COD' ? 'Selesaikan & konfirmasi COD' : 'Konfirmasi barang diterima'; }
              final items = (d['items'] as List<dynamic>? ?? []).map((e) {
                final m = Map<String, dynamic>.from(e as Map);
                return '${m['name'] ?? 'Produk'} × ${m['quantity'] ?? 1}';
              }).join(', ');
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pesanan #${doc.id}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Status: $status • ${payment == 'COD' ? 'COD' : 'Saldo DesaPay'}'),
                    Text('Penerima: ${d['customerName'] ?? '-'} • ${d['phone'] ?? '-'}'),
                    Text('Alamat: ${d['areaName'] ?? ''}, ${d['address'] ?? '-'}'),
                    Text('Barang: $items'),
                    Text('Total: Rp ${d['total'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (action != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: ElevatedButton(
                        onPressed: () async {
                          var collected = false;
                          if (action == 'DELIVER' && payment == 'COD') {
                            final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                              title: const Text('Konfirmasi uang COD'),
                              content: Text('Pastikan uang Rp ${d['total'] ?? 0} benar-benar diterima dari pembeli.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Belum diterima')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Uang diterima')),
                              ],
                            ));
                            if (confirm != true) return;
                            collected = true;
                          }
                          await _act(context, doc.id, action!, codCollected: collected);
                        },
                        child: Text(label),
                      )),
                    ],
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
