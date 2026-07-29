import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/warna.dart';

// ✅ PERBAIKAN 1: Import BottomNav, buang import HomeScreen
import '../../widgets/bottom_nav.dart'; // Sesuaikan path ini jika posisi file bottom_nav.dart Anda berbeda
import '../welcome_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      // LOGIKA PENJAGA KELAS BERAT: Cek status login setelah animasi selesai
      final User? user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // ✅ PERBAIKAN 2: Jika sudah login, lempar ke BottomNav (agar menu bawah muncul)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNav()),
        );
      } else {
        // Jika belum login, lempar ke Welcome Screen (sesuai alur UI Anda)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        decoration: BoxDecoration(gradient: premiumSplashGradient),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "DesaPay",
                    style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Premium Digital Payment Platform",
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 48),
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                ],
              ),
            ),
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: Column(
                children: [
                  Icon(Icons.shield_rounded, size: 18, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 6),
                  Text("Secured Network Infrastructure", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
