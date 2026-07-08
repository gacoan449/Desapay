import 'package:flutter/material.dart';

import '../config/warna.dart';

class SaldoCard extends StatelessWidget {
  const SaldoCard({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: WarnaDesaPay.primary,
        borderRadius: BorderRadius.circular(20),
      ),

      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(
            "Saldo Anda",
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          SizedBox(height: 10),

          Text(
            "Rp 0",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          Text(
            "Member Silver",
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

        ],
      ),
    );
  }
}
