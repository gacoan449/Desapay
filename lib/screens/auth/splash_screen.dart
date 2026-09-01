import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/warna.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService auth = AuthService();

  @override
  void initState() {
    super.initState();
    mulai();
  }

  Future<void> mulai() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = auth.currentUser;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user != null ? const BottomNav() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 90),
            const SizedBox(height: 20),
            const Text(
              "DesaPay",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Aplikasi PPOB Modern", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
