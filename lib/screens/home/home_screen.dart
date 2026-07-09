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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Fungsi Hubungi Pusat Bantuan Jalur Aman Universal
  Future<void> _bukaWhatsApp() async {
    final Uri url = Uri.parse("https://whatsapp.com...");
    try { await launchUrl(url, mode: LaunchMode.platformDefault); } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        backgroundColor: WarnaDesaPay.primary,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('ChatGPT Image 8 Jul 2026, 22.03.40.png', height: 35,
              errorBuilder: (_, __, ___) => const Icon(Icons.wallet, color: Colors.white)),
            const SizedBox(width: 8),
            const Text("DesaPay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Blue Header & Dudukan Kotak Saldo
            Stack(
              children: [
                Container(height: 60, decoration: BoxDecoration(color: WarnaDesaPay.primary,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: KotakSaldo()),
              ],
            ),
            const SizedBox(height: 20),

            // GRID MENU 4x2 INTERAKTIF ALA DANA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), spreadRadius: 3, blurRadius: 15)]),
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
                    _menuItem(Icons.tv_rounded, "TV Kabel", Colors.redAccent, const PascabayarScreen(jenisLayanan: "TV KABEL")),
                    _menuItem(Icons.grid_view_rounded, "Lainnya", Colors.grey.shade700, const LayananScreen()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // PUSAT BANTUAN WHATSAPP MEWAH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: _bukaWhatsApp,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade600, Colors.green.shade400]),
                    borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10)]),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.white.withOpacity(0.2), child: const Icon(Icons.support_agent_rounded, color: Colors.white)),
                      const SizedBox(width: 16),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("Pusat Bantuan DesaPay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text("Ada kendala transaksi? Hubungi CS WhatsApp kami 24 Jam nonstop.", style: TextStyle(color: Colors.whiteBB, fontSize: 11)),
                      ])),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // FOOTER IDENTITAS BRAND RESMI
            Column(
              children: [
                Icon(Icons.widgets_outlined, size: 35, color: WarnaDesaPay.primary.withOpacity(0.3)),
                const SizedBox(height: 6),
                Text("Aplikasi Keagenan Modern Nusantara", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                Text("© 2026 DesaPay Indonesia • Rilis Sukses", style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Fungsi Pembantu Ringkas Pembuat Tombol Menu Grid
  Widget _menuItem(IconData icon, String label, Color warna, Widget tujuan) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => tujuan)),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: warna.withOpacity(0.09), shape: BoxShape.circle),
            child: Icon(icon, color: warna, size: 26)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)
        ],
      ),
    );
  }
}
