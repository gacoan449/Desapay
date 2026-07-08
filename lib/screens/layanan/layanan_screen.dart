import 'package:flutter/material.dart';

import '../../config/warna.dart';

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
        children: const [

          MenuLayanan(Icons.phone_android,"Pulsa"),
          MenuLayanan(Icons.wifi,"Paket Data"),
          MenuLayanan(Icons.flash_on,"PLN"),
          MenuLayanan(Icons.account_balance_wallet,"E-Wallet"),
          MenuLayanan(Icons.sports_esports,"Voucher Game"),
          MenuLayanan(Icons.health_and_safety,"BPJS"),
          MenuLayanan(Icons.water_drop,"PDAM"),
          MenuLayanan(Icons.tv,"TV Kabel"),
          MenuLayanan(Icons.more_horiz,"Lainnya"),

        ],
      ),
    );
  }
}

class MenuLayanan extends StatelessWidget {

  final IconData icon;
  final String title;

  const MenuLayanan(
    this.icon,
    this.title, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$title segera tersedia"),
            ),
          );
        },
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
            ),

          ],
        ),
      ),
    );
  }
}
