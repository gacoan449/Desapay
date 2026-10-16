import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BelanjakuAdminRegionsScreen extends StatefulWidget {
  const BelanjakuAdminRegionsScreen({super.key});
  @override State<BelanjakuAdminRegionsScreen> createState() => _BelanjakuAdminRegionsScreenState();
}
class _BelanjakuAdminRegionsScreenState extends State<BelanjakuAdminRegionsScreen> {
  Future<void> addArea() async {
    final name = TextEditingController(); final subdistrict = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Tambah Wilayah'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: subdistrict, decoration: const InputDecoration(labelText: 'Kecamatan')),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Desa/Kelurahan')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan'))],
    ));
    if (ok == true && name.text.trim().isNotEmpty && subdistrict.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('belanjaku_delivery_areas').add({
        'name': name.text.trim(), 'subdistrict': subdistrict.text.trim(),
        'isActive': true, 'createdAt': FieldValue.serverTimestamp(),
      });
    }
    name.dispose(); subdistrict.dispose();
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Wilayah Layanan')),
    floatingActionButton: FloatingActionButton.extended(onPressed: addArea, icon: const Icon(Icons.add_location_alt_outlined), label: const Text('Tambah Wilayah')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('belanjaku_delivery_areas').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text('Wilayah tidak dapat dimuat. Pastikan akun admin memiliki akses.'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) return const Center(child: Text('Belum ada wilayah. Tambahkan wilayah yang akan diuji.'));
        return ListView(children: snap.data!.docs.map((doc) {
          final d = doc.data(); final active = d['isActive'] != false;
          return SwitchListTile(
            value: active, title: Text(d['name'] as String? ?? 'Wilayah'),
            subtitle: Text(d['subdistrict'] as String? ?? ''),
            onChanged: (value) => doc.reference.update({'isActive': value}),
          );
        }).toList());
      },
    ),
  );
}
