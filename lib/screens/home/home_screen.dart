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

      appBar: AppBar(
        elevation: 0,
        title: const Text("DesaPay"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Selamat Datang 👋",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 5),

            const Text(
              "Pengguna DesaPay",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const SaldoCard(),

            const SizedBox(height: 20),

            const BannerPromo(),

            const SizedBox(height: 25),

            const Text(
              "Promo DesaPay",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 165,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [

                  PromoCard(
                    title: "Cashback Pulsa",
                    subtitle: "Lebih hemat setiap transaksi",
                    icon: Icons.local_offer,
                    color: Colors.blue,
                  ),

                  SizedBox(width: 12),

                  PromoCard(
                    title: "Token PLN",
                    subtitle: "Admin murah",
                    icon: Icons.flash_on,
                    color: Colors.orange,
                  ),

                  SizedBox(width: 12),

                  PromoCard(
                    title: "Top Up E-Wallet",
                    subtitle: "Proses cepat",
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Layanan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PulsaScreen(),
                      ),
                    );
                  },
                ),

                MenuItem(
                  icon: Icons.wifi,
                  title: "Data",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaketScreen(),
                      ),
                    );
                  },
                ),

                MenuItem(
                  icon: Icons.flash_on,
                  title: "PLN",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlnScreen(),
                      ),
                    );
                  },
                ),

                MenuItem(
                  icon: Icons.account_balance_wallet,
                  title: "E-Wallet",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EwalletScreen(),
                      ),
                    );
                  },
                ),

                MenuItem(
                  icon: Icons.sports_esports,
                  title: "Game",
                  onTap: () {},
                ),

                MenuItem(
                  icon: Icons.health_and_safety,
                  title: "BPJS",
                  onTap: () {},
                ),

                MenuItem(
                  icon: Icons.water_drop,
                  title: "PDAM",
                  onTap: () {},
                ),

                MenuItem(
                  icon: Icons.grid_view,
                  title: "Semua",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LayananScreen(),
                      ),
                    );
                  },
                ),

              ],
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.orange,
                    child: Icon(
                      Icons.local_offer,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Promo Hari Ini",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Cashback hingga 10% untuk Pulsa, PLN dan E-Wallet.",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.support_agent,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pusat Bantuan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "WhatsApp\n085642131263",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  "Riwayat Transaksi",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Lihat semua transaksi Anda",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RiwayatScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                "Versi 1.0.0\n© 2026 DesaPay",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 25),

          ],
        ),
      ),
    );
  }
}
