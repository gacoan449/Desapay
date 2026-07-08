import 'package:flutter/material.dart';

import '../../config/warna.dart';
import '../../models/transaksi.dart';
import '../../services/transaksi_service.dart';

class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Transaksi> data = TransaksiService.semua();

    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
      ),

      body: data.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 15),

                  Text(
                    "Belum ada transaksi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "Silakan lakukan transaksi pertama.",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                ],
              ),
            )

          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,

              itemBuilder: (context, index) {

                final item = data[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),

                  child: ListTile(

                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt),
                    ),

                    title: Text(item.produk),

                    subtitle: Text(
                      "${item.tujuan}\nRp ${item.harga}",
                    ),

                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Text(
                          item.status,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      ],
                    ),

                  ),
                );
              },
            ),
    );
  }
}
