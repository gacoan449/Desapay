import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../notifikasi/notifikasi_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
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
                    Color(0xFF1976D2),
                    Color(0xFF42A5F5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Color(0xFF1976D2), size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Selamat Datang",
                              style: TextStyle(color: Colors.white70, fontSize: 15),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Pengguna DesaPay",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotifikasiScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Pencarian
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Cari layanan...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Tombol Cepat
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text("Isi Saldo", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.send, size: 20),
                    label: const Text("Transfer", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code_scanner, size: 20),
                    label: const Text("Scan", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // 4. Statistik Singkat
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF263238),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.white, size: 30),
                        SizedBox(height: 8),
                        Text("24", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        SizedBox(height: 4),
                        Text("Transaksi", style: TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF263238),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.payments, color: Colors.greenAccent, size: 30),
                        SizedBox(height: 8),
                        Text("Rp 0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        SizedBox(height: 4),
                        Text("Saldo", style: TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF263238),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.stars, color: Colors.orangeAccent, size: 30),
                        SizedBox(height: 8),
                        Text("0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        SizedBox(height: 4),
                        Text("Poin", style: TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // 5. Menu Layanan Utama
            const Text(
              "Layanan",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Transaksi Favorit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF263238))),
                  SizedBox(height: 12),
                  Text("Belum ada transaksi favorit", style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 7. Banner Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.08), blurRadius: 5)],
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign, color: Color(0xFF2E7D32), size: 38),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Isi saldo sekarang dan nikmati cashback hingga 10%.",
                      style: TextStyle(fontSize: 15, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // 8. Promo Hari Ini
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.08), blurRadius: 5)],
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 26, backgroundColor: Color(0xFFFF9800), child: Icon(Icons.local_offer, color: Colors.white, size: 28)),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Promo Hari Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFFE65100))),
                        SizedBox(height: 6),
                        Text("Cashback hingga 10% untuk Pulsa, PLN dan E-Wallet.", style: TextStyle(color: Color(0xFFE65100), fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // 9. Riwayat Transaksi
            Container(
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.06), blurRadius: 5)]),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF1976D2), child: Icon(Icons.receipt_long, color: Colors.white)),
                title: const Text("Riwayat Transaksi", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                subtitle: const Text("Lihat semua transaksi Anda", style: TextStyle(color: Colors.blueGrey)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blueGrey),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatScreen()));
                },
              ),
            ),

            const SizedBox(height: 15),

            // 10. Keamanan Akun
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF388E3C), child: Icon(Icons.security, color: Colors.white)),
                title: const Text("Keamanan Akun", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                subtitle: const Text("Aktifkan PIN & Login OTP", style: TextStyle(color: Colors.grey)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {},
              ),
            ),

            const SizedBox(height: 12),

            // 11. Pusat Bantuan
            InkWell(
              onTap: () async {
                final Uri urlWa = Uri.parse("https://wa.me/6285642131263");
                if (await canLaunchUrl(urlWa)) {
                  await launchUrl(urlWa, mode: LaunchMode.externalApplication);
                } else {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Aplikasi WhatsApp tidak ditemukan")),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.06), blurRadius: 5)],
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 26, backgroundColor: Color(0xFF00897B), child: Icon(Icons.support_agent, color: Colors.white, size: 28)),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pusat Bantuan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF00796B))),
                          SizedBox(height: 6),
                          Text("WhatsApp\n085642131263", style: TextStyle(color: Color(0xFF00796B), height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Center(
              child: Text(
                "Versi 1.0.0\n© 2026 DesaPay",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
