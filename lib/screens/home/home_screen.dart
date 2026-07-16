import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import standar internal framework DesaPay
import '../../config/warna.dart';
import '../../services/auth_service.dart';
import '../../services/saldo_service.dart';
import '../riwayat/riwayat_screen.dart';
import '../profil/profil_screen.dart';
import '../pindai/pindai_qris_screen.dart';
import '../saldo/topup_saldo_screen.dart';

// Import Custom Widgets asli bawaan project Anda
import '../../widgets/kotak_saldo.dart';
import '../../widgets/menu_item.dart';
import '../../widgets/banner_promo.dart';
import '../../widgets/promo_card.dart';

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
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
  int _bottomNavIndex = 0;
  num _saldoUserNyata = 0;
  String _namaUser = "Agen DesaPay";
  String _emailUser = "-";
  bool _isSaldoHidden = false;
  
  final PageController _bannerSliderController = PageController(initialPage: 0);
  int _currentPromoPage = 0;
  Timer? _sliderTimer;
  StreamSubscription? _userFirestoreSubscription;

  @override
  void initState() {
    super.initState();
    _aktifkanSinkronisasiAgenRealtime();
    _inisialisasiAutoSliderPromo();
  }

  void _aktifkanSinkronisasiAgenRealtime() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userFirestoreSubscription = FirebaseFirestore.instance
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
            });
          }
        }
      });
    }
  }

  void _inisialisasiAutoSliderPromo() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPromoPage < 1) {
        _currentPromoPage++;
      } else {
        _currentPromoPage = 0;
      }
      if (_bannerSliderController.hasClients) {
        _bannerSliderController.animateToPage(
          _currentPromoPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _bannerSliderController.dispose();
    _userFirestoreSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bukaLayananBantuanWA() async {
    const nomorCs = "6285642131263";
    final Uri url = Uri.https('wa.me', '/$nomorCs', {'text': 'Halo CS DesaPay, saya butuh bantuan teknis operasional agen.'});
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka WhatsApp. Silakan cek aplikasi WA Anda.")),
      );
    }
  }

  String _formatMataUangRupiah(num nominal) {
    return nominal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  Widget _buildContentDashboardMewah() {
    return RefreshIndicator(
      onRefresh: () async => _aktifkanSinkronisasiAgenRealtime(),
      color: WarnaDesaPay.primary,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // HEADER BACKGROUND GRADIENT & KOTAK SALDO
            // ==========================================
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [WarnaDesaPay.primary, Color(0xFF0C1938)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 32,
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
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
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
                                  _isSaldoHidden ? "Rp ••••••••" : "Rp ${_formatMataUangRupiah(_saldoUserNyata)}",
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
                          child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                        )
                      ],
                    ),
                    const SizedBox(height: 28),
                    
                    const KotakSaldo(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // CAROUSEL BANNER PROMO
            // ==========================================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Promo Spesial Menarik", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 140,
                child: PageView(
                  controller: _bannerSliderController,
                  onPageChanged: (index) => setState(() => _currentPromoPage = index),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF2C5364)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text("Serbuan Poin Agen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(height: 6), Text("Dapatkan komisi ganda tiap kelipatan transaksi PPOB di atas Rp100.000.", style: TextStyle(color: Colors.white70, fontSize: 11))])),
                          Icon(Icons.auto_awesome_rounded, size: 48, color: Colors.white24)
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text("Bebas Biaya Admin Token", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(height: 6), Text("Grosir token listrik prabayar termurah senusantara khusus mitra premium.", style: TextStyle(color: Colors.white70, fontSize: 11))])),
                          Icon(Icons.bolt_rounded, size: 48, color: Colors.white24)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPromoPage == index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPromoPage == index ? WarnaDesaPay.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // GRID LAYANAN UTAMA PPOB MITRA
            // ==========================================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Layanan Finansial Desa", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16, spreadRadius: 2)],
                ),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.85,
                  // KOREKSI 1: Menggunakan parameter 'icon' dan 'title' yang wajib ada sesuai instruksi compiler
                  children: const [
                    MenuItem(icon: Icons.phone_android_rounded, title: "Pulsa & Data"),
                    MenuItem(icon: Icons.flash_on_rounded, title: "Listrik PLN"),
                    MenuItem(icon: Icons.account_balance_wallet_rounded, title: "E-Wallet"),
                    MenuItem(icon: Icons.water_drop_rounded, title: "PDAM Air"),
                    MenuItem(icon: Icons.health_and_safety_rounded, title: "BPJS"),
                    MenuItem(icon: Icons.mosque_rounded, title: "Zakat Mall"),
                    MenuItem(icon: Icons.stars_rounded, title: "Desa Rewards"),
                    MenuItem(icon: Icons.grid_view_rounded, title: "Lihat Semua"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // BANNER STATIS / PROMO CARD BAWAH
            // ==========================================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              // KOREKSI 2: Menambahkan parameter wajib 'icon' bersama dengan 'title' dan 'subtitle'
              child: PromoCard(
                title: "Info Promo Terkini",
                subtitle: "Nikmati kemudahan transaksi harian bersama DesaPay",
                icon: Icons.campaign_rounded,
              ), 
            ),

            const SizedBox(height: 24),

            // ==========================================
            // PUSAT BANTUAN LAYANAN DIGITAL
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomBounce(
                onTap: _bukaLayananBantuanWA,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.green.shade700, Colors.teal.shade600]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(radius: 20, backgroundColor: Colors.white24, child: Icon(Icons.headset_mic_rounded, color: Colors.white, size: 22)),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Pusat Bantuan Digital via WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 2),
                            Text("Hubungi Customer Service jika ada kendala sistem", style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
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

  Widget _buildContentProfilMewah() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 3,
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
                        const SizedBox(height: 2),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.blue),
                  title: const Text("Keamanan Akun & PIN"),
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
    Widget aktifkanHalamanMenu() {
      switch (_bottomNavIndex) {
        case 1:
          return const RiwayatScreen();
        case 2:
          return _buildContentProfilMewah();
        default:
          return _buildContentDashboardMewah();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      body: aktifkanHalamanMenu(),
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
}
