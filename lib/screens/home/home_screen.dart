import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Sinkronisasi mutlak dengan arsitektur folder modular DesaPay Anda
import '../../config/warna.dart';
import '../../services/saldo_service.dart';
import '../../services/digiflazz_service.dart';
import '../pulsa/pulsa_screen.dart';
import '../pascabayar/pascabayar_screen.dart';
import '../saldo/topup_saldo_screen.dart';

// =========================================================================
// PREMIUM CUSTOM BOUNCE COMPONENT (MICRO-INTERACTION FOR GRID & BUTTONS)
// =========================================================================
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
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
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

// =========================================================================
// MAIN HOMESCREEN PLATFORM
// =========================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SaldoService _saldoService = SaldoService();
  final DigiflazzService _digiflazzService = DigiflazzService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  bool _isSaldoHidden = false;
  int _currentIndexBanner = 0;
  late PageController _pageController;
  Timer? _bannerTimer;

  // Data Mock Promo & Feed Ticker Sesuai Dokumen Gambar DANA
  final List<Map<String, String>> _promoBanners = [
    {
      "image": "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&q=80",
      "title": "FESTIVAL BOLA DUNIA DESAPAY",
      "desc": "Kumpulin Poin & Tukerin Hadiah Miliaran Rupiah!"
    },
    {
      "image": "https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?w=500&q=80",
      "title": "CASHBACK UNTUNG AGEN DESA",
      "desc": "Diskon Pulsa dan PPOB Melimpah Sepanjang Hari"
    }
  ];

  final List<String> _feedTickers = [
    "Feed: Masuk untuk lihat update transaksi sukses terbaru hari ini!",
    "Feed: Halo Agen, siap memaksimalkan keuntungan jualan Anda?",
    "Feed: Sambungkan koneksi jaringan terpercaya demi kelancaran PPOB.",
    "Feed: Dapatkan perlindungan transaksi aman 100% bersama DesaPay Proteksi."
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentIndexBanner < _promoBanners.length - 1) {
        _currentIndexBanner++;
      } else {
        _currentIndexBanner = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndexBanner,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMegaPromoPopup();
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatRupiah(dynamic angka) {
    int value = int.tryParse(angka.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _showMegaPromoPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0054A6), Color(0xFF0086FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=600&q=80",
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "FESTIVAL BOLA DUNIA",
                                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Kumpulin DesaPay Points & Tukerin Hadiah Total Miliaran Rupiah Sekarang Juga!",
                                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.4),
                                  ),
                                  const SizedBox(height: 20),
                                  CustomBounce(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD200),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "KUMPULIN SEKARANG",
                                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    radius: 18,
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _currentUser?.uid ?? "DEMO-MODE";

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      body: StreamBuilder<int>(
        stream: _saldoService.streamSaldo(uid),
        builder: (context, snapshot) {
          final int saldoSekarang = snapshot.data ?? 0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // =========================================================================
              // 1. PREMIUM FLOATING HEADER & ACTION ROW
              // =========================================================================
              SliverAppBar(
                expandedHeight: 145,
                pinned: true,
                elevation: 0,
                backgroundColor: WarnaDesaPay.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0054A6), Color(0xFF007BE6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isSaldoHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _isSaldoHidden = !_isSaldoHidden),
                    ),
                    const Text("Rp ", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(
                      _isSaldoHidden ? "••••••" : _formatRupiah(saldoSekarang),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(100)),
                    child: const Row(
                      children: [
                        Text("DESAPAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                        SizedBox(width: 4),
                        Icon(Icons.add_circle_rounded, color: Color(0xFFFFD200), size: 14),
                      ],
                    ),
                  )
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHeaderActionItem(Icons.add_box_rounded, "Isi Saldo", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TopupSaldoScreen()));
                        }),
                        _buildHeaderActionItem(Icons.arrow_downward_rounded, "Minta", () {}),
                        _buildHeaderActionItem(Icons.send_rounded, "Kirim", () {}),
                        _buildHeaderActionItem(Icons.mail_rounded, "Pesan", () {}),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================================================
                    // 2. DYNAMIC BROADCAST MOVING INTERACTIVE SLIDER
                    // =========================================================================
                    Container(
                      height: 140,
                      margin: const EdgeInsets.only(top: 16),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _promoBanners.length,
                        onPageChanged: (index) => setState(() => _currentIndexBanner = index),
                        itemBuilder: (context, index) {
                          final banner = _promoBanners[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(image: NetworkImage(banner["image"]!), fit: BoxFit.cover),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(banner["title"]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(banner["desc"]!, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // =========================================================================
                    // 3. CORE SERVICE PPOB GRID LAYOUT (PERBAIKAN: PEMBERSIHAN KATA KUNCI CONST KELOMPOK)
                    // =========================================================================
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 18,
                        children: [
                          _buildGridMenuItem(Icons.phone_android_rounded, "Pulsa & Data", const Color(0xFF0054A6), () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PulsaScreen()));
                          }),
                          _buildGridMenuItem(Icons.bolt_rounded, "Listrik PLN", const Color(0xFFFFB300), () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PascabayarScreen(jenisLayanan: "PLN")));
                          }),
                          _buildGridMenuItem(Icons.water_drop_rounded, "PDAM Air", const Color(0xFF00C4FF), () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PascabayarScreen(jenisLayanan: "PDAM")));
                          }),
                          _buildGridMenuItem(Icons.health_and_safety_rounded, "BPJS", const Color(0xFF22C55E), () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PascabayarScreen(jenisLayanan: "BPJS")));
                          }),
                          _buildGridMenuItem(Icons.tv_rounded, "TV Kabel", const Color(0xFFFF6600), () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PascabayarScreen(jenisLayanan: "TV KABEL")));
                          }),
                          _buildGridMenuItem(Icons.star_rounded, "A+ Rewards", const Color(0xFFFF1493), () {}),
                          _buildGridMenuItem(Icons.flight_rounded, "Travel Tiket", const Color(0xFF8338EC), () {}),
                          _buildGridMenuItem(Icons.apps_rounded, "Lihat Semua", Colors.grey.shade700, () {}),
                        ],
                      ),
                    ),

                    // =========================================================================
                    // 4. VERTICAL MARQUEE FEED TICKERS
                    // =========================================================================
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _feedTickers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_rounded, size: 14, color: Color(0xFF0086FF)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _feedTickers[index],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Icon(Icons.campaign_rounded, size: 14, color: Colors.grey.shade400),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // =========================================================================
                    // 5. SECURED FRAUD SHIELD INSURANCE INDICATOR
                    // =========================================================================
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0086FF).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF0086FF).withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: Color(0xFF0086FF), size: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("10 Aktivitas Terlindungi Sistem", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text("Jaminan proteksi saldo aman anti-penipuan global 100%.", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0086FF)),
                        ],
                      ),
                    ),

                    // =========================================================================
                    // 6. DEALS ENGINE VOUCHER CAROUSEL
                    // =========================================================================
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("DesaPay Deals Premium", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text("Lihat Semua", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0086FF))),
                        ],
                      ),
                    ),
                    Container(
                      height: 115,
                      margin: const EdgeInsets.only(bottom: 24),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildDealsCard("XXI Cinema Tiket", "Rp50.000", "Diskon 20%", Colors.amber.shade800),
                          _buildDealsCard("Supermarket Voucher", "Rp10.000", "Diskon 20%", Colors.red.shade700),
                          _buildDealsCard("Paket Data Bulk", "Rp40.000", "Spesial Deal", Colors.purple.shade700),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGridMenuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return CustomBounce(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDealsCard(String title, String price, String badge, Color color) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
            child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(price, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          )
        ],
      ),
    );
  }
}
