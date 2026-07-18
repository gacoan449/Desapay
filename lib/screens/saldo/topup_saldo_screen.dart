import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import Konfigurasi, Layanan, dan Widget Modular (CTO Standard)
import '../../config/warna.dart';
import '../../services/tripay_service.dart';
import '../../widgets/menu_item.dart'; // Menggunakan CustomBounce pusat
import '../saldo/invoice_screen.dart';

/// Halaman Top Up Saldo Akun Agen DesaPay
class TopupSaldoScreen extends StatefulWidget {
  const TopupSaldoScreen({super.key});

  @override
  State<TopupSaldoScreen> createState() => _TopupSaldoScreenState();
}

class _TopupSaldoScreenState extends State<TopupSaldoScreen> {
  final TextEditingController _nominalController = TextEditingController();
  bool _isLoading = false;

  // Daftar Pilihan Cepat Pengisian Saldo
  final List<int> _pilihanNominal = [20000, 50000, 100000, 250000, 500000, 1000000];

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  /// Memproses pembuatan tagihan QRIS via TriPay
  void _eksekusiMintaTiketTriPay() async {
    // Menghilangkan format titik jika ada, lalu parsing
    final String teksNominal = _nominalController.text.replaceAll('.', '');
    final int nominal = int.tryParse(teksNominal) ?? 0;

    if (nominal < 10000) {
      _tampilkanNotifikasi("Minimal pengisian saldo adalah Rp 10.000", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final User? currentUser = FirebaseAuth.instance.currentUser;
    String namaUser = "Agen DesaPay";
    String emailUser = "agen@desapay.id";
    String teleponUser = "080000000000";

    // Mengambil data terkini pengguna dari Firestore untuk detail tagihan
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          namaUser = data['nama'] ?? namaUser;
          emailUser = data['email'] ?? emailUser;
          teleponUser = data['nomorHp'] ?? data['telepon'] ?? teleponUser;
        }
      } catch (e) {
        debugPrint("Gagal mengambil data user: $e");
      }
    }

    // Eksekusi API TriPay
    final responseData = await TriPayService().buatTagihanClosedPayment(
      method: 'QRIS', 
      amount: nominal,
      namaPelanggan: namaUser,
      emailPelanggan: emailUser,
      nomorHpPelanggan: teleponUser,
      namaProduk: 'Top Up Saldo Akun DesaPay',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (responseData != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => InvoiceScreen(tripayData: responseData)),
      );
    } else {
      _tampilkanNotifikasi("Gagal membuat tagihan. Periksa koneksi data internet/kredensial API.", isError: true);
    }
  }

  /// Helper untuk merubah teks input menjadi format mata uang
  void _setNominalPilihan(int nominal) {
    setState(() {
      _nominalController.text = _formatAngka(nominal);
    });
  }

  String _formatAngka(int angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(angka);
  }

  void _tampilkanNotifikasi(String pesan, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isError ? WarnaDesaPay.danger : WarnaDesaPay.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Isi Saldo",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. KOTAK INPUT NOMINAL
            // ==========================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: WarnaDesaPay.lightCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nominal Pengisian", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: WarnaDesaPay.textMain)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nominalController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: WarnaDesaPay.textMain),
                    decoration: InputDecoration(
                      prefixText: "Rp ",
                      prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: WarnaDesaPay.textMain),
                      hintText: "0",
                      hintStyle: TextStyle(color: WarnaDesaPay.textSub.withOpacity(0.5)),
                      filled: true,
                      fillColor: WarnaDesaPay.lightField,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    onChanged: (value) {
                      // Membersihkan input dari huruf/titik manual agar murni angka
                      String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (cleanValue.isNotEmpty) {
                        int parsed = int.parse(cleanValue);
                        _nominalController.value = TextEditingValue(
                          text: _formatAngka(parsed),
                          selection: TextSelection.collapsed(offset: _formatAngka(parsed).length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Minimal pengisian saldo adalah Rp 10.000",
                    style: TextStyle(fontSize: 12, color: WarnaDesaPay.textSub, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ==========================================
            // 2. GRID PILIHAN CEPAT (QUICK SELECT)
            // ==========================================
            const Text(
              "Pilih Nominal Cepat",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: WarnaDesaPay.textMain),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: _pilihanNominal.length,
              itemBuilder: (context, index) {
                final int nominal = _pilihanNominal[index];
                return CustomBounce(
                  onTap: () => _setNominalPilihan(nominal),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WarnaDesaPay.primary.withOpacity(0.3), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Rp ${_formatAngka(nominal)}",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: WarnaDesaPay.primary),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 48),

            // ==========================================
            // 3. TOMBOL PROSES (CUSTOM BOUNCE)
            // ==========================================
            CustomBounce(
              onTap: _isLoading ? () {} : _eksekusiMintaTiketTriPay,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey.shade400 : WarnaDesaPay.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isLoading 
                    ? [] 
                    : [
                        BoxShadow(
                          color: WarnaDesaPay.primary.withOpacity(0.24),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                ),
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        "LANJUTKAN PEMBAYARAN",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.6),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
