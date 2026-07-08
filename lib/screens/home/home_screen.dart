import 'package:flutter/material.dart';

import '../../config/warna.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("DesaPay"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: WarnaDesaPay.primary,
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Saldo Anda",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "Rp 0",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Menu Utama",
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
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,

              children: const [

                _MenuItem(Icons.phone_android,"Pulsa"),
                _MenuItem(Icons.wifi,"Data"),
                _MenuItem(Icons.flash_on,"PLN"),
                _MenuItem(Icons.account_balance_wallet,"E-Wallet"),
                _MenuItem(Icons.receipt_long,"Tagihan"),
                _MenuItem(Icons.history,"Riwayat"),
                _MenuItem(Icons.support_agent,"Bantuan"),
                _MenuItem(Icons.person,"Profil"),

              ],
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(15),
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "🔥 Promo Hari Ini",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "Pulsa mulai Rp5.000\nToken PLN\nTop Up E-Wallet",
                  ),

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {

  final IconData icon;
  final String title;

  const _MenuItem(this.icon,this.title);

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [

        CircleAvatar(
          radius: 28,
          backgroundColor: WarnaDesaPay.primary.withOpacity(.1),
          child: Icon(
            icon,
            color: WarnaDesaPay.primary,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),

      ],
    );

  }
}
