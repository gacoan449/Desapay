import 'package:flutter/material.dart';

import '../../config/warna.dart';

import '../../widgets/banner_promo.dart';
import '../../widgets/menu_item.dart';
import '../../widgets/promo_card.dart';
import '../../widgets/saldo_card.dart';

import '../pulsa/pulsa_screen.dart';
import '../paket/paket_screen.dart';
import '../pln/pln_screen.dart';
import '../ewallet/ewallet_screen.dart';
import '../layanan/layanan_screen.dart';
import '../riwayat/riwayat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 1. Header Premium
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff1565C0),
                    Color(0xff42A5F5),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Selamat Datang",
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              "Pengguna DesaPay",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Icon(Icons.notifications, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Pencarian
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Cari layanan...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // 3. Tombol Cepat
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text("Isi Saldo"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.send),
                    label: const Text("Transfer"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("Scan"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. Statistik Singkat
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.blue, size: 28),
                          SizedBox(height: 8),
                          Text("24", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Transaksi", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.payments, color: Colors.green, size: 28),
                          SizedBox(height: 8),
                          Text("Rp 0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Saldo", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.stars, color: Colors.orange, size: 28),
                          SizedBox(height: 8),
                          Text("0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Poin", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // 5. Menu Layanan Utama
            const Text(
              "Layanan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 0.78,
              mainAxisSpacing: 18,
              crossAxisSpacing: 12,
              children: [
                MenuItem(
                  icon: Icons.phone_android,
                  title: "Pulsa",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PulsaScreen()));
                  },
                ),
                MenuItem(
                  icon: Icons.wifi,
                  title: "Data",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PaketScreen()));
                  },
                ),
                MenuItem(
                  icon: Icons.flash_on,
                  title: "PLN",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlnScreen()));
                  },
                ),
                MenuItem(
                  icon: Icons.account_balance_wallet,
                  title: "E-Wallet",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EwalletScreen()));
                  },
                ),
                MenuItem(icon: Icons.sports_esports, title: "Game", onTap: () {}),
                MenuItem(icon: Icons.health_and_safety, title: "BPJS", onTap: () {}),
                MenuItem(icon: Icons.water_drop, title: "PDAM", onTap: () {}),
                MenuItem(
                  icon: Icons.grid_view,
                  title: "Semua",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LayananScreen()));
                  },
                ),
              ],
            ),

            const SizedBox(height: 25),

            // 6. Menu Favorit
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Transaksi Favorit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 10),
                  Text("Belum ada transaksi favorit", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 7. Banner Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign, color: Colors.green, size: 35),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Isi saldo sekarang dan nikmati cashback hingga 10%.",
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // 8. Promo Hari Ini
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: Colors.orange, child: Icon(Icons.local_offer, color: Colors.white)),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Promo Hari Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        SizedBox(height: 5),
                        Text("Cashback hingga 10% untuk Pulsa, PLN dan E-Wallet."),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // 9. Riwayat Transaksi
            Container(
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.receipt_long, color: Colors.white)),
                title: const Text("Riwayat Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Lihat semua transaksi Anda"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatScreen()));
                },
              ),
            ),

            const SizedBox(height: 15),

            // 10. Keamanan Akun
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.security, color: Colors.white)),
                title: const Text("Keamanan Akun", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Aktifkan PIN & Login OTP"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
            ),

            const SizedBox(height: 10),

            // 11. Pusat Bantuan
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: Colors.teal, child: Icon(Icons.support_agent, color: Colors.white)),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Pusat Bantuan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        SizedBox(height: 5),
                        Text("WhatsApp\n085642131263"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                "Versi 1.0.0\n© 2026 DesaPay",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
