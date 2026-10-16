import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class CourierManagementScreen extends StatefulWidget {
  const CourierManagementScreen({super.key});

  @override
  State<CourierManagementScreen> createState() => _CourierManagementScreenState();
}

class _CourierManagementScreenState extends State<CourierManagementScreen> {
  final _search = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _setCourier(String uid, bool makeCourier, List<String> areas) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await FirebaseFunctions.instanceFor(region: 'asia-southeast2')
          .httpsCallable('belanjakuAdminSetCourierRole')
          .call({'uid': uid, 'makeCourier': makeCourier, 'serviceAreaIds': areas});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(makeCourier ? 'Role kurir diaktifkan.' : 'Role dikembalikan menjadi pembeli.'),
        ));
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Perubahan role gagal.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan. Coba lagi.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kurir')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari nama, email, atau UID',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Aktifkan hanya akun yang sudah diverifikasi. Masukkan ID wilayah layanan yang sesuai dengan data area Belanjaku.'),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return const Center(child: Text('Daftar pengguna tidak dapat dimuat.'));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs.where((doc) {
                final d = doc.data();
                if ((d['role'] ?? 'user') == 'admin') return false;
                final haystack = '${d['nama'] ?? d['name'] ?? ''} ${d['email'] ?? ''} ${doc.id}'.toLowerCase();
                return query.isEmpty || haystack.contains(query);
              }).toList();
              if (docs.isEmpty) return const Center(child: Text('Pengguna tidak ditemukan.'));
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final doc = docs[i], d = doc.data();
                  final isCourier = d['role'] == 'courier';
                  final areas = (d['serviceAreaIds'] as List<dynamic>? ?? []).whereType<String>().toList();
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    child: ListTile(
                      title: Text((d['nama'] ?? d['name'] ?? 'Tanpa nama').toString()),
                      subtitle: Text('${d['email'] ?? doc.id}\nRole: ${d['role'] ?? 'user'} • Wilayah: ${areas.join(', ')}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: isCourier ? 'Nonaktifkan role kurir' : 'Aktifkan sebagai kurir',
                        onPressed: _busy ? null : () async {
                          List<String> selected = areas;
                          if (!isCourier) {
                            final controller = TextEditingController(text: areas.join(', '));
                            final value = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Wilayah layanan kurir'),
                                content: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(hintText: 'area_id_1, area_id_2'),
                                  maxLines: 2,
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Simpan')),
                                ],
                              ),
                            );
                            if (value == null) return;
                            selected = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
                            if (selected.isEmpty) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimal satu ID wilayah harus diisi.')));
                              return;
                            }
                          } else {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Nonaktifkan role kurir?'),
                                content: const Text('Akun akan dikembalikan ke role pembeli. Periksa tugas aktif terlebih dahulu.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lanjutkan')),
                                ],
                              ),
                            );
                            if (confirm != true) return;
                          }
                          await _setCourier(doc.id, !isCourier, selected);
                        },
                        icon: Icon(isCourier ? Icons.person_remove_alt_1 : Icons.delivery_dining),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
