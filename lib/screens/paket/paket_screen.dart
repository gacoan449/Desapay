import 'package:flutter/material.dart';

import '../../config/warna.dart';

class PaketScreen extends StatelessWidget {
  const PaketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final paket = [
      "1 GB",
      "2 GB",
      "5 GB",
      "10 GB",
      "20 GB",
      "30 GB",
      "50 GB",
      "Unlimited",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Paket Data"),
      ),
      backgroundColor: WarnaDesaPay.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Masukkan Nomor HP",
                prefixIcon: const Icon(Icons.phone_android),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.builder(
                itemCount: paket.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2,
                ),
                itemBuilder: (context, index) {
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${paket[index]} dipilih"),
                          ),
                        );
                      },
                      child: Center(
                        child: Text(
                          paket[index],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
