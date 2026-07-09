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
      backgroundColor: const Color(0xFFF5F9FC), 
      
      // 1. APPBAR UTAMA
      appBar: AppBar(
        backgroundColor: WarnaDesaPay.primary,
        elevation: 0,
        title: Row(
          children: [
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
            // Dudukan Atas Kotak Saldo
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
                  child: KotakSaldo(), 
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. GRID MENU UTAMA 4x2 INTERAKTIF (KODE MELEBUR TANPA FUNGSI LUAR)
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
                    // --- MENU PULSA ---
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PulsaScreen())),
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.09), shape: BoxShape.circle),
                            child: const Icon(Icons.phone_android_rounded, color: Colors.orange, size: 26),
                          ),
                          const SizedBox(height: 8),
                          const Text("Pulsa", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87))
                        ],
                      ),
                    ),

                    // --- MENU DATA ---
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaketScreen())),
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.09), shape: BoxShape.circle),
                            child: const Icon(Icons.wifi_rounded, color: Colors.blue, size: 26),
                          ),
                          const SizedBox(height: 8),
                          const Text("Data", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87))
                        ],
                      ),
                    ),

                    // --- MENU LISTRIK PLN ---
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlnScreen())),
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.09), shape: BoxShape.circle),
                            child: Icon(Icons.flash_on_rounded, color: Colors.amber.shade600, size: 26),
                          ),
                          const SizedBox(height: 8),
                          const Text("Listrik PLN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87))
                        ],
                      ),
                    ),

                    // --- MENU E-WALLET ---
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EwalletScreen())),
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
