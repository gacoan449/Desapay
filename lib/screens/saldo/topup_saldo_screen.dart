import 'package:flutter/material.dart';

import '../../config/warna.dart';

class TopupSaldoScreen extends StatelessWidget {
  const TopupSaldoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Isi Saldo"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          const Text(
            "Pilih Nominal",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _nominal("Rp10.000"),
          _nominal("Rp20.000"),
          _nominal("Rp50.000"),
          _nominal("Rp100.000"),
          _nominal("Rp200.000"),
          _nominal("Rp500.000"),
          _nominal("Rp1.000.000"),

        ],
      ),
    );
  }

  Widget _nominal(String nominal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.account_balance_wallet),
        ),

        title: Text(nominal),

        subtitle: const Text(
          "Saldo akan masuk otomatis",
        ),

        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
