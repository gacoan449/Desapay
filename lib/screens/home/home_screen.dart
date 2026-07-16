import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Untuk WhatsApp
import 'package:flutter_animate/flutter_animate.dart'; // Untuk Animasi Mewah

// Import existing modules
import '../../config/warna.dart';
import '../../services/saldo_service.dart';
import '../pulsa/pulsa_screen.dart';
import '../../screens/pascabayar/pascabayar_screen.dart';
import '../saldo/topup_saldo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SaldoService _saldoService = SaldoService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  bool _isSaldoHidden = false;
  int _currentIndex = 0; // Untuk Bottom Navigation

  // Method WhatsApp
  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse("https://wa.me/6285642131263?text=Halo%20Admin%20Desapay,%20saya%20membutuhkan%20bantuan.");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9FAFB),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        // 1. HEADER PREMIUM (DANA STYLE)
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: WarnaDesaPay.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeaderContent(),
          ),
        ),
        
        // 2. MAIN GRID MENU
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildCoreServices(),
              _buildBantuanBanner(), // Menu Bantuan WA
              _buildDealsSection(),
            ],
          ),
        ),
      ],
    );
  }

  // Header Content
  Widget _buildHeaderContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0054A6), Color(0xFF007BE6)]),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
                  const SizedBox(width: 10),
                  Text("Hi, Agen Desapay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(onPressed: (){}, icon: const Icon(Icons.qr_code_scanner, color: Colors.white))
            ],
          ),
          const SizedBox(height: 20),
          // Balance Display
          Row(
            children: [
              Text("Rp", style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(width: 5),
              Text(_isSaldoHidden ? "••••••" : "2.500.000", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              IconButton(onPressed: ()=>setState(()=> _isSaldoHidden = !_isSaldoHidden), icon: Icon(_isSaldoHidden ? Icons.visibility_off : Icons.visibility, color: Colors.white70, size: 18))
            ],
          )
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // Grid Services
  Widget _buildCoreServices() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        children: [
          _menuItem(Icons.phone_android, "Pulsa", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PulsaScreen()))),
          _menuItem(Icons.bolt, "PLN", () {}),
          _menuItem(Icons.water_drop, "PDAM", () {}),
          _menuItem(Icons.health_and_safety, "BPJS", () {}),
          _menuItem(Icons.tv, "TV Kabel", () {}),
          _menuItem(Icons.flight, "Tiket", () {}),
          _menuItem(Icons.gamepad, "Games", () {}),
          _menuItem(Icons.more_horiz, "Lainnya", () {}),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 800.ms);
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: WarnaDesaPay.primary, size: 30),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  // Bantuan Button (WA)
  Widget _buildBantuanBanner() {
    return GestureDetector(
      onTap: _launchWhatsApp,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green.shade200)
        ),
        child: Row(
          children: [
            const Icon(Icons.whatsapp, color: Colors.green, size: 30),
            const SizedBox(width: 15),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Butuh Bantuan?", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Klik disini untuk chat admin via WA", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Bottom Nav
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "Aktivitas"),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Dompet"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Saya"),
      ],
    );
  }

  Widget _buildDealsSection() {
    return Container(height: 100, color: Colors.transparent); // Placeholder
  }
}
