import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../widgets/menu_item.dart';
import 'ppob_generic_screen.dart'; 

class SemuaLayananScreen extends StatelessWidget {
  const SemuaLayananScreen({super.key});

  void _bukaLayanan(BuildContext context, String namaLayanan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PpobGenericScreen(kategori: namaLayanan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: WarnaDesaPay.textMain,
        title: const Text(
          "Semua Produk & Layanan",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildKategoriSection(
            context,
            judul: "Telekomunikasi",
            layanan: [
              _ItemData("Pulsa Murah", Icons.phone_android_rounded, const Color(0xFFEFF6FF), WarnaDesaPay.primary),
              _ItemData("Paket Data", Icons.wifi_tethering_rounded, const Color(0xFFF0F9FF), const Color(0xFF0284C7)),
              _ItemData("Telkom", Icons.phone_in_talk_rounded, const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
            ],
          ),
          Container(height: 8, color: WarnaDesaPay.lightBg), 
          _buildKategoriSection(
            context,
            judul: "Tagihan & Gaya Hidup",
            layanan: [
              _ItemData("Listrik PLN", Icons.bolt_rounded, const Color(0xFFFFFBEB), const Color(0xFFD97706)),
              _ItemData("PDAM Air", Icons.water_drop_rounded, const Color(0xFFECFEFF), WarnaDesaPay.secondary),
              _ItemData("BPJS", Icons.health_and_safety_rounded, const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
              _ItemData("TV Kabel", Icons.tv_rounded, const Color(0xFFFAF5FF), const Color(0xFF9333EA)),
            ],
          ),
          Container(height: 8, color: WarnaDesaPay.lightBg),
          _buildKategoriSection(
            context,
            judul: "Hiburan & Top Up",
            layanan: [
              _ItemData("Top Up Games", Icons.sports_esports_rounded, const Color(0xFFFFF1F2), const Color(0xFFE11D48)),
              _ItemData("Uang Elektronik", Icons.account_balance_wallet_rounded, const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
              _ItemData("Streaming", Icons.play_circle_filled_rounded, const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildKategoriSection(
    BuildContext context, {
    required String judul,
    required List<_ItemData> layanan,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: WarnaDesaPay.textMain,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 20,
              childAspectRatio: 0.85,
            ),
            itemCount: layanan.length,
            itemBuilder: (context, index) {
              final item = layanan[index];
              return MenuItem(
                icon: item.icon,
                title: item.title,
                badgeColor: item.bgColor,
                iconColor: item.iconColor,
                onTap: () => _bukaLayanan(context, item.title),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ItemData {
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  
  _ItemData(this.title, this.icon, this.bgColor, this.iconColor);
}
