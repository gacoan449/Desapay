import 'package:flutter/material.dart';

import 'konfirmasi_pulsa_screen.dart';

class PilihNominalScreen extends StatelessWidget {
  final String nomor;

  const PilihNominalScreen({
    super.key,
    required this.nomor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Nominal"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),

        children: [

          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text("Pulsa 5.000"),
              subtitle: const Text("Harga Rp6.500"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KonfirmasiPulsaScreen(
                      nomor: nomor,
                      nominal: "5.000",
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text("Pulsa 10.000"),
              subtitle: const Text("Harga Rp11.500"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KonfirmasiPulsaScreen(
                      nomor: nomor,
                      nominal: "10.000",
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text("Pulsa 20.000"),
              subtitle: const Text("Harga Rp21.500"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KonfirmasiPulsaScreen(
                      nomor: nomor,
                      nominal: "20.000",
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text("Pulsa 50.000"),
              subtitle: const Text("Harga Rp51.000"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KonfirmasiPulsaScreen(
                      nomor: nomor,
                      nominal: "50.000",
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text("Pulsa 100.000"),
              subtitle: const Text("Harga Rp100.500"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KonfirmasiPulsaScreen(
                      nomor: nomor,
                      nominal: "100.000",
                    ),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}
