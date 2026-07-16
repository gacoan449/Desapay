import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Sesuaikan import dengan struktur folder Anda
import '../../config/warna.dart';
import '../login/login_screen.dart'; 

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar Akun", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin ingin keluar dari DesaPay?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog
              await FirebaseAuth.instance.signOut(); // Proses hapus sesi Firebase
              
              // Lempar user kembali ke halaman Login dengan aman
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil data user yang sedang login saat ini (jika ada)
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      appBar: AppBar(
        title: const Text("Profil Premium"),
        backgroundColor: const Color(0xFF0054A6),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Menghilangkan tombol back default jika ada
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          // KARTU IDENTITAS USER (Tampil meskipun data di database kosong)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey,
                  backgroundImage: NetworkImage("https://i.pravatar.cc/150"),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? "Agen DesaPay",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        user?.phoneNumber ?? user?.email ?? "Belum ada kontak terdaftar",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("Premium Member", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 30),

          // MENU SETTINGS
          const Text("Pengaturan Keamanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 10),
          _buildMenu(Icons.lock_outline_rounded, "Ubah PIN", () {}),
          _buildMenu(Icons.fingerprint_rounded, "Biometrik", () {}),
          _buildMenu(Icons.verified_user_outlined, "Verifikasi KTP (KYC)", () {}),
          
          const SizedBox(height: 20),
          const Text("Pusat Bantuan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 10),
          _buildMenu(Icons.help_outline_rounded, "Syarat & Ketentuan", () {}),
          _buildMenu(Icons.headset_mic_rounded, "Hubungi CS (WhatsApp)", () {}),

          const SizedBox(height: 40),
          
          // TOMBOL LOGOUT UNTUK MEMANGGIL LOGIN SCREEN
          ElevatedButton.icon(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: const Text("Keluar Aplikasi", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () => _logout(context),
          ),
          const SizedBox(height: 80), // Buffer agar tidak tertutup bottom nav
        ],
      ),
    );
  }

  Widget _buildMenu(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0054A6)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
