import 'package:flutter/material.dart';

import '../../config/warna.dart';

class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: const [

          RiwayatItem(
            layanan: "Pulsa Telkomsel",
            tujuan: "081234567890",
            nominal: "Rp10.000",
            status: "Berhasil",
            warna: Colors.green,
          ),

          RiwayatItem(
            layanan: "Token PLN",
            tujuan: "1234567890",
            nominal: "Rp50.000",
            status: "Berhasil",
            warna: Colors.green,
          ),

          RiwayatItem(
            layanan: "Top Up DANA",
            tujuan: "081298765432",
            nominal: "Rp20.000",
            status: "Diproses",
            warna: Colors.orange,
          ),

        ],
      ),
    );
  }
}

class RiwayatItem extends StatelessWidget {

  final String layanan;
  final String tujuan;
  final String nominal;
  final String status;
  final Color warna;

  const RiwayatItem({
    super.key,
    required this.layanan,
    required this.tujuan,
    required this.nominal,
    required this.status,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: warna,
          child: const Icon(
            Icons.receipt_long,
            color: Colors.white,
          ),
        ),

        title: Text(layanan),

        subtitle: Text(
          "$tujuan\n$nominal",
        ),

        trailing: Text(
          status,
          style: TextStyle(
            color: warna,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
