import 'package:flutter/material.dart';

import '../../config/warna.dart';

class MetodePembayaranScreen extends StatelessWidget {
  final String nominal;

  const MetodePembayaranScreen({
    super.key,
    required this.nominal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Metode Pembayaran"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          const Text(
            "Transfer Bank",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 10),

          _item(
            context,
            "BCA Virtual Account",
            Icons.account_balance,
          ),

          _item(
            context,
            "BRI Virtual Account",
            Icons.account_balance,
          ),

          _item(
            context,
            "BNI Virtual Account",
            Icons.account_balance,
          ),

          _item(
            context,
            "Mandiri Virtual Account",
            Icons.account_balance,
          ),

          const SizedBox(height: 25),

          const Text(
            "QRIS",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 10),

          _item(
            context,
            "QRIS Semua E-Wallet",
            Icons.qr_code,
          ),

          const SizedBox(height: 25),

          const Text(
            "Minimarket",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 10),

          _item(
            context,
            "Alfamart",
            Icons.store,
          ),

          _item(
            context,
            "Indomaret",
            Icons.storefront,
          ),

          const SizedBox(height: 25),

          const Text(
            "E-Wallet",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 10),

          _item(
            context,
            "DANA",
            Icons.account_balance_wallet,
          ),

          _item(
            context,
            "OVO",
            Icons.account_balance_wallet,
          ),

          _item(
            context,
            "GoPay",
            Icons.account_balance_wallet,
          ),

          _item(
            context,
            "ShopeePay",
            Icons.account_balance_wallet,
          ),

        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),

      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),

        onTap: () {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "$title dipilih untuk top up $nominal",
              ),
            ),
          );

        },
      ),
    );
  }
}
