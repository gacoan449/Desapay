import 'package:flutter/material.dart';

import '../../config/warna.dart';

class EwalletScreen extends StatelessWidget {
  const EwalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Top Up E-Wallet"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menu(
            context,
            Icons.account_balance_wallet,
            "DANA",
            "Top Up Saldo DANA",
          ),

          _menu(
            context,
            Icons.account_balance_wallet,
            "OVO",
            "Top Up Saldo OVO",
          ),

          _menu(
            context,
            Icons.account_balance_wallet,
            "GoPay",
            "Top Up Saldo GoPay",
          ),

          _menu(
            context,
            Icons.account_balance_wallet,
            "ShopeePay",
            "Top Up Saldo ShopeePay",
          ),

          _menu(
            context,
            Icons.account_balance_wallet,
            "LinkAja",
            "Top Up Saldo LinkAja",
          ),
        ],
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: WarnaDesaPay.primary.withValues(alpha: 0.1),
          child: Icon(
            icon,
            color: WarnaDesaPay.primary,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$title segera tersedia"),
            ),
          );
        },
      ),
    );
  }
}
