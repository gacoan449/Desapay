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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSaldoHidden = false;

  Future<void> _bukaWhatsApp() async {
    const nomor = "6285642131263";
    final Uri url = Uri.https(
      'wa.me',
      '/$nomor',
      {'text': 'Halo CS DesaPay, saya mengalami kendala transaksi.'},
    );

    try {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
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
                "QRIS DesaPay",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Fitur QRIS Merchant sedang dalam tahap verifikasi regulasi Tripay. Kami akan memberi tahu Anda setelah fitur ini aktif.",
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
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: WarnaDesaPay.primary,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/logo.png",
                height: 28,
                errorBuilder: (_, __, ___) {
                  return const Icon(Icons.wallet, color: Colors.white, size: 24);
                },
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DesaPay",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.5),
                ),
                Text(
                  "Premium Member",
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            onPressed: _qrisBelumAktif,
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: _notifikasi,
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                ),
              )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
        color: WarnaDesaPay.primary,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: WarnaDesaPay.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "Total Saldo Akun",
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => setState(() => _isSaldoHidden = !_isSaldoHidden),
                                              child: Icon(
                                                _isSaldoHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        _isSaldoHidden
                                            ? const Text("••••••••", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87))
                                            : const KotakSaldo(),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.stars_rounded, color: Colors.blue.shade700, size: 16),
                                          const SizedBox(width: 4),
                                          Text("1,250 Pts", style: TextStyle(color: Colors.blue.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _quickActionItem(Icons.add_card_rounded, "Isi Saldo", () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TopupSaldoScreen()));
                                    }),
                                    _quickActionItem(Icons.send_rounded, "Transfer", _qrisBelumAktif),
                                    _quickActionItem(Icons.qr_code_2_rounded, "Bayar QR", _qrisBelumAktif),
                                    _quickActionItem(Icons.history_toggle_off_rounded, "Riwayat", () {}),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Layanan Pembayaran",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.04),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.88,
                        children: [
                          _menuItem(Icons.phone_android_rounded, "Pulsa", const Color(0xFFFF9F43), const PulsaScreen()),
                          _menuItem(Icons.wifi_rounded, "Paket Data", const Color(0xff0984e3), const PaketScreen()),
                          _menuItem(Icons.flash_on_rounded, "Token PLN", const Color(0xfff1c40f), const PlnScreen()),
                          _menuItem(Icons.account_balance_wallet_rounded, "E-Wallet", const Color(0xff6c5ce7), const EwalletScreen()),
                          _menuItem(Icons.health_and_safety_rounded, "BPJS Kesehatan", const Color(0xff00b894), const PascabayarScreen(jenisLayanan: "BPJS")),
                          _menuItem(Icons.water_drop_rounded, "PDAM Air", const Color(0xff00cec9), const PascabayarScreen(jenisLayanan: "PDAM")),
                          _menuItem(Icons.mosque_rounded, "Zakat/Infak", const Color(0xffe17055), const LayananScreen()),
                          _menuItem(Icons.grid_view_rounded, "Semua Menu", const Color(0xff636e72), const LayananScreen()),
                        ],
                      ),
                    ),
                  ],
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
                        const Text("Promo Spesial Hari Ini", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        TextButton(onPressed: () {}, child: Text("Lihat Semua", style: TextStyle(color: WarnaDesaPay.primary, fontWeight: FontWeight.bold)))
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 130,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildPromoCard(
                            [Colors.blue.shade800, Colors.lightBlue.shade500],
                            "assets/promo1.png",
                            "Bebas Admin Tripay",
                            "Top Up Saldo via Merchant Minimarket gratis potongan biaya khusus minggu ini!",
                          ),
                          _buildPromoCard(
                            [Colors.purple.shade700, Colors.pink.shade400],
                            "assets/promo2.png",
                            "Cuan Token Listrik",
                            "Nikmati potongan harga PPOB s.d Rp 10.000 untuk pengisian token PLN larut malam.",
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: _bukaWhatsApp,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.teal.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Butuh Bantuan Cepat?",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Hubungi Customer Service WhatsApp DesaPay jika ada kendala saldo atau transaksi gateway.",
                                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              Center(
                child: Column(
                  children: [
                    Icon(Icons.shield_rounded, size: 32, color: WarnaDesaPay.primary.withOpacity(0.25)),
                    const SizedBox(height: 8),
                    Text(
                      "Secured by Tripay Payment Gateway Network",
                      style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "© 2026 DesaPay Indonesia • Version 2.0.0-Premium",
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

  Widget _quickActionItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Icon(icon, color: WarnaDesaPay.primary, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color warna, Widget tujuan) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => tujuan)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warna.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
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

  Widget _buildPromoCard(List<Color> colors, String fallbackAsset, String title, String subtitle) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.local_offer_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
        ],
      ),
    );
  }
}
