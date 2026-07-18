import 'package:flutter/material.dart';

import '../../config/warna.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final emailController = TextEditingController();
  final AuthService auth = AuthService();

  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {

    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Masukkan email terlebih dahulu"),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final hasil = await auth.forgotPassword(
      emailController.text.trim(),
    );

    setState(() {
      loading = false;
    });

    if (!mounted) return;

    if (hasil == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Link reset password berhasil dikirim.",
          ),
        ),
      );

      Navigator.pop(context);

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasil),
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg, // PERBAIKAN: Menggunakan lightBg

      appBar: AppBar(
        title: const Text("Lupa Password"),
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(

          children: [

            const SizedBox(height: 30),

            const Icon(
              Icons.lock_reset,
              size: 80,
              color: WarnaDesaPay.primary, // Penyesuaian estetik ke warna utama aplikasi
            ),

            const SizedBox(height: 20),

            const Text(
              "Reset Password",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: WarnaDesaPay.textMain,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Masukkan email yang terdaftar untuk menerima link reset password.",
              textAlign: TextAlign.center,
              style: TextStyle(color: WarnaDesaPay.textSub),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WarnaDesaPay.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: loading ? null : resetPassword,
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        "KIRIM LINK RESET",
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
