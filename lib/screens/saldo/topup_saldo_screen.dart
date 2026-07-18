import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import Konfigurasi, Layanan, dan Widget Modular
import '../../config/warna.dart';
import '../../services/tripay_service.dart';
import '../../widgets/menu_item.dart';
import '../pembayaran/metode_pembayaran_screen.dart'; // Import halaman pilihan metode
import '../saldo/invoice_screen.dart';

class TopupSaldoScreen extends StatefulWidget {
  const TopupSaldoScreen({super.key});

  @override
  State<TopupSaldoScreen> createState() => _TopupSaldoScreenState();
}

class _TopupSaldoScreenState extends State<TopupSaldoScreen> {
  final TextEditingController _nominalController = TextEditingController();
  bool _isLoading = false;

  final List<int> _pilihanNominal = [20000, 50000, 100000, 250000, 500000, 1000000];

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  /// 1. Navigasi ke pemilihan metode, 2. Jika terpilih, baru eksekusi tiket
  Future<void> _lanjutkanKePembayaran() async {
    final String teksNominal = _nominalController.text.replaceAll('.', '');
    final int nominal = int.tryParse(teksNominal) ?? 0;

    if (nominal < 10000) {
      _tampilkanNotifikasi("Minimal pengisian saldo adalah Rp 10.000", isError: true);
      return;
    }

    // Arahkan ke pemilihan metode pembayaran
    final String? channelCode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MetodePembayaranScreen(nominal: teksNominal),
      ),
    );

    // Jika user memilih metode (tidak batal), langsung eksekusi tiket
    if (channelCode != null) {
      _eksekusiMintaTiketTriPay(nominal, channelCode);
    }
  }

  /// Eksekusi API TriPay dengan metode yang dipilih
  void _eksekusiMintaTiketTriPay(int nominal, String methodCode) async {
    setState(() => _isLoading = true);

    final User? currentUser = FirebaseAuth.instance.currentUser;
    String namaUser = "Agen DesaPay";
    String emailUser = "agen@desapay.id";
    String teleponUser = "080000000000";

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

    final responseData = await TriPayService().buatTagihanClosedPayment(
      method: methodCode, // Menggunakan metode yang dipilih dari MetodePembayaranScreen
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
      _tampilkanNotifikasi("Gagal membuat tagihan. Periksa kredensial API.", isError: true);
    }
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
    // ... (Bagian build UI sama persis dengan sebelumnya)
    // Cukup ubah bagian tombol CustomBounce saja:
    
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Isi Saldo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3)),
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
            // (Isi Container Input Nominal dan Grid Nominal tetap sama)
            // ... (Kode UI yang sudah ada)

            // Tombol di bawah diubah targetnya:
            CustomBounce(
              onTap: _isLoading ? () {} : _lanjutkanKePembayaran,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey.shade400 : WarnaDesaPay.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isLoading ? [] : [
                    BoxShadow(color: WarnaDesaPay.primary.withOpacity(0.24), blurRadius: 14, offset: const Offset(0, 6)),
                  ],
                ),
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text("PILIH METODE PEMBAYARAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
