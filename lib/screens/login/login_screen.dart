import 'package:flutter/material.dart';

import '../../config/warna.dart';
import '../../services/auth_service.dart';

// Import Navigasi Pengguna Biasa & Admin
import '../../widgets/bottom_nav.dart'; 
import '../admin/admin_dashboard_screen.dart'; // Pastikan path folder admin ini sudah sesuai

import '../auth/forgot_password_screen.dart';
import '../auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService auth = AuthService();

  bool loading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final emailInput = emailController.text.trim();
    final passwordInput = passwordController.text.trim();

    if (emailInput.isEmpty || passwordInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email dan password wajib diisi"),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final hasil = await auth.login(
      email: emailInput,
      password: passwordInput,
    );

    setState(() {
      loading = false;
    });

    if (!mounted) return;

    if (hasil == null) {
      // --- LOGIKA PEMISAH AKUN (ROLE-BASED ACCESS CONTROL) ---
      if (emailInput.toLowerCase() == "annisaulinayah55@gmail.com") {
        // JIKA ADMIN: Lempar ke Command Center (Dashboard Khusus Admin)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboardScreen(),
          ),
        );
      } else {
        // JIKA USER BIASA: Lempar ke BottomNav Utama DesaPay
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BottomNav(),
          ),
        );
      }
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
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [

              const SizedBox(height: 40),

              const Icon(
                Icons.account_balance_wallet,
                size: 90,
                color: WarnaDesaPay.primary,
              ),

              const SizedBox(height: 20),

              const Text(
                "DesaPay",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const Text(
                "Masuk ke akun Anda",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                  prefixIcon: const Icon(Icons.email, color: WarnaDesaPay.primary),
                  floatingLabelStyle: const TextStyle(color: WarnaDesaPay.primary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.black26, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: WarnaDesaPay.primary, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                  prefixIcon: const Icon(Icons.lock, color: WarnaDesaPay.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: WarnaDesaPay.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                  floatingLabelStyle: const TextStyle(color: WarnaDesaPay.primary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.black26, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: WarnaDesaPay.primary, width: 2),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Lupa Password?",
                    style: TextStyle(
                      color: WarnaDesaPay.primary, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarnaDesaPay.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text("MASUK"),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: WarnaDesaPay.primary, width: 1.5),
                    foregroundColor: WarnaDesaPay.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  child: const Text("DAFTAR AKUN"),
                ),
              ),

              const SizedBox(height: 30),

              const Divider(color: Colors.black12, thickness: 1),

              const SizedBox(height: 20),

              const Text(
                "Butuh Bantuan?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "WhatsApp: 085642131263",
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
              ),

              const Text(
                "Email: gacoan449@gmail.com",
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
