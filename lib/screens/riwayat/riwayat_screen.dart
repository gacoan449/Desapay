import 'package:flutter/material.dart';

import '../../config/warna.dart';

class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
      ),
      backgroundColor: WarnaDesaPay.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [

          RiwayatItem(
            title: "Pulsa Telkomsel",
            nominal: "Rp10.000",
            status: "Berhasil",
            tanggal: "04 Juli 2026",
          ),

          RiwayatItem(
            title: "Token PLN",
            nominal: "Rp50.000",
            status: "Berhasil",
            tanggal: "03 Juli 2026",
          ),

          RiwayatItem(
            title: "Top Up DANA",
            nominal: "Rp20.000",
            status: "Diproses",
            tanggal: "03 Juli 2026",
          ),

        ],
      ),
    );
  }
}

class RiwayatItem extends StatelessWidget {

  final String title;
  final String nominal;
  final String status;
  final String tanggal;

  const RiwayatItem({
    super.key,
    required this.title,
    required this.nominal,
    required this.status,
    required this.tanggal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.receipt_long),
        ),
        title: Text(title),
        subtitle: Text(tanggal),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nominal,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                color: status == "Berhasil"
                    ? Colors.green
                    : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
