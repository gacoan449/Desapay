import 'package:flutter/material.dart';

import '../../config/warna.dart';

class KonfirmasiPembayaranScreen extends StatelessWidget {
  final String nomor;
  final String produk;
  final int harga;

  const KonfirmasiPembayaranScreen({
    super.key,
    required this.nomor,
    required this.produk,
    required this.harga,
  });

  @override
  Widget build(BuildContext context) {

    const admin = 1500;
    final total = harga + admin;

    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Konfirmasi Pembayaran"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            Card(
              child: Column(

                children: [

                  ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: const Text("Nomor Tujuan"),
                    subtitle: Text(nomor),
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: const Text("Produk"),
                    subtitle: Text(produk),
                  ),

                  const Divider(),

                  ListTile(
                    title: const Text("Harga"),
                    trailing: Text("Rp $harga"),
                  ),

                  ListTile(
                    title: const Text("Biaya Admin"),
                    trailing: const Text("Rp 1.500"),
                  ),

                  const Divider(),

                  ListTile(
                    title: const Text(
                      "Total Pembayaran",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    trailing: Text(
                      "Rp $total",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),

                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text("BAYAR SEKARANG"),

                onPressed: () {

                  ScaffoldMessenger.of(context).showSnackBar(

                    const SnackBar(
                      content: Text(
                        "Tahap berikutnya akan terhubung ke Tripay.",
                      ),
                    ),

                  );

                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}
