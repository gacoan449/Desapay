import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/tripay_service.dart';
import '../saldo/invoice_screen.dart';

class TopupSaldoScreen extends StatefulWidget {
  const TopupSaldoScreen({super.key});

  @override
  State<TopupSaldoScreen> createState() => _TopupSaldoScreenState();
}

class _TopupSaldoScreenState extends State<TopupSaldoScreen> {
  final TextEditingController _nominalController = TextEditingController();
  bool _isLoading = false;

  void _eksekusiMintaTiketTriPay() async {
    final int nominal = int.tryParse(_nominalController.text) ?? 0;
    if (nominal < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal pengisian saldo adalah Rp 10.000")),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final User? currentUser = FirebaseAuth.instance.currentUser;
    String namaUser = "Agen DesaPay";
    String emailUser = "agen@desapay.id";
    String teleponUser = "085642131263";

    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        namaUser = data['nama'] ?? namaUser;
        emailUser = data['email'] ?? emailUser;
        teleponUser = data['nomorHp'] ?? data['telepon'] ?? teleponUser;
      }
    }

    final responseData = await TriPayService().buatTagihanClosedPayment(
      method: 'QRIS', 
      amount: nominal,
      namaPelanggan: namaUser,
      emailPelanggan: emailUser,
      nomorHpPelanggan: teleponUser,
      namaProduk: 'Top Up Saldo Akun Mandiri Agen',
    );

    setState(() { _isLoading = false; });

    if (responseData != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => InvoiceScreen(tripayData: responseData)),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal membuat tagihan. Periksa koneksi data internet/kredensial API.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Isi Saldo Akun")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Masukkan Nominal Pengisian (Rp)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _eksekusiMintaTiketTriPay,
                child: _isLoading ? const CircularProgressIndicator() : const Text("Konfirmasi & Bayar via TriPay"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
