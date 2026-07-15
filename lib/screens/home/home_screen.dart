import 'dart:async';
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
import '../saldo/topup_saldo_screen.dart';

// ==========================================
// 1. CUSTOM BOUNCE ANIMATION WIDGET
// ==========================================
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
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
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

// ==========================================
// MAIN SCREEN WINDOWS
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSaldoHidden = false;
  final PageController _bannerController = PageController(initialPage: 0);
  int _currentBannerPage = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    // Sistem Autoscroll Pintar untuk Banner Canggih
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

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
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

  void _qrisBelumAktif() {
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
              Icon(Icons.qr_code_scanner_rounded, size: 72, color: WarnaDesaPay.primary),
              const SizedBox(height: 16),
              const Text(
                "QRIS Merchant DesaPay",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Fitur internal QRIS sedang dalam tahap sinkronisasi data merchant reguler. Kami akan segera mengaktifkannya untuk Anda.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
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
                  child: const Text("Paham, Terima Kasih", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _notifikasi() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 10),
            Text("Kotak masuk Anda masih bersih."),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: WarnaDesaPay.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gradasi Biru Mewah Kiblat Aplikasi DANA
    final LinearGradient premiumBlueGradient = LinearGradient(
      colors: [
        WarnaDesaPay.primary,
        const Color(0xFF007BE6),
        const Color(0xFF0086FF),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
        color: WarnaDesaPay.primary,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 2. PREMIUM BLUE HEADER LAYOUT (DANA STYLE)
              // ==========================================
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: premiumBlueGradient,
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 24,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  children: [
                    // TOP BAR: SALDO UTAMA & TOMBOL SIDE ACTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            // INTEGRASI TOGGLE SALDO DI TOP BAR
                            GestureDetector(
                              onTap: () => setState(() => _isSaldoHidden = !_isSaldoHidden),
                              child: Row(
                                children: [
                                  _isSaldoHidden
                                      ? const Text("Rp ••••••", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                                      : const DefaultTextStyle(
                                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                          child: KotakSaldo(),
                                        ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _isSaldoHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // RIGHT BADGE PLATFORM
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "DesaPay+",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // TRANSPARENT WHITE ACTION BUTTONS GRID ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _topActionItem(Icons.add_box_rounded, "Isi Saldo", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TopupSaldoScreen()));
                        }),
                        _topActionItem(Icons.arrow_upward_rounded, "Kirim", _qrisBelumAktif),
                        _topActionItem(Icons.qr_code_scanner_rounded, "Pindai", _qrisBelumAktif),
                        _topActionItem(Icons.history_rounded, "Riwayat", () {}),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // GRID MENU UTAMA PPOB WITH CUSTOM BOUNCE EFFECT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
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

              // ANIMATED PROMO CAROUSEL (CANGGIH & MANDIRI TANPA BORDER TEXT EXTRA)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Promo Spesial Menarik", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        TextButton(onPressed: () {}, child: Text("Lihat Semua", style: TextStyle(color: WarnaDesaPay.primary, fontWeight: FontWeight.bold)))
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
                          _buildPremiumBanner(
                            [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)],
                            Icons.auto_awesome_rounded,
                            "Festival Transaksi Kilat",
                            "Dapatkan koin loyalitas ganda untuk setiap pengisian Pulsa & Paket Data di atas jam 9 malam.",
                          ),
                          _buildPremiumBanner(
                            [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
                            Icons.bolt_rounded,
                            "Token Listrik Hemat Rumah",
                            "Tanpa biaya penanganan tambahan untuk semua golongan daya listrik pascabayar.",
                          ),
                          _buildPremiumBanner(
                            [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                            Icons.volunteer_activism_rounded,
                            "Pemberdayaan Desa Mandiri",
                            "Salurkan Zakat dan Infak Anda secara aman dan real-time langsung ke program desa binaan.",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Indikator Titik Banner Carousel
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentBannerPage == index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentBannerPage == index ? WarnaDesaPay.primary : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // PLATFORM ASSISTANCE CARD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomBounce(
                  onTap: _bukaWhatsApp,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.emerald.shade700, Colors.teal.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.emerald.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.headset_mic_rounded, color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pusat Bantuan Digital",
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Hubungi tim teknis via WhatsApp jika ada kendala pemrosesan sistem pembayaran Anda.",
                                style: TextStyle(color: Colors.whiteAA, fontSize: 11, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // SECURED FOOTER CERTIFICATE
              Center(
                child: Column(
                  children: [
                    Icon(Icons.verified_user_rounded, size: 30, color: WarnaDesaPay.primary.withOpacity(0.2)),
                    const SizedBox(height: 8),
                    Text(
                      "Secured Network Infrastructure Protocol",
                      style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "© 2026 DesaPay Indonesia • Premium Release Build v2.1.0",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topActionItem(IconData icon, String label, VoidCallback onTap) {
    return CustomBounce(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedMenu(IconData icon, String label, Color warna, Widget tujuan) {
    return CustomBounce(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => tujuan)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: warna.withOpacity(0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: warna, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(List<Color> gradientColors, IconData iconData, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.3),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(iconData, size: 48, color: Colors.white.withOpacity(0.15)),
        ],
      ),
    );
  }
}
