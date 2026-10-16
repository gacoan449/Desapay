import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class BelanjakuAdminOrdersScreen extends StatelessWidget {
  const BelanjakuAdminOrdersScreen({super.key});

  Future<void> _process(BuildContext context, String id, String action) async {
    try {
      await FirebaseFunctions.instanceFor(region: 'asia-southeast2')
          .httpsCallable('belanjakuAdminProcessOrder')
          .call({'orderId': id, 'action': action});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tindakan pesanan berhasil diproses.')));
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Tindakan gagal.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan. Coba lagi.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pesanan Belanjaku')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('belanjaku_orders').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text('Pesanan tidak dapat dimuat. Pastikan akun admin memiliki akses.'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs.toList()
          ..sort((a, b) => ((b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0)
              .compareTo((a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0));
        if (docs.isEmpty) return const Center(child: Text('Belum ada pesanan Belanjaku.'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i], d = doc.data();
            final status = d['status'] as String? ?? 'NEW';
            final method = d['paymentMethod'] as String? ?? 'COD';
            final actions = <Widget>[];
            if (status == 'NEW') actions.add(OutlinedButton(onPressed: () => _process(context, doc.id, 'CONFIRM'), child: const Text('Konfirmasi')));
            if (status == 'CONFIRMED') actions.add(ElevatedButton(onPressed: () => _process(context, doc.id, 'ASSIGN_AUTO'), child: const Text('Pilih kurir otomatis')));
            if (['NEW', 'CONFIRMED', 'ASSIGNED', 'ACCEPTED'].contains(status)) {
              actions.add(TextButton(onPressed: () async {
                final reason = await showDialog<String>(context: context, builder: (ctx) {
                  final controller = TextEditingController(text: 'Dibatalkan admin');
                  return AlertDialog(title: const Text('Batalkan pesanan'), content: TextField(controller: controller, maxLength: 300, decoration: const InputDecoration(labelText: 'Alasan')),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kembali')), ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Batalkan'))]);
                });
                if (reason != null) await _process(context, doc.id, 'CANCEL');
              }, child: const Text('Batalkan')));
            }
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pesanan #${doc.id}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text('Status: $status • Pembayaran: ${method == 'COD' ? 'COD' : 'Saldo DesaPay'} • ${d['paymentStatus'] ?? 'UNPAID'}'),
                  Text('Total: Rp ${d['total'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('Penerima: ${d['customerName'] ?? '-'} • ${d['phone'] ?? '-'}'),
                  Text('Alamat: ${d['areaName'] ?? ''}, ${d['address'] ?? '-'}'),
                  Text('Kurir: ${d['courierUid'] ?? 'Belum ditugaskan'}'),
                  Text('Item: ${d['itemCount'] ?? 0}'),
                  if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 4, children: actions),
                ]),
              ),
            );
          },
        );
      },
    ),
  );
}
