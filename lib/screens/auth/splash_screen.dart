import 'dart:async';

import 'package:flutter/material.dart';

import '../../bottom_nav.dart';
import '../../config/warna.dart';
import '../../services/auth_service.dart';
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

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    final user = await auth.currentUser();

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BottomNav(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: WarnaDesaPay.primary,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [

            Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 90,
            ),

            SizedBox(height: 20),

            Text(
              "DesaPay",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Aplikasi PPOB Modern",
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            SizedBox(height: 40),

            CircularProgressIndicator(
              color: Colors.white,
            ),

          ],
        ),
      ),
    );
  }
}
