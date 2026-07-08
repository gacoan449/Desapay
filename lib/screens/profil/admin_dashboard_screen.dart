import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/warna.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  final promoController = TextEditingController();
  final bannerController = TextEditingController();
  
  // Controller untuk tambah/edit menu layanan
  final namaMenuController = TextEditingController();
  final ikonController = TextEditingController();
  bool loading = false;

  Future<void> simpanPerubahan() async {
    if (promoController.text.trim().isEmpty || bannerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua kolom pengaturan wajib diisi")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await _firestore.collection("pengaturan").doc("aplikasi").set({
        "teksPromo": promoController.text.trim(),
        "teksBanner": bannerController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pengaturan DesaPay berhasil diperbarui!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan data: $e")),
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> tambahMenuLayanan() async {
    if (namaMenuController.text.trim().isEmpty || ikonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama menu dan kode ikon wajib diisi")),
      );
      return;
    }

    try {
      String idMenu = namaMenuController.text.trim().toLowerCase().replaceAll(' ', '_');
      await _firestore.collection("menu_layanan").doc(idMenu).set({
        "id": idMenu,
        "nama": namaMenuController.text.trim(),
        "ikon": ikonController.text.trim(), // Contoh: phone_android, flash_on, game_controller
        "isAktif": true,
        "urutan": 1,
      });

      if (!mounted) return;
      namaMenuController.clear();
      ikonController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menu layanan baru berhasil ditambahkan!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menambah menu: $e")),
      );
    }
  }

  void tampilkanDialogTambahMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Menu Layanan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaMenuController,
              decoration: const InputDecoration(
                labelText: "Nama Menu (Contoh: Pulsa, BPJS, PLN)",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ikonController,
              decoration: const InputDecoration(
                labelText: "Kode Ikon (Contoh: phone, flash, game)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: tambahMenuLayanan,
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    promoController.dispose();
    bannerController.dispose();
    namaMenuController.dispose();
    ikonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: const Text("Dashboard Admin"),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pengaturan Tampilan Aplikasi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: bannerController,
              decoration: InputDecoration(
                labelText: "Teks Banner Informasi Saldo",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: promoController,
              decoration: InputDecoration(
                labelText: "Teks Promo Hari Ini",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 15),
            
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
                onPressed: loading ? null : simpanPerubahan,
                child: const Text("SIMPAN TEXT PROMO & BANNER", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(thickness: 1),
            ),

            const Text(
              "Manajemen Grid Menu Layanan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_box),
                label: const Text("TAMBAH MENU BARUsecara Live"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                onPressed: tampilkanDialogTambahMenu,
              ),
            ),
            const SizedBox(height: 15),

            // Menampilkan daftar menu aktif yang bisa di-nonaktifkan langsung lewat tombol saklar (Switch)
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection("menu_layanan").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final item = docs[index].data() as Map<String, dynamic>;
                    bool isAktif = item["isAktif"] ?? false;
                    return Card(
                      child: ListTile(
                        title: Text(item["nama"] ?? "-"),
                        subtitle: Text("ID: ${item["id"]}"),
                        trailing: Switch(
                          value: isAktif,
                          onChanged: (val) {
                            _firestore.collection("menu_layanan").doc(item["id"]).update({
                              "isAktif": val,
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
