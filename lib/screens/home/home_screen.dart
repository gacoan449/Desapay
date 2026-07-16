import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/warna.dart';
import '../../screens/saldo/topup_saldo_screen.dart';
import '../../screens/riwayat/riwayat_screen.dart';
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
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
  
  final PageController _bannerController = PageController(initialPage: 0);
  int _currentBannerPage = 0;
  Timer? _bannerTimer;
  StreamSubscription? _saldoSubscription;

  @override
  void initState() {
    super.initState();
    _aktifkanListenerSaldoRealtime();
    
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentBannerPage < 2) {
        _currentBannerPage++;
      } else {
        _currentBannerPage = 0;
      }
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _aktifkanListenerSaldoRealtime() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _saldoSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots()
          .listen((DocumentSnapshot snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _saldoUserNyata = data['saldo'] ?? 0;
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
    _saldoSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bukaWhatsApp() async {
    const nomor = "6285642131263";
    final Uri url = Uri.https(
      'wa.me',
      '/$nomor',
      {'text': 'Halo CS DesaPay, saya mengalami kendala transaksi.'},
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal membuka WhatsApp. Pastikan aplikasi WA terinstall."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _kirimSaldoAction() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Icon(Icons.send_to_mobile_rounded, size: 72, color: WarnaDesaPay.primary),
              const SizedBox(height: 16),
              const Text(
                "Kirim Saldo DesaPay",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Fitur transfer saldo antar agen dan rekening bank sedang dalam pemeliharaan jaringan.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.slateGrey, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarnaDesaPay.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Baik, Dimengerti", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pindaiQrisAction() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PindaiQrisScreen()),
    );
  }

  void _notifikasi() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.mail_outline_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text("Kotak masuk Anda masih bersih!"),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: WarnaDesaPay.primary,
      ),
    );
  }

  String _formatRupiah(num nominal) {
    final int value = nominal.toInt();
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final LinearGradient premiumBlueGradient = LinearGradient(
      colors: [WarnaDesaPay.primary, const Color(0xFF0F172A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    Widget buildBodyContent() {
      if (_bottomNavIndex == 1) return const RiwayatScreen();
      if (_bottomNavIndex == 2) {
        return const Center(child: Text("Halaman Profil Manajemen Agen", style: TextStyle(fontWeight: FontWeight.bold)));
      }

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
                decoration: BoxDecoration(
                  gradient: premiumBlueGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40,
                        top: -20,
                        child: Opacity(
                          opacity: 0.08,
                          child: const Icon(Icons.blur_circular_rounded, size: 280, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 16,
                          bottom: 28,
                          left: 20,
                          right: 20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text("Saldo DesaPay", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () => setState(() => _isSaldoHidden = !_isSaldoHidden),
                                              child: Icon(_isSaldoHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16, color: Colors.white70),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _isSaldoHidden ? "Rp ••••••••" : "Rp ${_formatRupiah(_saldoUserNyata)}",
                                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withOpacity(0.15), width: 1)),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 14),
                                          SizedBox(width: 4),
                                          Text("DesaPay+", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.2)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: _notifikasi,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
                                            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                                          ),
                                          Positioned(
                                            right: 2,
                                            top: 2,
                                            child: Container(width: 9, height: 9, decoration: BoxDecoration(color: WarnaDesaPay.danger, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1E40AF), width: 1.5))),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _topActionItem(icon: Icons.add_rounded, label: "Isi Saldo", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopupSaldoScreen()))),
                                _topActionItem(icon: Icons.arrow_upward_rounded, label: "Kirim", onTap: _kirimSaldoAction),
                                _topActionItem(icon: Icons.qr_code_scanner_rounded, label: "Pindai", onTap: _pindaiQrisAction),
                                _topActionItem(icon: Icons.history_rounded, label: "Riwayat", onTap: () => setState(() => _bottomNavIndex = 1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16, spreadRadius: 2)]),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 22,
                    crossAxisSpacing: 4,
                    childAspectRatio: 0.88,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Promo Spesial Menarik", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        TextButton(onPressed: () {}, child: const Text("Lihat Semua", style: TextStyle(color: WarnaDesaPay.primary, fontWeight: FontWeight.bold)))
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      child: PageView(
                        controller: _bannerController,
                        onPageChanged: (index) => setState(() => _currentBannerPage = index),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildPremiumBanner([const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)], Icons.auto_awesome_rounded, "Festival Transaksi Kilat", "Dapatkan koin loyalitas ganda untuk setiap pengisian Pulsa di atas jam 9 malam."),
                          _buildPremiumBanner([const Color(0xFF8E2DE2), const Color(0xFF4A00E0)], Icons.bolt_rounded, "Token Listrik Hemat Rumah", "Tanpa biaya penanganan tambahan untuk semua golongan daya listrik."),
                        ],
                      ),
                    ),
                  ],
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
                        CircleAvatar(radius: 22, backgroundColor: Colors.white24, child: Icon(Icons.headset_mic_rounded, color: Colors.white, size: 24)),
                        SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Pusat Bantuan Digital", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), SizedBox(height: 4), Text("Hubungi tim teknis via WhatsApp jika ada kendala sistem pembayaran.", style: TextStyle(color: Colors.white, fontSize: 11))])),
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
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1), width: 1)),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMenu(IconData icon, String label, Color warna, Widget tujuan) {
    return CustomBounce(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => tujuan)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: warna.withOpacity(0.09), shape: BoxShape.circle), child: Icon(icon, color: warna, size: 26)),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(List<Color> gradientColors, IconData iconData, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 6), Text(description, maxLines: 2, style: const TextStyle(color: Colors.white70, fontSize: 11))])),
          const SizedBox(width: 12),
          Icon(iconData, size: 40, color: Colors.white24),
        ],
      ),
    );
  }
}
