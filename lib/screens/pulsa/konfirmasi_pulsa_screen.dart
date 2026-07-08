import 'package:flutter/material.dart';

import '../../config/warna.dart';

class KonfirmasiPulsaScreen extends StatelessWidget {
  final String nomor;
  final String nominal;

  const KonfirmasiPulsaScreen({
    super.key,
    required this.nomor,
    required this.nominal,
  });

  @override
  Widget build(BuildContext context) {
    const int admin = 1500;

    final int harga =
        int.parse(nominal.replaceAll(".", ""));

    final int total = harga + admin;

    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Konfirmasi"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  children: [

                    ListTile(
                      leading: const Icon(Icons.phone_android),
                      title: const Text("Nomor Tujuan"),
                      subtitle: Text(nomor),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.bolt),
                      title: const Text("Nominal"),
                      subtitle: Text("Rp $nominal"),
                    ),

                    const Divider(),

                    ListTile(
                      title: const Text("Biaya Admin"),
                      trailing: const Text("Rp 1.500"),
                    ),

                    ListTile(
                      title: const Text(
                        "Total Bayar",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Text(
                        "Rp $total",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: () {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Fitur pembayaran Tripay segera dihubungkan.",
                      ),
                    ),
                  );

                },
                child: const Text(
                  "BAYAR SEKARANG",
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
