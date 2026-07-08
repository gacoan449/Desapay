import 'package:flutter/material.dart';

class BannerPromo extends StatelessWidget {
  const BannerPromo({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(
      height: 140,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Colors.blue,
            Colors.lightBlue,
          ],
        ),
      ),

      child: const Center(
        child: Text(
          "PROMO DESAPAY\nPulsa • Paket • PLN",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
