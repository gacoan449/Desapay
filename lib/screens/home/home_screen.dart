import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/warna.dart';

// IMPORT JALUR SEARAH: Lolos validasi kompilasi server otomatis GitHub Actions
import '../../widgets/kotak_saldo.dart'; 
import '../layanan/layanan_screen.dart';
import '../pulsa/pulsa_screen.dart';
import '../paket/paket_screen.dart';
import '../pln/pln_screen.dart';
import '../ewallet/ewallet_screen.dart';
import '../pascabayar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // Fungsi Launcher WhatsApp Jalur Aman Tanpa Mengubah Android Manifest
  Future<void> _bukaWhatsAppPusatBantuan() async {
    final String nomorWa = "6285642131263"; 
    final String teksPesan = Uri.encodeComponent("Halo CS DesaPay, saya butuh bantuan terkait transaksi...");
    // Menggunakan URL web universal api.whatsapp agar kompatibel dan aman dari pemblokiran
    final Uri urlAman = Uri.parse("https://whatsapp.com");

    try {
      await launchUrl(urlAman, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membuka WhatsApp: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Fungsi Simulasi Pindai QRIS Mewah ala DANA
  void _bukaKameraQRIS() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 20),
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text("PINDAI QRIS DESAPAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Spacer(),
            // Kotak Bidik Kamera QRIS
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade400, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_scanner_rounded, size: 100, color: Colors.white24),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Arahkan kamera ke kode QRIS DesaPay", style: TextStyle(color: Colors.white70)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.grey.shade900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(icon: const Icon(Icons.flash_off, color: Colors.white), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.image, color: Colors.white), onPressed: () {}),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC), // Latar belakang abu cerah khas dompet digital
      
      // 1. APPBAR ATAS MEWAH ALA DANA
      appBar: AppBar(
        backgroundColor: WarnaDesaPay.primary,
        elevation: 0,
        title: Row(
          children: [
            // MEMANGGIL LOGO BARU: Menggunakan nama file ChatGPT yang pas sesuai pubspec.yaml Anda
            Image.asset(
              'ChatGPT Image 8 Jul 2026, 22.03.40.png',
              height: 35,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.wallet, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 8),
            const Text("DesaPay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
            onPressed: _bukaKameraQRIS,
            tooltip: "Pindai QRIS",
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Belum ada notifikasi baru hari ini.")),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Biru Atas & Dudukan Kotak Saldo
            Stack(
              children: [
                Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: WarnaDesaPay.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                  child: KotakSaldo(), // Memanggil komponen saldo otomatis kita
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. GRID MENU UTAMA 4x2 INTERAKTIF DAN MENARIK ALA DANA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.06), spreadRadius: 3, blurRadius: 15)
                  ]
                ),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                  children: [
                    _itemMenuDana(Icons.phone_android_rounded, "Pulsa", Colors.orange, const PulsaScreen()),
                    _itemMenuDana(Icons.wifi_rounded, "Data", Colors.blue, const PaketScreen()),
                    _itemMenuDana(Icons.flash_on_rounded, "Listrik PLN", Colors.amber.shade600, const PlnScreen()),
                    _itemMenuDana(Icons.account_balance_wallet_rounded, "E-Wallet", Colors.purple, const EwalletScreen()),
                    _itemMenuDana(Icons.health_and_safety_rounded, "BPJS", Colors.teal, const PascabayarScreen(jenisLayanan: "BPJS")),
                    _itemMenuDana(Icons.water_drop_rounded, "PDAM", Colors.lightBlue, const PascabayarScreen(jenisLayanan: "PDAM")),
                    _itemMenuDana(Icons.tv_rounded, "TV Kabel", Colors.redAccent, const PascabayarScreen(jenisLayanan: "TV KABEL")),
                    _itemMenuDana(Icons.grid_view_rounded, "Lihat Semua", Colors.grey.shade700, const LayananScreen()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. SPANDUK PUSAT BANTUAN WHATSAPP MEWAH & MENARIK (KLIK LANGSUNG TEMBAK)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: _bukaWhatsAppPusatBantuan,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.emerald.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.green.withOpacity(0.2), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Pusat Bantuan DesaPay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text("Ada kendala transaksi? Hubungi CS WhatsApp kami 24 Jam nonstop.", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, height: 1.4)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                    ],
