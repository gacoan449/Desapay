import 'package:flutter/material.dart';

import '../../bottom_nav.dart';
import '../../config/warna.dart';
import '../../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({
    super.key,
    required this.phone,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final otpController = TextEditingController();

  final AuthService auth = AuthService();

  bool loading = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> verifikasi() async {
    if (otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Masukkan 6 digit kode OTP"),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final berhasil = await auth.verifyOtp(
      otpController.text.trim(),
    );

    setState(() {
      loading = false;
    });

    if (!mounted) return;

    if (berhasil) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const BottomNav(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kode OTP salah"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: const Text("Verifikasi OTP"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            const SizedBox(height: 20),

            const Icon(
              Icons.sms,
              color: Colors.blue,
              size: 90,
            ),

            const SizedBox(height: 20),

            const Text(
              "Masukkan Kode OTP",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Kode dikirim ke\n${widget.phone}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "------",
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : verifikasi,
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        "VERIFIKASI",
                      ),
              ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () async {
                await auth.sendOtp(widget.phone);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Kode OTP dikirim ulang",
                    ),
                  ),
                );
              },
              child: const Text(
                "Kirim Ulang OTP",
              ),
            ),

          ],
        ),
      ),
    );
  }
}
