import 'package:flutter/material.dart';
import '../../config/warna.dart';

// JALUR IMPORT GLOBAL KE SCREENS LAIN
import '../paket/paket_screen.dart';
import '../pln/pln_screen.dart';
import '../ewallet/ewallet_screen.dart';
import '../pulsa/pulsa_screen.dart';
import '../pascabayar_screen.dart';

// ==========================================
// CUSTOM BOUNCE ANIMATION WIDGET
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
class LayananScreen extends StatefulWidget {
  const LayananScreen({super.key});

  @override
  State<LayananScreen> createState() => _LayananScreenState();
}

class _LayananScreenState extends State<LayananScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // Global Keys untuk auto-scroll ketika tab ditekan
  final GlobalKey _keyKategori1 = GlobalKey();
  final GlobalKey _keyKategori2 = GlobalKey();
  final GlobalKey _keyKategori3 = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        title: const Text(
          "Semua Kategori",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        // STICKY TABS PLATFORM (STYLE DANA LENGKAP)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            width: double.infinity,
            child: TabBar(
              controller: _tabController,
              indicatorColor: WarnaDesaPay.primary,
              labelColor: WarnaDesaPay.primary,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              onTap: (index) {
                if (index == 0) _scrollToSection(_keyKategori1);
                if (index == 1) _scrollToSection(_keyKategori2);
                if (index == 2) _scrollToSection(_keyKategori3);
              },
              tabs: const [
                Tab(text: "Pulsa & Data"),
                Tab(text: "E-Wallet"),
                Tab(text: "Tagihan Bulanan"),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KATEGORI 1: PULSA & DATA
            Container(
              key: _keyKategori1,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJudulHeader(Icons.phone_iphone_rounded, "Pulsa & Paket Data"),
                  const SizedBox(height: 16),
                  _buildGridMenu(context, [
                    _item(Icons.phone_android_rounded, "Pulsa", const Color(0xFFFF9F43), const PulsaScreen()),
                    _item(Icons.swap_horizontal_circle_rounded, "Transfer Pulsa", const Color(0xFFFF6B6B), const PulsaScreen()),
                    _item(Icons.flash_on_rounded, "Token PLN", const Color(0xFFFFD200), const PlnScreen()),
                    _item(Icons.star_rounded, "Tsel Spesial", const Color(0xFFE52229), const PaketScreen()),
                    _item(Icons.bolt_rounded, "Aktivasi Tsel", const Color(0xFFFA5252), const PaketScreen()),
                    _item(Icons.phone_in_talk_rounded, "Paket Nelpon", const Color(0xFF108EE9), null, pesan: "Paket Nelpon"),
                    _item(Icons.signal_cellular_alt_rounded, "Kuota Tri", const Color(0xFF9B5DE5), const PaketScreen()),
                    _item(Icons.signal_cellular_alt_rounded, "Kuota Indosat", const Color(0xFFF15BB5), const PaketScreen()),
                    _item(Icons.signal_cellular_alt_rounded, "Kuota Smart", const Color(0xFFF15BB5), const PaketScreen()),
                    _item(Icons.signal_cellular_alt_rounded, "Kuota by.U", const Color(0xFF00F5D4), const PaketScreen()),
                    _item(Icons.signal_cellular_alt_rounded, "Kuota XL", const Color(0xFF00BBF9), const PaketScreen()),
                    _item(Icons.signal_cellular_alt_rounded, "Kuota AXIS", const Color(0xFF8338EC), const PaketScreen()),
                  ]),
                ],
              ),
            ),

            // KATEGORI 2: E-WALLET
            Container(
              key: _keyKategori2,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJudulHeader(Icons.account_balance_wallet_rounded, "E-Wallet & E-Money"),
                  const SizedBox(height: 16),
                  _buildGridMenu(context, [
                    _item(Icons.directions_car_filled_rounded, "MAXIM", const Color(0xFFFBC531), const EwalletScreen(jenisEwallet: "MAXIM")),
                    _item(Icons.electric_moped_rounded, "GRAB Driver", const Color(0xFF4CD137), const EwalletScreen(jenisEwallet: "GRAB")),
                    _item(Icons.two_wheeler_rounded, "inDrive", const Color(0xFF44BD32), const EwalletScreen(jenisEwallet: "INDRIVE")),
                    _item(Icons.motorcycle_rounded, "Gojek Driver", const Color(0xFF009432), const EwalletScreen(jenisEwallet: "Gojek Driver")),
                    _item(Icons.shopping_bag_rounded, "ShopeePay", const Color(0xFFFF7675), const EwalletScreen(jenisEwallet: "ShopeePay")),
                    _item(Icons.account_balance_wallet_rounded, "DANA", const Color(0xFF00a8ff), const EwalletScreen(jenisEwallet: "DANA")),
                    _item(Icons.payment_rounded, "LinkAja", const Color(0xFFEA2027), const EwalletScreen(jenisEwallet: "LinkAja")),
                    _item(Icons.credit_card_rounded, "OVO", const Color(0xFF9C88FF), const EwalletScreen(jenisEwallet: "OVO")),
                    _item(Icons.wallet_rounded, "GOPAY", const Color(0xFF00C2FF), const EwalletScreen(jenisEwallet: "GoPay")),
                  ]),
                ],
              ),
            ),

            // KATEGORI 3: BILLER PPOB
            Container(
              key: _keyKategori3,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJudulHeader(Icons.receipt_long_rounded, "Tagihan Bulanan & PPOB"),
                  const SizedBox(height: 16),
                  _buildGridMenu(context, [
                    _item(Icons.receipt_long_rounded, "Pascabayar", const Color(0xFF487EB0), const PascabayarScreen(jenisLayanan: "PASCABAYAR")),
                    _item(Icons.electric_meter_rounded, "Tagihan PLN", const Color(0xFF2F3640), const PascabayarScreen(jenisLayanan: "LISTRIK")),
                    _item(Icons.water_drop_rounded, "Air PDAM", const Color(0xFF00A8FF), const PascabayarScreen(jenisLayanan: "PDAM")),
                    _item(Icons.health_and_safety_rounded, "BPJS Kesh", const Color(0xFF4CD137), const PascabayarScreen(jenisLayanan: "BPJS")),
                    _item(Icons.tv_rounded, "TV Kabel", const Color(0xFFE84118), const PascabayarScreen(jenisLayanan: "TV KABEL")),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJudulHeader(IconData icon, String judul) {
    return Row(
      children: [
        Icon(icon, size: 20, color: WarnaDesaPay.primary),
        const SizedBox(width: 8),
        Text(
          judul,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildGridMenu(BuildContext context, List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 18,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final data = items[index];
        final Color itemColor = data['color'] as Color;

        return CustomBounce(
          onTap: () {
            if (data['target'] != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => data['target']));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Layanan ${data['pesan']} otomatis terkoneksi ke sistem pusat."),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: WarnaDesaPay.primary,
                ),
              );
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(data['icon'] as IconData, size: 24, color: itemColor),
              ),
              const SizedBox(height: 8),
              Text(
                data['title'] as String,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _item(IconData icon, String title, Color color, Widget? target, {String? pesan}) {
    return {'icon': icon, 'title': title, 'color': color, 'target': target, 'pesan': pesan};
  }
}
