import 'package:flutter/material.dart';
import '../../config/warna.dart';

// Panggil semua halaman layar produk yang sudah kita buat otomatis
import 'paket_screen.dart';
import 'pln_screen.dart';
import 'ewallet_screen.dart';
// Catatan: Jika Anda sudah punya file PulsaScreen, silakan aktifkan import di bawah ini
// import 'pulsa_screen.dart'; 

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
          // 1. PULSA (Sementara memunculkan SnackBar, siap diarahkan ke PulsaScreen)
          MenuLayanan(
            icon: Icons.phone_android,
            title: "Pulsa",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Menu Pulsa Reguler sedang kita siapkan otomatis")),
              );
              // Nanti jika PulsaScreen sudah ada, hapus SnackBar di atas lalu aktifkan kode ini:
              // Navigator.push(context, MaterialPageRoute(builder: (_) => const PulsaScreen()));
            },
          ),

          // 2. PAKET DATA (Sudah Terhubung & Otomatis)
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

          // 3. PLN (Sudah Terhubung & Otomatis)
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

          // 4. E-WALLET (Sudah Terhubung & Otomatis)
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

          // 5. VOUCHER GAME (Pengembangan Selanjutnya)
          MenuLayanan(
            icon: Icons.sports_esports,
            title: "Voucher Game",
            onTap: () => _tampilkanPesanBelumTersedia(context, "Voucher Game"),
          ),

          // 6. BPJS (Pengembangan Selanjutnya)
          MenuLayanan(
            icon: Icons.health_and_safety,
            title: "BPJS",
            onTap: () => _tampilkanPesanBelumTersedia(context, "BPJS"),
          ),

          // 7. PDAM (Pengembangan Selanjutnya)
          MenuLayanan(
            icon: Icons.water_drop,
            title: "PDAM",
            onTap: () => _tampilkanPesanBelumTersedia(context, "PDAM"),
          ),

          // 8. TV KABEL (Pengembangan Selanjutnya)
          MenuLayanan(
            icon: Icons.tv,
            title: "TV Kabel",
            onTap: () => _tampilkanPesanBel_umTersedia(context, "TV Kabel"),
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

  // Fungsi pembantu untuk memunculkan pesan menu yang belum diotomatiskan
  void _tampilkanPesanBelumTersedia(BuildContext context, String namaLayanan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$namaLayanan segera tersedia"),
      ),
    );
  }
}

// Komponen tombol menu yang menerima aksi ketukan (onTap) secara dinamis
class MenuLayanan extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap; // Menampung perintah klik dari halaman utama

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
        onTap: onTap, // Menjalankan fungsi perpindahan halaman saat ditekan
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
