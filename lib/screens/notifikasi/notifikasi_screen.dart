import 'package:flutter/material.dart';
import '../../config/warna.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium saat Notifikasi Disentuh
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
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
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

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          "Notifikasi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        // SEGMENTED TABS UNTUK FILTER NOTIFIKASI ALA E-WALLET MEWAH
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
              tabs: const [
                Tab(text: "Aktivitas Transaksi"),
                Tab(text: "Promo & Info"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          // TAB 1: AKTIVITAS TRANSAKSI
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              _buildSectionHeader("Hari Ini"),
              _NotifCard(
                icon: Icons.check_circle_rounded,
                color: Colors.green.shade600,
                title: "Transaksi Berhasil",
                subtitle: "Pulsa Telkomsel Rp20.000 sukses diproses ke nomor tujuan.",
                time: "Baru saja",
                onTap: () {},
              ),
              _NotifCard(
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.blue.shade600,
                title: "Saldo Masuk via Bank",
                subtitle: "Top Up saldo Rp100.000 melalui VA otomatis berhasil ditambahkan.",
                time: "10 menit lalu",
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildSectionHeader("Kategori Lampau"),
              _NotifCard(
                icon: Icons.cancel_rounded,
                color: Colors.red.shade600,
                title: "Transaksi Dibatalkan",
                subtitle: "Pengisian Token PLN Rp50.000 gagal. Saldo telah dikembalikan utuh.",
                time: "2 hari lalu",
                onTap: () {},
              ),
            ],
          ),

          // TAB 2: PROMO & INFO
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              _buildSectionHeader("Terbaru"),
              _NotifCard(
                icon: Icons.local_offer_rounded,
                color: Colors.orange.shade700,
                title: "Promo Spesial Gajian",
                subtitle: "Dapatkan potongan harga langsung s.d 10% untuk pengisian produk PPOB terpilih malam ini.",
                time: "Hari ini",
                onTap: () {},
              ),
              _NotifCard(
                icon: Icons.info_rounded,
                color: Colors.purple.shade600,
                title: "Pemberitahuan Sistem",
                subtitle: "Selamat datang di ekosistem DesaPay Premium Release Build v2.1.1. Nikmati kemudahan bertransaksi.",
                time: "Kemarin",
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final VoidCallback onTap;

  const _NotifCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: CustomBounce(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              // MEMBERIKAN BORDER INDIKATOR WARNA DI SISI KIRI LAYAKNYA APLIKASI PREMIUM
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: color, width: 5),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LINGKARAN IKON MODERN
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  // KONTEN NOTIFIKASI
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
