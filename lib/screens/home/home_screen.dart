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
              height: 140,
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
              mainAxisSpacing: 20,
              crossAxisSpacing: 10,

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

            Card(
              child: ListTile(
                leading: const Icon(Icons.local_offer),
                title: const Text("Promo Hari Ini"),
                subtitle: const Text(
                  "Nikmati harga spesial Pulsa, Paket Data, Token PLN dan E-Wallet.",
                ),
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text("Pusat Bantuan"),
                subtitle: const Text(
                  "WhatsApp : 085642131263\nEmail : gacoan449@gmail.com",
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
