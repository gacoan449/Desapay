import 'package:flutter/material.dart';
import '../../config/warna.dart';

// JALUR IMPORT GLOBAL (Menggunakan penanda keluar folder yang tepat)
import '../paket/paket_screen.dart';
import '../pln/pln_screen.dart';
import '../ewallet/ewallet_screen.dart';
import '../pulsa/pulsa_screen.dart';
import '../pascabayar_screen.dart'; // Jalur aman keluar sub-folder

class LayananScreen extends StatelessWidget {
  const LayananScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: const Text("Semua Layanan"),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          // 1. PULSA
          MenuLayanan(
            icon: Icons.phone_android,
            title: "Pulsa",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PulsaScreen()),
              );
            },
          ),

          // 2. PAKET DATA
          MenuLayanan(
            icon: Icons.wifi,
            title: "Paket Data",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaketScreen()),
              );
            },
          ),

          // 3. PLN
          MenuLayanan(
            icon: Icons.flash_on,
            title: "PLN",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlnScreen()),
              );
            },
          ),

          // 4. E-WALLET
          MenuLayanan(
            icon: Icons.account_balance_wallet,
            title: "E-Wallet",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EwalletScreen()),
              );
            },
          ),

          // 5. VOUCHER GAME
          MenuLayanan(
            icon: Icons.sports_esports,
            title: "Voucher Game",
            onTap: () => _tampilkanPesanBelumTersedia(context, "Voucher Game"),
          ),

          // 6. BPJS (KATA CONST DI DEPAN PASCABAYAR SCREEN SUDAH DIHAPUS)
          MenuLayanan(
            icon: Icons.health_and_safety,
            title: "BPJS",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PascabayarScreen(jenisLayanan: "BPJS")),
              );
            },
          ),

          // 7. PDAM (KATA CONST DI DEPAN PASCABAYAR SCREEN SUDAH DIHAPUS)
          MenuLayanan(
            icon: Icons.water_drop,
            title: "PDAM",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PascabayarScreen(jenisLayanan: "PDAM")),
              );
            },
          ),

          // 8. TV KABEL (KATA CONST DI DEPAN PASCABAYAR SCREEN SUDAH DIHAPUS)
          MenuLayanan(
            icon: Icons.tv,
            title: "TV Kabel",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PascabayarScreen(jenisLayanan: "TV KABEL")),
              );
            },
          ),

          // 9. LAINNYA
          MenuLayanan(
            icon: Icons.more_horiz,
            title: "Lainnya",
            onTap: () => _tampilkanPesanBelumTersedia(context, "Layanan Lainnya"),
          ),
        ],
      ),
    );
  }

  void _tampilkanPesanBelumTersedia(BuildContext context, String namaLayanan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$namaLayanan segera tersedia"),
      ),
    );
  }
}

class MenuLayanan extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const MenuLayanan({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 35,
              color: WarnaDesaPay.primary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
