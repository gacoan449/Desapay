import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/security_service.dart';

class KeamananScreen extends StatefulWidget {
  const KeamananScreen({super.key});

  @override
  State<KeamananScreen> createState() => _KeamananScreenState();
}

class _KeamananScreenState extends State<KeamananScreen> {
  final SecurityService _securityService = SecurityService();

  bool _biometricEnabled = false;
  bool _loadingBiometric = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  // ============================================================
  // MEMUAT STATUS BIOMETRIK
  // ============================================================
  Future<void> _loadBiometricStatus() async {
    final enabled = await _securityService.isBiometricEnabled();

    if (!mounted) return;

    setState(() {
      _biometricEnabled = enabled;
      _loadingBiometric = false;
    });
  }

  // ============================================================
  // AKTIFKAN / NONAKTIFKAN BIOMETRIK
  // ============================================================
  Future<void> _toggleBiometric(bool value) async {
    if (_loadingBiometric) return;

    // ==========================================================
    // AKTIFKAN
    // ==========================================================
    if (value) {
      setState(() {
        _loadingBiometric = true;
      });

      final available =
          await _securityService.isBiometricAvailable();

      if (!available) {
        if (!mounted) return;

        setState(() {
          _loadingBiometric = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometrik tidak tersedia atau belum diatur pada perangkat ini.',
            ),
          ),
        );

        return;
      }

      final success = await _securityService.enableBiometric();

      if (!mounted) return;

      setState(() {
        _biometricEnabled = success;
        _loadingBiometric = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Login biometrik berhasil diaktifkan.'
                : 'Verifikasi biometrik gagal.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // NONAKTIFKAN
    // ==========================================================
    setState(() {
      _loadingBiometric = true;
    });

    await _securityService.disableBiometric();

    if (!mounted) return;

    setState(() {
      _biometricEnabled = false;
      _loadingBiometric = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login biometrik telah dinonaktifkan.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        title: const Text(
          "Keamanan Akun",
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: WarnaDesaPay.lightField,
              ),
            ),
            child: Column(
              children: [
                // ==================================================
                // UBAH PIN TRANSAKSI
                // ==================================================
                ListTile(
                  leading: const Icon(
                    Icons.pin_rounded,
                    color: WarnaDesaPay.primary,
                  ),
                  title: const Text(
                    "Ubah PIN Transaksi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    "6 digit angka rahasia",
                    style: TextStyle(
                      fontSize: 12,
                      color: WarnaDesaPay.textSub,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: () {},
                ),

                const Divider(
                  height: 1,
                  indent: 50,
                  color: WarnaDesaPay.lightField,
                ),

                // ==================================================
                // UBAH KATA SANDI
                // ==================================================
                ListTile(
                  leading: const Icon(
                    Icons.lock_rounded,
                    color: WarnaDesaPay.primary,
                  ),
                  title: const Text(
                    "Ubah Kata Sandi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    "Untuk login ke aplikasi",
                    style: TextStyle(
                      fontSize: 12,
                      color: WarnaDesaPay.textSub,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: () {},
                ),

                const Divider(
                  height: 1,
                  indent: 50,
                  color: WarnaDesaPay.lightField,
                ),

                // ==================================================
                // LOGIN BIOMETRIK
                // ==================================================
                SwitchListTile(
                  value: _biometricEnabled,
                  activeColor: WarnaDesaPay.primary,
                  secondary: _loadingBiometric
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.fingerprint_rounded,
                          color: WarnaDesaPay.primary,
                        ),
                  title: const Text(
                    "Login Biometrik",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    "Gunakan Sidik Jari / Face ID",
                    style: TextStyle(
                      fontSize: 12,
                      color: WarnaDesaPay.textSub,
                    ),
                  ),
                  onChanged: _loadingBiometric
                      ? null
                      : _toggleBiometric,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
