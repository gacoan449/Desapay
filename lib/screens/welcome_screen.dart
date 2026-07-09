import 'package:flutter/material.dart';
import '../../config/warna.dart';
import 'home/home_screen.dart'; // Menuju ke halaman dashboard utama ala DANA Anda

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // 1. WIDGET TAMPILAN LOGO UTAMA DESAPAY MEWAH
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      spreadRadius: 4,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    // Memanggil nama file gambar persis sesuai yang ada di pubspec.yaml Anda
                    'ChatGPT Image 8 Jul 2026, 22.03.40.png',
                    height: 140, 
                    width: 140,  
                    fit: Alignment.center,
                    // Fitur pengaman: Jika gambar tersangkut / belum sinkron, layar tidak akan memerah/error
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 90,
                        color: Colors.blue,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 2. TEKS JUDUL DAN JARGON KEAGENAN
              const Text(
                "Selamat Datang di DesaPay",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              const Text(
                "Solusi terbaik loket pembayaran digital, pulsa, dan tagihan PPOB modern. Mudah digunakan, aman, dan tepercaya untuk kemajuan ekonomi desa.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // 3. TOMBOL UTAMA UNTUK MASUK KE BERANDA JUALAN
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarnaDesaPay.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () {
                    // Masuk langsung ke HomeScreen (Dashboard DANA) dan hapus halaman welcome dari memori HP
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "MULAI JUALAN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
