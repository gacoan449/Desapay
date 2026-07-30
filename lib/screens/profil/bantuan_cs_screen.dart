import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/warna.dart';

class BantuanCsScreen extends StatefulWidget {
  const BantuanCsScreen({super.key});

  @override
  State<BantuanCsScreen> createState() => _BantuanCsScreenState();
}

class _BantuanCsScreenState extends State<BantuanCsScreen> {
  final TextEditingController _pesanController = TextEditingController();
  bool _isLoading = false;

  Future<void> _kirimTiket() async {
    if (_pesanController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection("keluhan_pelanggan").add({
        "namaUser": user?.displayName ?? "Pengguna DesaPay",
        "phoneUser": user?.phoneNumber ?? user?.email ?? "-",
        "pesan": _pesanController.text.trim(),
        "status": "Pending", // Status masuk ke dashboard admin
        "waktuMasuk": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _pesanController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pesan terkirim ke Admin. Mohon tunggu balasan.", style: TextStyle(color: Colors.white)), backgroundColor: WarnaDesaPay.success));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mengirim: $e", style: const TextStyle(color: Colors.white)), backgroundColor: WarnaDesaPay.danger));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(title: const Text("Pusat Bantuan CS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), backgroundColor: WarnaDesaPay.primary, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ada kendala transaksi?", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: WarnaDesaPay.textMain)),
            const SizedBox(height: 8),
            const Text("Tuliskan detail masalah Anda. Tim CS kami akan segera mengeceknya ke sistem.", style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 13)),
            const SizedBox(height: 24),
            TextField(
              controller: _pesanController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Contoh: Saldo pulsa saya belum masuk padahal sudah terpotong Rp 50.000",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: WarnaDesaPay.lightField)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: WarnaDesaPay.primary)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: WarnaDesaPay.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: _isLoading ? null : _kirimTiket,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("KIRIM KE ADMIN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
