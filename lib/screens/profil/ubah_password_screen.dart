import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/auth_service.dart';

class UbahPasswordScreen extends StatefulWidget {
  const UbahPasswordScreen({super.key});

  @override
  State<UbahPasswordScreen> createState() => _UbahPasswordScreenState();
}

class _UbahPasswordScreenState extends State<UbahPasswordScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _passwordLamaController =
      TextEditingController();

  final TextEditingController _passwordBaruController =
      TextEditingController();

  final TextEditingController _konfirmasiController =
      TextEditingController();

  bool _obscureLama = true;
  bool _obscureBaru = true;
  bool _obscureKonfirmasi = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordLamaController.dispose();
    _passwordBaruController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  // ============================================================
  // PROSES UBAH PASSWORD
  // ============================================================
  Future<void> _ubahPassword() async {
    final passwordLama = _passwordLamaController.text.trim();
    final passwordBaru = _passwordBaruController.text.trim();
    final konfirmasi = _konfirmasiController.text.trim();

    if (passwordLama.isEmpty ||
        passwordBaru.isEmpty ||
        konfirmasi.isEmpty) {
      _showMessage("Semua kolom kata sandi wajib diisi.");
      return;
    }

    if (passwordBaru.length < 6) {
      _showMessage(
        "Kata sandi baru minimal 6 karakter.",
      );
      return;
    }

    if (passwordBaru != konfirmasi) {
      _showMessage(
        "Konfirmasi kata sandi baru tidak cocok.",
      );
      return;
    }

    if (passwordLama == passwordBaru) {
      _showMessage(
        "Kata sandi baru harus berbeda dari kata sandi lama.",
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    final result = await _authService.changePassword(
      currentPassword: passwordLama,
      newPassword: passwordBaru,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (result != null) {
      _showMessage(result);
      return;
    }

    // Berhasil
    _passwordLamaController.clear();
    _passwordBaruController.clear();
    _konfirmasiController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Kata sandi berhasil diubah.",
        ),
      ),
    );

    Navigator.pop(context);
  }

  // ============================================================
  // PESAN ERROR
  // ============================================================
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // INPUT PASSWORD
  // ============================================================
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: !_loading,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: WarnaDesaPay.lightField,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: WarnaDesaPay.lightField,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: WarnaDesaPay.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        title: const Text(
          "Ubah Kata Sandi",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ========================================================
          // HEADER
          // ========================================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: WarnaDesaPay.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.security_rounded,
                  color: WarnaDesaPay.primary,
                  size: 26,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Untuk keamanan akun, masukkan kata sandi lama sebelum membuat kata sandi baru.",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: WarnaDesaPay.textSub,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ========================================================
          // PASSWORD LAMA
          // ========================================================
          _passwordField(
            controller: _passwordLamaController,
            label: "Kata Sandi Lama",
            obscureText: _obscureLama,
            onToggle: () {
              setState(() {
                _obscureLama = !_obscureLama;
              });
            },
          ),

          const SizedBox(height: 16),

          // ========================================================
          // PASSWORD BARU
          // ========================================================
          _passwordField(
            controller: _passwordBaruController,
            label: "Kata Sandi Baru",
            obscureText: _obscureBaru,
            onToggle: () {
              setState(() {
                _obscureBaru = !_obscureBaru;
              });
            },
          ),

          const SizedBox(height: 16),

          // ========================================================
          // KONFIRMASI PASSWORD
          // ========================================================
          _passwordField(
            controller: _konfirmasiController,
            label: "Konfirmasi Kata Sandi Baru",
            obscureText: _obscureKonfirmasi,
            onToggle: () {
              setState(() {
                _obscureKonfirmasi = !_obscureKonfirmasi;
              });
            },
          ),

          const SizedBox(height: 24),

          // ========================================================
          // TOMBOL SIMPAN
          // ========================================================
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _ubahPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: WarnaDesaPay.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "SIMPAN KATA SANDI",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
