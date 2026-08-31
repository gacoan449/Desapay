// =====================================================================
// FILE: lib/screens/login/login_screen.dart
// =====================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/warna.dart';
import '../../services/auth_service.dart';

// Import tetap dipertahankan agar struktur proyek tidak berubah.
import '../../widgets/bottom_nav.dart';
import '../admin/admin_dashboard_screen.dart';

import '../auth/forgot_password_screen.dart';
import '../auth/register_screen.dart';

// =====================================================================
// LOGIN SCREEN
// =====================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// =====================================================================
// LOGIN STATE
// =====================================================================

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  final AuthService auth = AuthService();

  bool loading = false;

  bool hidePassword = true;

  // ===================================================================
  // DISPOSE
  // ===================================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ===================================================================
  // LOGIN
  // ===================================================================

  Future<void> login() async {
    final emailInput = emailController.text.trim();

    final passwordInput = passwordController.text.trim();

    // ===============================================================
    // VALIDASI INPUT
    // ===============================================================

    if (emailInput.isEmpty || passwordInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Email dan password wajib diisi",
          ),
        ),
      );

      return;
    }

    if (loading) {
      return;
    }

    // ===============================================================
    // START LOADING
    // ===============================================================

    setState(() {
      loading = true;
    });

    // ===============================================================
    // LOGIN FIREBASE
    // ===============================================================
    //
    // AuthService adalah satu-satunya tempat untuk proses login.
    //
    // AuthService.login() menggunakan:
    //
    // FirebaseAuth.signInWithEmailAndPassword()
    //
    // ===============================================================

    final hasil = await auth.login(
      email: emailInput,
      password: passwordInput,
    );

    if (!mounted) {
      return;
    }

    // ===============================================================
    // LOGIN GAGAL
    // ===============================================================

    if (hasil != null) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasil),
        ),
      );

      return;
    }

    // ===============================================================
    // LOGIN BERHASIL
    // ===============================================================
    //
    // Routing utama tetap ditangani oleh:
    //
    // lib/main.dart
    //
    // melalui:
    //
    // FirebaseAuth.authStateChanges()
    //
    // USER  -> BottomNav
    // ADMIN -> AdminDashboard
    //
    // LoginScreen tidak melakukan Navigator ke dashboard
    // agar tidak terjadi double-router.
    //
    // ===============================================================

    try {
      final User? user = FirebaseAuth.instance.currentUser;

      // -------------------------------------------------------------
      // SESSION TIDAK DITEMUKAN
      // -------------------------------------------------------------

      if (user == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Login gagal. Sesi pengguna tidak ditemukan.',
            ),
          ),
        );

        return;
      }

      debugPrint(
        '✅ Firebase login berhasil: ${user.email}',
      );

      debugPrint(
        '✅ Firebase UID: ${user.uid}',
      );

      // -------------------------------------------------------------
      // VERIFIKASI RINGAN DATA USER
      // -------------------------------------------------------------
      //
      // Pengecekan akun sebenarnya dilakukan oleh main.dart.
      //
      // Di sini kita hanya memastikan currentUser Firebase
      // benar-benar tersedia setelah login.
      //
      // -------------------------------------------------------------

      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
      });

      // =============================================================
      // SELESAI
      // =============================================================
      //
      // Tidak ada Navigator.push di sini.
      // authStateChanges() di main.dart akan memicu routing.
      //
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
      });

      debugPrint(
        '❌ Firebase login verification gagal: '
        '${e.code} - ${e.message}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Login berhasil tetapi sesi akun belum dapat diverifikasi.',
          ),
        ),
      );
    } catch (e, stackTrace) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
      });

      debugPrint(
        '❌ Login verification error: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Login berhasil, tetapi sesi akun belum dapat diverifikasi.',
          ),
        ),
      );
    }
  }

  // ===================================================================
  // BUILD
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(
                height: 40,
              ),

              // =======================================================
              // LOGO
              // =======================================================

              const Icon(
                Icons.account_balance_wallet,
                size: 90,
                color: WarnaDesaPay.primary,
              ),

              const SizedBox(
                height: 20,
              ),

              // =======================================================
              // TITLE
              // =======================================================

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

              const SizedBox(
                height: 40,
              ),

              // =======================================================
              // EMAIL
              // =======================================================

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                style: const TextStyle(
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(
                    Icons.email,
                    color: WarnaDesaPay.primary,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: WarnaDesaPay.primary,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.black26,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: WarnaDesaPay.primary,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) {
                  FocusScope.of(context).nextFocus();
                },
              ),

              const SizedBox(
                height: 20,
              ),

              // =======================================================
              // PASSWORD
              // =======================================================

              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(
                  color: Colors.black87,
                ),
                onSubmitted: (_) {
                  if (!loading) {
                    login();
                  }
                },
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock,
                    color: WarnaDesaPay.primary,
                  ),
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
                  floatingLabelStyle: const TextStyle(
                    color: WarnaDesaPay.primary,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.black26,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: WarnaDesaPay.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              // =======================================================
              // FORGOT PASSWORD
              // =======================================================

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ForgotPasswordScreen(),
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

              const SizedBox(
                height: 10,
              ),

              // =======================================================
              // LOGIN BUTTON
              // =======================================================

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarnaDesaPay.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        WarnaDesaPay.primary.withOpacity(0.55),
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "MASUK",
                        ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // =======================================================
              // REGISTER BUTTON
              // =======================================================

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: loading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const RegisterScreen(),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: WarnaDesaPay.primary,
                      width: 1.5,
                    ),
                    foregroundColor: WarnaDesaPay.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text(
                    "DAFTAR AKUN",
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // =======================================================
              // DIVIDER
              // =======================================================

              const Divider(
                color: Colors.black12,
                thickness: 1,
              ),

              const SizedBox(
                height: 20,
              ),

              // =======================================================
              // HELP
              // =======================================================

              const Text(
                "Butuh Bantuan?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                "WhatsApp: 085642131263",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Text(
                "Email: gacoan449@gmail.com",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
