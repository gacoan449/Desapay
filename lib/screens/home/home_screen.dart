import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

// Import sesuai dengan struktur folder Anda yang Asli di screenshot
import '../../config/warna.dart';
import '../../services/saldo_service.dart';
import '../pulsa/pulsa_screen.dart';
import '../pln/pln_screen.dart';
import '../saldo/topup_saldo_screen.dart';
import '../pindai/pindai_qris_screen.dart';

// --- KUNCI DIBUKA: Mengimpor halaman lain untuk Bottom Navigation ---
import '../riwayat/riwayat_screen.dart';
import '../ewallet/ewallet_screen.dart';
import '../profil/profil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final SaldoService _saldoService = SaldoService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  bool _isSaldoHidden = false;
  int _currentIndex = 0;
  late PageController _pageController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // Data Banner Animasi
  final List<String> _promoBanners = [
    "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&q=80",
    "https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?w=500&q=80",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startBannerAnimation();
  }

  void _startBannerAnimation() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentBannerIndex < _promoBanners.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // PERBAIKAN: Fungsi WA agar lolos blokir Android 11+ dan GitHub Actions
  Future<void> _launchWA() async {
    const String phone = "6285642131263";
    const String message = "Halo Admin Desapay, saya butuh bantuan.";
    
    final Uri waUrl = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");

    try {
      if (!await launchUrl(waUrl, mode: LaunchMode.externalApplication)) {
        debugPrint('Tidak dapat meluncurkan WhatsApp');
      }
    } catch (e) {
      debugPrint("Error WA: $e");
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 1));
    setState(() {}); // Refresh UI
  }

  // --- MEMISAHKAN KONTEN BERANDA KE WIDGET TERSENDIRI ---
  Widget _buildHomeDashboard() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF0054A6),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // ==========================================
          // 1. HEADER & SALDO (DANA PREMIUM STYLE)
          // ==========================================
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0054A6),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0054A6), Color(0xFF0086FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profil Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.grey,
                                  backgroundImage: NetworkImage("https://i.pravatar.cc/100"), // Avatar user
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("DesaPay Premium", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text(_currentUser?.phoneNumber ?? "0856xxxxxx63", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(onPressed: _launchWA, icon: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 22)),
                              IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 25),
                      
                      // Informasi Saldo
                      const Text("Total Saldo", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      StreamBuilder<int>(
                        stream: _saldoService.streamSaldo(_currentUser?.uid ?? "demo"),
                        builder: (context, snapshot) {
                          int saldo = snapshot.data ?? 0;
                          return Row(
                            children: [
                              const Text("Rp ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(
                                _isSaldoHidden ? "••••••" : _formatRupiah(saldo),
                                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => setState(() => _isSaldoHidden = !_isSaldoHidden),
                                child: Icon(_isSaldoHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white70, size: 20),
                              )
                            ],
                          );
                        }
                      ),
                      
                      const SizedBox(height: 25),
                      // Quick Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickAction(Icons.add_circle_outline_rounded, "Isi Saldo", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopupSaldoScreen()))),
                          _buildQuickAction(Icons.arrow_downward_rounded, "Minta", () {}),
                          _buildQuickAction(Icons.send_rounded, "Kirim", () {}),
                          _buildQuickAction(Icons.qr_code_scanner_rounded, "Pindai", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PindaiQrisScreen()))),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ==========================================
          // 2. KONTEN UTAMA (PPOB, BANNER, FEED)
          // ==========================================
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xffF4F7FA),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Banner Promo Animasi Berjalan
                  SizedBox(
                    height: 140,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _promoBanners.length,
                      onPageChanged: (index) => setState(() => _currentBannerIndex = index),
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(image: NetworkImage(_promoBanners[index]), fit: BoxFit.cover),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grid Menu PPOB Lengkap
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPPOBItem(Icons.phone_android_rounded, "Pulsa & Data", const Color(0xFF0054A6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PulsaScreen()))),
                            _buildPPOBItem(Icons.bolt_rounded, "Listrik PLN", const Color(0xFFFFB300), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlnScreen()))),
                            _buildPPOBItem(Icons.water_drop_rounded, "PDAM Air", const Color(0xFF00C4FF), () {}),
                            _buildPPOBItem(Icons.health_and_safety_rounded, "BPJS", const Color(0xFF22C55E), () {}),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPPOBItem(Icons.tv_rounded, "TV Kabel", const Color(0xFF8338EC), () {}),
                            _buildPPOBItem(Icons.gamepad_rounded, "Voucher Game", const Color(0xFFE11D48), () {}),
                            _buildPPOBItem(Icons.wifi_rounded, "Internet", const Color(0xFF0EA5E9), () {}),
                            _buildPPOBItem(Icons.grid_view_rounded, "Lihat Semua", Colors.grey.shade700, () {}),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Feed Transaksi Ticker
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.campaign_rounded, color: Color(0xFF0054A6), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Feed: Transaksi PLN Token a/n Budi berhasil (Baru saja)",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // Section DesaPay Deals
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Promo Untung DesaPay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildDealsCard("Cashback Pulsa", "Diskon 10%", Colors.orange.shade400),
                        _buildDealsCard("Token Listrik Murah", "Potongan 5rb", Colors.blue.shade400),
                        _buildDealsCard("Voucher Game", "Bonus Kuota", Colors.purple.shade400),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Buffer bawah
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // --- KUNCI DIBUKA: Array Halaman untuk Bottom Navigation ---
    final List<Widget> bodyPages = [
      _buildHomeDashboard(),             // Index 0: Beranda PPOB
      const RiwayatScreen(),             // Index 1: Riwayat Transaksi
      const SizedBox.shrink(),           // Index 2: Kosong (Karena akan Push ke Layar Kamera Scanner)
      const EwalletScreen(),             // Index 3: Dompet / E-Wallet
      const ProfilScreen(),              // Index 4: Pengaturan Profil & Akses Logout
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      
      // Menampilkan halaman berdasarkan tab yang dipilih
      body: bodyPages[_currentIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF0054A6),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          // --- KUNCI DIBUKA: Logika Perpindahan Tab & Kamera ---
          if (index == 2) {
            // Jika klik tombol biru QRIS, langsung buka kamera Pindai
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PindaiQrisScreen()));
          } else {
            // Ubah tab tampilan layar
            setState(() => _currentIndex = index);
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Beranda"),
          const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: "Riwayat"),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFF0054A6), shape: BoxShape.circle),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
            ), 
            label: "Pay"
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: "Dompet"),
          const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profil"),
        ],
      ),
    );
  }

  // Komponen UI Internal agar tidak perlu pusing import file lain
  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPPOBItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsCard(String title, String subtitle, Color bgColor) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
