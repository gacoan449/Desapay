import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/warna.dart';
import '../../screens/saldo/topup_saldo_screen.dart';
import '../pindai/pindai_qris_screen.dart'; 
import '../layanan/layanan_screen.dart';
import '../pulsa/pulsa_screen.dart';
import '../paket/paket_screen.dart';
import '../pln/pln_screen.dart';
import '../ewallet/ewallet_screen.dart';
import '../pascabayar_screen.dart';

class CustomBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const CustomBounce({super.key, required this.child, required this.onTap});

  @override
  State<CustomBounce> createState() => _CustomBounceState();
}

class _CustomBounceState extends State<CustomBounce> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap(); },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSaldoHidden = false;
  num _saldoUserNyata = 0;
  int _bottomNavIndex = 0;
  String _namaUser = "Agen DesaPay";
  String _emailUser = "-";
  String _phoneUser = "";
  
  final PageController _bannerController = PageController(initialPage: 0);
  int _currentBannerPage = 0;
  Timer? _bannerTimer;
  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();
    _aktifkanListenerUserRealtime();
    
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentBannerPage < 1) { _currentBannerPage++; } else { _currentBannerPage = 0; }
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(_currentBannerPage, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  void _aktifkanListenerUserRealtime() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots()
          .listen((DocumentSnapshot snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _saldoUserNyata = data['saldo'] ?? 0;
              _namaUser = data['nama'] ?? "Agen DesaPay";
              _emailUser = data['email'] ?? "-";
              _phoneUser = data['nomorHp'] ?? data['telepon'] ?? "";
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bukaWhatsApp() async {
    const nomor = "6285642131263";
    final Uri url = Uri.https('wa.me', '/$nomor', {'text': 'Halo CS DesaPay, saya mengalami kendala transaksi.'});
    try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka WhatsApp.")));
    }
  }

  void _pindaiQrisAction() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PindaiQrisScreen()));
  }

  String _formatRupiah(num nominal) {
    return nominal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  // RIB-1: Mengembalikan Halaman Riwayat Transaksi Rill dari Database Firestore
  Widget _buildRiwayatPage() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Silakan login terlebih dahulu"));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada riwayat transaksi rill"));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final tx = docs[index].data() as Map<String, dynamic>;
              final String tipe = tx['type'] ?? 'Transaksi';
              final num jumlah = tx['amount'] ?? 0;
              final String status = tx['status'] ?? 'PENDING';
              
              Color statusColor = WarnaDesaPay.warning;
              if (status == 'SUKSES' || status == 'SUCCESS') statusColor = Colors.green;
              if (status == 'GAGAL' || status == 'FAILED') statusColor = Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(tipe, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  trailing: Text("Rp ${_formatRupiah(jumlah)}", style: const TextStyle(fontWeight: FontWeight.black)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // RIB-2: Halaman Profil Rill dengan Sinkronisasi Data Firebase
  Widget _buildProfilPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(radius: 32, backgroundColor: WarnaDesaPay.primary.withOpacity(0.1), child: const Icon(Icons.person, size: 40, color: WarnaDesaPay.primary)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_namaUser, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(_emailUser, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.blue),
                  title: const Text("Keamanan Akun"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Keluar Aplikasi"),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget buildBodyContent() {
      if (_bottomNavIndex == 1) return _buildRiwayatPage();
      if (_bottomNavIndex == 2) return _buildProfilPage();

      // Dashboard Utama
      return RefreshIndicator(
        onRefresh: () async => _aktifkanListenerSaldoRealtime(),
        color: WarnaDesaPay.primary,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [WarnaDesaPay.primary, const Color(0xFF0F172A)], begin: Alignment.topCenter, end: Alignment.bottomCenter), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36))),
                child: Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 28, left: 20, right: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text("Saldo DesaPay", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 6),
                                      GestureDetector(onTap: () => setState(() => _isSaldoHidden = !_isSaldoHidden), child: Icon(_isSaldoHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16, color: Colors.white70)),
                                    ],
                                  ),
                                  Text(_isSaldoHidden ? "Rp ••••••••" : "Rp ${_formatRupiah(_saldoUserNyata)}", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                                ],
                              )
                            ],
                          ),
                          const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24)
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _topActionItem(icon: Icons.add_rounded, label: "Isi Saldo", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopupSaldoScreen()))),
                          _topActionItem(icon: Icons.arrow_upward_rounded, label: "Kirim", onTap: () {}),
                          _topActionItem(icon: Icons.qr_code_scanner_rounded, label: "Pindai", onTap: _pindaiQrisAction),
                          _topActionItem(icon: Icons.history_rounded, label: "Riwayat", onTap: () => setState(() => _bottomNavIndex = 1)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Menu Grid PPOB
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: GridView.count(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 4, mainAxisSpacing: 22, crossAxisSpacing: 4, childAspectRatio: 0.88,
                    children: [
                      _buildAnimatedMenu(Icons.phone_android_rounded, "Pulsa & Data", const Color(0xFFFF9F43), const PulsaScreen()),
                      _buildAnimatedMenu(Icons.flash_on_rounded, "Listrik PLN", const Color(0xfff1c40f), const PlnScreen()),
                      _buildAnimatedMenu(Icons.account_balance_wallet_rounded, "E-Wallet", const Color(0xff6c5ce7), const EwalletScreen()),
                      _buildAnimatedMenu(Icons.water_drop_rounded, "PDAM Air", const Color(0xff00cec9), const PascabayarScreen(jenisLayanan: "PDAM")),
                      _buildAnimatedMenu(Icons.health_and_safety_rounded, "BPJS Kesehatan", const Color(0xff00b894), const PascabayarScreen(jenisLayanan: "BPJS")),
                      _buildAnimatedMenu(Icons.mosque_rounded, "Zakat Mall", const Color(0xffe17055), const LayananScreen()),
                      _buildAnimatedMenu(Icons.stars_rounded, "Desa Rewards", const Color(0xff0984e3), const LayananScreen()),
                      _buildAnimatedMenu(Icons.grid_view_rounded, "Lihat Semua", const Color(0xff636e72), const LayananScreen()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomBounce(
                  onTap: _bukaWhatsApp,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade700, Colors.teal.shade600]), borderRadius: BorderRadius.circular(24)),
                    child: const Row(
                      children: [
                        Icon(Icons.headset_mic_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text("Pusat Bantuan Digital via WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      body: buildBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        selectedItemColor: WarnaDesaPay.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profil"),
        ],
      ),
    );
  }

  Widget _topActionItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return CustomBounce(
      onTap: onTap,
      child: Column(
        children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: Colors.white, size: 28)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildAnimatedMenu(IconData icon, String label, Color warna, Widget tujuan) {
    return CustomBounce(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => tujuan)),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: warna.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: warna)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }
}
