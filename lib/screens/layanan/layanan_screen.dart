import 'package:flutter/material.dart';

// PENGATURAN TEMA & WIDGET MODULAR (CTO STANDARD)
import '../../config/warna.dart';
import '../../widgets/menu_item.dart'; // Memuat MenuItem dan CustomBounce yang sudah distandarisasi

// JALUR IMPORT GLOBAL KE SCREENS LAYANAN PPOB
import '../paket/paket_screen.dart';
import '../pln/pln_screen.dart';
import '../ewallet/ewallet_screen.dart';
import '../pulsa/pulsa_screen.dart';
import '../pascabayar_screen.dart';

// =========================================================================
// DATA CLASS: STRONG-TYPED MODEL UNTUK ITEM LAYANAN (ANTI RUNTIME ERROR)
// =========================================================================
class DataLayanan {
  final IconData icon;
  final String title;
  final Color color;
  final Widget? target;
  final String? pesan;

  const DataLayanan({
    required this.icon,
    required this.title,
    required this.color,
    this.target,
    this.pesan,
  });
}

// =========================================================================
// MAIN SCREEN WINDOWS: HALAMAN SEMUA LAYANAN DESAPAY
// =========================================================================
class LayananScreen extends StatefulWidget {
  const LayananScreen({super.key});

  @override
  State<LayananScreen> createState() => _LayananScreenState();
}

class _LayananScreenState extends State<LayananScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // Global Keys untuk auto-scroll ketika tab ditekan (Sticky Tabs)
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

  /// Menangani pergerakan scroll reaktif berdasarkan tab yang dipilih
  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.05, // Memberikan sedikit jarak (offset) dari ujung atas layar
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
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
        // STICKY TABS PLATFORM (STYLE FINTECH PREMIUM)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            width: double.infinity,
            child: TabBar(
              controller: _tabController,
              indicatorColor: WarnaDesaPay.primary,
              indicatorWeight: 3, // Indikator lebih tebal & tegas
              labelColor: WarnaDesaPay.primary,
              unselectedLabelColor: WarnaDesaPay.textSub,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              onTap: (index) {
                if (index == 0) _scrollToSection(_keyKategori1);
                if (index == 1) _scrollToSection(_keyKategori2);
                if (index == 2) _scrollToSection(_keyKategori3);
              },
              tabs: const [
                Tab(text: "Pulsa & Data"),
                Tab(text: "E-Wallet"),
                Tab(text: "Biller PPOB"),
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
            // ==========================================
            // KATEGORI 1: PULSA & DATA
            // ==========================================
            _buildSectionKategori(
              key: _keyKategori1,
              icon: Icons.phone_iphone_rounded,
              judul: "Pulsa & Paket Data",
              items: [
                const DataLayanan(icon: Icons.phone_android_rounded, title: "Pulsa", color: Color(0xFFFF9F43), target: PulsaScreen()),
                const DataLayanan(icon: Icons.swap_horizontal_circle_rounded, title: "Transfer Pulsa", color: Color(0xFFFF6B6B), target: PulsaScreen()),
                const DataLayanan(icon: Icons.flash_on_rounded, title: "Token PLN", color: Color(0xFFD97706), target: PlnScreen()),
                const DataLayanan(icon: Icons.star_rounded, title: "Tsel Spesial", color: Color(0xFFE52229), target: PaketScreen()),
                const DataLayanan(icon: Icons.bolt_rounded, title: "Aktivasi Tsel", color: Color(0xFFFA5252), target: PaketScreen()),
                const DataLayanan(icon: Icons.phone_in_talk_rounded, title: "Paket Nelpon", color: Color(0xFF0284C7), pesan: "Paket Nelpon"),
                const DataLayanan(icon: Icons.signal_cellular_alt_rounded, title: "Kuota Tri", color: Color(0xFF9333EA), target: PaketScreen()),
                const DataLayanan(icon: Icons.signal_cellular_alt_rounded, title: "Kuota Indosat", color: Color(0xFFDB2777), target: PaketScreen()),
                const DataLayanan(icon: Icons.signal_cellular_alt_rounded, title: "Kuota Smart", color: Color(0xFFDB2777), target: PaketScreen()),
                const DataLayanan(icon: Icons.signal_cellular_alt_rounded, title: "Kuota by.U", color: Color(0xFF0D9488), target: PaketScreen()),
                const DataLayanan(icon: Icons.signal_cellular_alt_rounded, title: "Kuota XL", color: Color(0xFF0284C7), target: PaketScreen()),
                const DataLayanan(icon: Icons.signal_cellular_alt_rounded, title: "Kuota AXIS", color: Color(0xFF7E22CE), target: PaketScreen()),
              ],
            ),

            // ==========================================
            // KATEGORI 2: E-WALLET
            // ==========================================
            _buildSectionKategori(
              key: _keyKategori2,
              icon: Icons.account_balance_wallet_rounded,
              judul: "E-Wallet & E-Money",
              items: [
                const DataLayanan(icon: Icons.directions_car_filled_rounded, title: "MAXIM", color: Color(0xFFF59E0B), target: EwalletScreen(jenisEwallet: "MAXIM")),
                const DataLayanan(icon: Icons.electric_moped_rounded, title: "GRAB Driver", color: Color(0xFF16A34A), target: EwalletScreen(jenisEwallet: "GRAB")),
                const DataLayanan(icon: Icons.two_wheeler_rounded, title: "inDrive", color: Color(0xFF22C55E), target: EwalletScreen(jenisEwallet: "INDRIVE")),
                const DataLayanan(icon: Icons.motorcycle_rounded, title: "Gojek Driver", color: Color(0xFF15803D), target: EwalletScreen(jenisEwallet: "Gojek Driver")),
                const DataLayanan(icon: Icons.shopping_bag_rounded, title: "ShopeePay", color: Color(0xFFF43F5E), target: EwalletScreen(jenisEwallet: "ShopeePay")),
                const DataLayanan(icon: Icons.account_balance_wallet_rounded, title: "DANA", color: Color(0xFF0284C7), target: EwalletScreen(jenisEwallet: "DANA")),
                const DataLayanan(icon: Icons.payment_rounded, title: "LinkAja", color: Color(0xFFDC2626), target: EwalletScreen(jenisEwallet: "LinkAja")),
                const DataLayanan(icon: Icons.credit_card_rounded, title: "OVO", color: Color(0xFF7C3AED), target: EwalletScreen(jenisEwallet: "OVO")),
                const DataLayanan(icon: Icons.wallet_rounded, title: "GOPAY", color: Color(0xFF0EA5E9), target: EwalletScreen(jenisEwallet: "GoPay")),
              ],
            ),

            // ==========================================
            // KATEGORI 3: BILLER PPOB
            // ==========================================
            _buildSectionKategori(
              key: _keyKategori3,
              icon: Icons.receipt_long_rounded,
              judul: "Tagihan Bulanan & PPOB",
              items: [
                const DataLayanan(icon: Icons.receipt_long_rounded, title: "Pascabayar", color: Color(0xFF334155), target: PascabayarScreen(jenisLayanan: "PASCABAYAR")),
                const DataLayanan(icon: Icons.electric_meter_rounded, title: "Tagihan PLN", color: Color(0xFFD97706), target: PascabayarScreen(jenisLayanan: "LISTRIK")),
                const DataLayanan(icon: Icons.water_drop_rounded, title: "Air PDAM", color: Color(0xFF0284C7), target: PascabayarScreen(jenisLayanan: "PDAM")),
                const DataLayanan(icon: Icons.health_and_safety_rounded, title: "BPJS Kesh", color: Color(0xFF16A34A), target: PascabayarScreen(jenisLayanan: "BPJS")),
                const DataLayanan(icon: Icons.tv_rounded, title: "TV Kabel", color: Color(0xFFEA580C), target: PascabayarScreen(jenisLayanan: "TV KABEL")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper untuk membangun blok kontainer masing-masing kategori
  Widget _buildSectionKategori({
    required GlobalKey key,
    required IconData icon,
    required String judul,
    required List<DataLayanan> items,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: WarnaDesaPay.lightCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: WarnaDesaPay.shadow.withOpacity(0.06), 
            blurRadius: 14, 
            spreadRadius: 0, 
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // JUDUL KATEGORI
          Row(
            children: [
              Icon(icon, size: 22, color: WarnaDesaPay.primary),
              const SizedBox(width: 10),
              Text(
                judul,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: WarnaDesaPay.textMain, letterSpacing: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // GRID MENU LAYANAN MODULAR
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Disesuaikan agar teks 2 baris tidak terpotong
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final data = items[index];

              // MENGGUNAKAN KOMPONEN `MenuItem` YANG SUDAH KITA STANDARISASI
              return MenuItem(
                icon: data.icon,
                title: data.title,
                iconColor: data.color,
                badgeColor: data.color.withOpacity(0.12),
                onTap: () {
                  if (data.target != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => data.target!));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Layanan ${data.pesan} segera hadir!"),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: WarnaDesaPay.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
