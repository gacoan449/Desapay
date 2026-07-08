import 'package:flutter/material.dart';

import '../../config/warna.dart';

class PulsaScreen extends StatelessWidget {
  const PulsaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nominal = [
      "5.000",
      "10.000",
      "15.000",
      "20.000",
      "25.000",
      "30.000",
      "50.000",
      "100.000",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pulsa"),
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
                itemCount: nominal.length,
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
                            content: Text(
                              "Pulsa Rp ${nominal[index]} dipilih",
                            ),
                          ),
                        );
                      },
                      child: Center(
                        child: Text(
                          "Rp ${nominal[index]}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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
