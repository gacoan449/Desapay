import 'package:flutter/material.dart';

import '../../config/warna.dart';
import '../../widgets/banner_promo.dart';
import '../../widgets/menu_item.dart';
import '../../widgets/saldo_card.dart';

import '../pulsa/pulsa_screen.dart';
import '../paket/paket_screen.dart';
import '../pln/pln_screen.dart';
import '../ewallet/ewallet_screen.dart';

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
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Selamat Datang 👋",
              style: TextStyle(
                fontSize: 16,
              ),
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
              "Layanan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
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

              ],
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(Icons.local_offer),

                title: const Text("Promo Hari Ini"),

                subtitle: const Text(
                  "Pulsa, Paket Data dan Token PLN lebih hemat.",
                ),
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: ListTile(
                leading: const Icon(Icons.support_agent),

                title: const Text("Butuh Bantuan?"),

                subtitle: const Text(
                  "WhatsApp 085642131263",
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
