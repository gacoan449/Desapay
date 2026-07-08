import 'package:flutter/material.dart';

import '../../config/warna.dart';

class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Notifikasi"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: const [

          _NotifCard(
            icon: Icons.check_circle,
            color: Colors.green,
            title: "Transaksi Berhasil",
            subtitle: "Pulsa Telkomsel Rp20.000 berhasil diproses.",
            time: "Baru saja",
          ),

          _NotifCard(
            icon: Icons.account_balance_wallet,
            color: Colors.blue,
            title: "Saldo Bertambah",
            subtitle: "Top Up saldo Rp100.000 berhasil.",
            time: "10 menit lalu",
          ),

          _NotifCard(
            icon: Icons.local_offer,
            color: Colors.orange,
            title: "Promo Baru",
            subtitle: "Cashback hingga 10% untuk pembelian Token PLN.",
            time: "Hari ini",
          ),

          _NotifCard(
            icon: Icons.info,
            color: Colors.purple,
            title: "Informasi",
            subtitle: "Selamat datang di DesaPay versi Beta.",
            time: "Kemarin",
          ),

        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _NotifCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Text(
          time,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
