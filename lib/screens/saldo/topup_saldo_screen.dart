import 'package:flutter/material.dart';

import '../../config/warna.dart';
import 'metode_pembayaran_screen.dart';

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

          // REVISI: Sekarang kita oper "context" ke dalam fungsi _nominal
          _nominal(context, "Rp10.000"),
          _nominal(context, "Rp20.000"),
          _nominal(context, "Rp50.000"),
          _nominal(context, "Rp100.000"),
          _nominal(context, "Rp200.000"),
          _nominal(context, "Rp500.000"),
          _nominal(context, "Rp1.000.000"),

        ],
      ),
    );
  }

  // REVISI: Menambahkan parameter "BuildContext context" agar fungsi ini punya akses navigasi
  Widget _nominal(BuildContext context, String nominal) {
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

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MetodePembayaranScreen(
                nominal: nominal,
              ),
            ),
          );
        },
      ),
    );
  }
}
