import 'package:flutter/material.dart';

import '../../config/warna.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav.dart';

class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

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
        const SnackBar(content: Text("Masukkan 6 digit kode OTP")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final credential = await auth.signInWithPhoneNumber(
        verificationId: widget.phone,
        smsCode: otpController.text.trim(),
      );

      if (!mounted) return;
      setState(() => loading = false);

      if (credential?.user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BottomNav()),
          (route) => false,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kode OTP salah atau sudah kedaluwarsa")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(title: const Text("Verifikasi OTP")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.sms, color: Colors.blue, size: 90),
            const SizedBox(height: 20),
            const Text("Masukkan Kode OTP", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Kode dikirim ke\n${widget.phone}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "------",
                counterText: "",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : verifikasi,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("VERIFIKASI"),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                try {
                  await auth.verifyPhoneNumber(
                    phoneNumber: widget.phone,
                    verificationCompleted: (_) {},
                    verificationFailed: (_) {},
                    codeSent: (_, __) {},
                    codeAutoRetrievalTimeout: (_) {},
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kode OTP dikirim ulang")),
                  );
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal mengirim ulang OTP")),
                  );
                }
              },
              child: const Text("Kirim Ulang OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
