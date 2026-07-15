import 'dart:async';
import 'package:flutter/material.dart';

import '../../config/warna.dart';
import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer; // REVISI SAFETY: Penjaga pointer untuk mencegah memory leak

  @override
  void initState() {
    super.initState();

    // Mengunci alur transisi aman terkendali
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return; // Mencegah perpindahan halaman jika widget sudah dilepas
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Mematikan background timer saat splash screen ditutup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gradasi Biru Mewah Selaras dengan Dashboard Luxury DesaPay
    final LinearGradient premiumSplashGradient = LinearGradient(
      colors: [
        WarnaDesaPay.primary,
        const Color(0xFF007BE6),
        const Color(0xFF0086FF),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: premiumSplashGradient,
        ),
        child: Stack(
          children: [
            // KONTEN UTAMA SPLASH CENTERED LOGO
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Aksen Berpendar Mewah
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "DesaPay",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Premium Digital Payment Platform",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Loading Indicator Lembut
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // ORNAMEN FOOTER UNTUK VISUAL MEWAH
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Icon(
                    Icons.shield_rounded, 
                    size: 18, 
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Secured Network Infrastructure",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
