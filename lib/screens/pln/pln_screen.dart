import 'package:flutter/material.dart';

import '../../config/warna.dart';

class PlnScreen extends StatelessWidget {
  const PlnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PLN"),
      ),
      backgroundColor: WarnaDesaPay.background,

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.flash_on,
                  color: Colors.orange,
                ),
                title: const Text("Token PLN"),
                subtitle: const Text("Beli token listrik prabayar"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Menu Token PLN"),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.receipt_long,
                  color: Colors.blue,
                ),
                title: const Text("Tagihan PLN"),
                subtitle: const Text("Bayar listrik pascabayar"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Menu Tagihan PLN"),
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
