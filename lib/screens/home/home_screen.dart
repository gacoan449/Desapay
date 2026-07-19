import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

// Import Konfigurasi & Service Inti
import '../../config/warna.dart';
import '../../services/saldo_service.dart';

// Import Layar Moduler
import '../pulsa/pulsa_screen.dart' hide CustomBounce;
import '../pln/pln_screen.dart' hide CustomBounce;
import '../saldo/topup_saldo_screen.dart' hide CustomBounce;
import '../pindai/pindai_qris_screen.dart' hide CustomBounce;

// Import Layar Sapu Jagat PPOB
import '../ppob/ppob_generic_screen.dart' hide CustomBounce;
import '../ppob/semua_layanan_screen.dart' hide CustomBounce;

// Import Re-usable Premium Widgets
import '../../widgets/menu_item.dart';
import '../../widgets/promo_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ISaldoService _saldoService = SaldoService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  bool _isSaldoHidden = false;
  late PageController _pageController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  final List<String> _promoBanners = [
    "https://images.unsplash.com/photo-1612036781124-847f8939b154?w=800&q=80",
    "https://images.unsplash.com/photo-1605810230434-7631ac76ec81?w=800&q=80",
    "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800&q=80",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startBannerAnimation();
  }

  void _startBannerAnimation() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_currentBannerIndex < _promoBanners.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
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

  Future<void> _launchWA() async {
    const String phone = "6285642131263";
    const String message = "Halo CS DesaPay, saya butuh bantuan terkait transaksi.";
    final Uri waUrl = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
    try {
      if (!await launchUrl(waUrl, mode: LaunchMode.externalApplication)) {
        debugPrint('Bypass: Aplikasi WA tidak ditemukan.');
      }
    } catch (e) {
      debugPrint("Error WA Intent: $e");
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() {}); 
  }

  void _bukaLayananGenerik(String namaLayanan) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => PpobGenericScreen(kategori: namaLayanan))
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold di sini sekarang murni hanya untuk konten (tidak ada bottomNavigationBar lagi)
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: WarnaDesaPay.primary,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: 310, 
              pinned: true,
              elevation: 0,
              backgroundColor: WarnaDesaPay.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [WarnaDesaPay.primary, const Color(0xFF1E40AF), WarnaDesaPay.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                  child: const CircleAvatar(
                                    radius: 20,
                                    backgroundColor: WarnaDesaPay.primary,
                                    child: Icon(Icons.person_rounded, size: 24, color: Colors.white), 
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("DesaPay Premium", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                                    Text(_currentUser?.phoneNumber ?? "Akun Terverifikasi", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                CustomBounce(
                                  onTap: _launchWA, 
                                  child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                CustomBounce(
                                  onTap: (){}, 
                                  child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
                                ),
                              ],
                            )
                          ],
                        ),
                        
                        const Spacer(),
                        
                        Text("Total Saldo Anda", style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        StreamBuilder<int>(
                          stream: _saldoService.streamSaldo(_currentUser?.uid ?? "demo_uid"),
                          builder: (context, snapshot) {
                            final int saldo = snapshot.data ?? 0;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text("Rp ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _isSaldoHidden ? "••••••" : _formatRupiah(saldo),
                                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CustomBounce(
                                  onTap: () => setState(() => _isSaldoHidden = !_isSaldoHidden),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                                    child: Icon(_isSaldoHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white, size: 20),
                                  ),
                                )
                              ],
                            );
                          }
                        ),
                        
                        const SizedBox(height: 28),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildHeaderAction(Icons.add_circle_rounded, "Isi Saldo", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopupSaldoScreen()))),
                            _buildHeaderAction(Icons.arrow_circle_down_rounded, "Minta", () => _bukaLayananGenerik("Terima Dana")),
                            _buildHeaderAction(Icons.send_rounded, "Kirim", () => _bukaLayananGenerik("Transfer Bank")),
                            _buildHeaderAction(Icons.qr_code_scanner_rounded, "Pindai", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PindaiQrisScreen()))),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: WarnaDesaPay.lightBg,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 150,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _promoBanners.length,
                        onPageChanged: (index) => setState(() => _currentBannerIndex = index),
                        itemBuilder: (context, index) {
                          return CustomBounce(
                            onTap: () {},
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(image: NetworkImage(_promoBanners[index]), fit: BoxFit.cover),
                                boxShadow: [
                                  BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 8))
                                ]
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 12,
                        padding: EdgeInsets.zero,
                        children: [
                          MenuItem(icon: Icons.phone_android_rounded, title: "Pulsa", badgeColor: const Color(0xFFEFF6FF), iconColor: WarnaDesaPay.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PulsaScreen()))),
                          MenuItem(icon: Icons.bolt_rounded, title: "PLN Listrik", badgeColor: const Color(0xFFFFFBEB), iconColor: const Color(0xFFD97706), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlnScreen()))),
                          MenuItem(icon: Icons.account_balance_wallet_rounded, title: "E-Wallet", badgeColor: const Color(0xFFF5F3FF), iconColor: const Color(0xFF7C3AED), onTap: () => _bukaLayananGenerik("Topup E-Wallet / E-Toll")),
                          MenuItem(icon: Icons.sports_esports_rounded, title: "Game", badgeColor: const Color(0xFFFFF1F2), iconColor: const Color(0xFFE11D48), onTap: () => _bukaLayananGenerik("Voucher Game")),
                          MenuItem(icon: Icons.water_drop_rounded, title: "PDAM Air", badgeColor: const Color(0xFFECFEFF), iconColor: WarnaDesaPay.secondary, onTap: () => _bukaLayananGenerik("PDAM Nasional")),
                          MenuItem(icon: Icons.health_and_safety_rounded, title: "BPJS", badgeColor: const Color(0xFFF0FDF4), iconColor: const Color(0xFF16A34A), onTap: () => _bukaLayananGenerik("BPJS Kesehatan")),
                          MenuItem(icon: Icons.tv_rounded, title: "Internet & TV", badgeColor: const Color(0xFFFAF5FF), iconColor: const Color(0xFF9333EA), onTap: () => _bukaLayananGenerik("Internet & TV Cable")),
                          MenuItem(icon: Icons.local_fire_department_rounded, title: "Gas PGN", badgeColor: const Color(0xFFFFF7ED), iconColor: const Color(0xFFEA580C), onTap: () => _bukaLayananGenerik("Gas PGN")),
                          MenuItem(icon: Icons.receipt_long_rounded, title: "Angsuran", badgeColor: const Color(0xFFF1F5F9), iconColor: const Color(0xFF475569), onTap: () => _bukaLayananGenerik("Angsuran Kredit")),
                          MenuItem(icon: Icons.account_balance_rounded, title: "Pajak PBB", badgeColor: const Color(0xFFF0FDF4), iconColor: const Color(0xFF059669), onTap: () => _bukaLayananGenerik("Pajak PBB")),
                          MenuItem(icon: Icons.directions_bus_rounded, title: "Tiket", badgeColor: const Color(0xFFFEF2F2), iconColor: const Color(0xFFDC2626), onTap: () => _bukaLayananGenerik("Tiket Perjalanan")),
                          MenuItem(icon: Icons.grid_view_rounded, title: "Semua", badgeColor: WarnaDesaPay.lightField, iconColor: WarnaDesaPay.textSub, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SemuaLayananScreen()))),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: WarnaDesaPay.lightField, width: 1.5),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.campaign_rounded, color: WarnaDesaPay.primary, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Feed: Transaksi E-Toll a/n Budi berhasil",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WarnaDesaPay.textMain),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("Promo Untung DesaPay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: WarnaDesaPay.textMain, letterSpacing: 0.2)),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 20, right: 4),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          PromoCard(
                            title: "Cashback Pulsa", subtitle: "Diskon s/d 10% Hari Ini", 
                            icon: Icons.percent_rounded, color: const Color(0xFFF59E0B), onTap: () {}
                          ),
                          PromoCard(
                            title: "Token Hemat", subtitle: "Potongan admin Rp 2.500", 
                            icon: Icons.bolt_rounded, color: WarnaDesaPay.primary, onTap: () {}
                          ),
                          PromoCard(
                            title: "Voucher Game", subtitle: "Bonus kuota melimpah", 
                            icon: Icons.gamepad_rounded, color: const Color(0xFF9333EA), onTap: () {}
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120), // Memberi ruang ekstra agar tidak tertutup nav bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, String label, VoidCallback onTap) {
    return CustomBounce(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1), 
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            label, 
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3)
          ),
        ],
      ),
    );
  }
}
