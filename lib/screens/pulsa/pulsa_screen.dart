import 'package:flutter/material.dart';

import '../../config/warna.dart';
import 'pilih_nominal_screen.dart';

class PulsaScreen extends StatefulWidget {
  const PulsaScreen({super.key});

  @override
  State<PulsaScreen> createState() => _PulsaScreenState();
}

class _PulsaScreenState extends State<PulsaScreen> {
  final TextEditingController nomorController = TextEditingController();

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

  @override
  void dispose() {
    nomorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Pulsa"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Nomor Tujuan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: nomorController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "08xxxxxxxxxx",
                prefixIcon: const Icon(Icons.phone_android),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Pilih Nominal",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 15),

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
                    elevation: 3,

                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),

                      onTap: () {

                        if (nomorController.text.isEmpty) {

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Masukkan nomor HP terlebih dahulu.",
                              ),
                            ),
                          );

                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PilihNominalScreen(
                              nomor: nomorController.text,
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
