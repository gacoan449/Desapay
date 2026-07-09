import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/warna.dart';
import '../../widgets/kotak_saldo.dart'; 
import '../layanan/layanan_screen.dart';
import '../pulsa/pulsa_screen.dart';
import '../paket/paket_screen.dart';
import '../pln/pln_screen.dart';
import '../ewallet/ewallet_screen.dart';
import '../pascabayar_screen.dart';
import '../topup_saldo_screen.dart'; // Import halaman isi saldo Anda

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. FUNGSI PUSAT BANTUAN JALUR UTUH (ANTI-ERROR)
  Future<void> _bukaWhatsAppPusatBantuan() async {
    final String nomorWa = "6285642131263"; 
    final String teksPesan = Uri.encodeComponent("Halo CS DesaPay, saya butuh bantuan terkait kendala transaksi...");
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

  // 2. FUNGSI SIMULASI KAMERA SCAN QRIS DANA STYLE
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      
      // BAR ATAS DENGAN TOMBOL SCAN QRIS DAN LONCENG NOTIFIKASI
      appBar: AppBar(
        backgroundColor: WarnaDesaPay.primary,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'ChatGPT Image 8 Jul 2026, 22.03.40.png', 
              height: 35,
              errorBuilder: (_, __, ___) => const Icon(Icons.wallet, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text("DesaPay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
            onPressed: _bukaKameraQRIS, // Aktif membuka lembar scan kamera
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Dudukan Atas Biru untuk Kotak Saldo
            Stack(
              children: [
                Container(
                  height: 100, // Diperpanjang agar gradasi muat rapi
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: WarnaDesaPay.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                  child: Column(
                    children: [
                      KotakSaldo(),
                      const SizedBox(height: 10),
                      
                      // KELUHAN TERJAWAB: MEMUNCUKKAN TOMBOL TOP UP SALDO DISAMPING KOTAK
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TopupSaldoScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: WarnaDesaPay.primary, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  "ISI SALDO / TOP UP AGEN",
                                  style: TextStyle(color: WarnaDesaPay.primary, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // GRID MENU UTAMA 4x2 DANA STYLE
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
                    _menuItem(Icons.phone_android_rounded, "Pulsa", Colors.orange, const PulsaScreen()),
                    _menuItem(Icons.wifi_rounded, "Data", Colors.blue, const PaketScreen()),
                    _menuItem(Icons.flash_on_rounded, "Listrik", Colors.amber.shade600, const PlnScreen()),
                    _menuItem(Icons.account_balance_wallet_rounded, "E-Wallet", Colors.purple, const EwalletScreen()),
                    _menuItem(Icons.health_and_safety_rounded, "BPJS", Colors.teal, const PascabayarScreen(jenisLayanan: "BPJS")),
                    _menuItem(Icons.water_drop_rounded, "PDAM", Colors.lightBlue, const PascabayarScreen(jenisLayanan: "PDAM")),
                    _itemMenuLainnya(Icons.tv_rounded, "TV Kabel", Colors.redAccent, const PascabayarScreen(jenisLayanan: "TV KABEL")),
                    _itemMenuLainnya(Icons.grid_view_rounded, "Lainnya", Colors.grey.shade700, const LayananScreen()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // PUSAT BANTUAN WHATSAPP MEWAH (SUDAH DIPERBAIKI LINK UTUHNYA)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: _bukaWhatsAppPusatBantuan,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10)
                    ]
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.support_agent_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
