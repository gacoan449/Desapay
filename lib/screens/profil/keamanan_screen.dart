import 'package:flutter/material.dart';
import '../../config/warna.dart';

class KeamananScreen extends StatelessWidget {
  const KeamananScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        title: const Text("Keamanan Akun", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: WarnaDesaPay.lightField)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.pin_rounded, color: WarnaDesaPay.primary),
                  title: const Text("Ubah PIN Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("6 digit angka rahasia", style: TextStyle(fontSize: 12, color: WarnaDesaPay.textSub)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 50, color: WarnaDesaPay.lightField),
                ListTile(
                  leading: const Icon(Icons.lock_rounded, color: WarnaDesaPay.primary),
                  title: const Text("Ubah Kata Sandi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Untuk login ke aplikasi", style: TextStyle(fontSize: 12, color: WarnaDesaPay.textSub)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 50, color: WarnaDesaPay.lightField),
                SwitchListTile(
                  value: true,
                  activeColor: WarnaDesaPay.primary,
                  secondary: const Icon(Icons.fingerprint_rounded, color: WarnaDesaPay.primary),
                  title: const Text("Login Biometrik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Gunakan Sidik Jari / Face ID", style: TextStyle(fontSize: 12, color: WarnaDesaPay.textSub)),
                  onChanged: (val) {},
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
