import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import Konfigurasi, Widget Reusable, dan Halaman Login (CTO Standard)
import '../../config/warna.dart';
import '../../widgets/menu_item.dart'; // Menggunakan CustomBounce dari standarisasi sebelumnya
import '../login/login_screen.dart'; 

/// Widget Tampilan Profil & Pengaturan Akun Premium Pengguna DesaPay (Presentation Layer)
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  /// Menampilkan Pop-up Dialog Konfirmasi Keluar dengan Gaya Fintek Modern
  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: WarnaDesaPay.danger, size: 26),
            SizedBox(width: 10),
            Text(
              "Keluar Akun", 
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: WarnaDesaPay.textMain)
            ),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari sesi aktif aplikasi DesaPay?",
          style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: WarnaDesaPay.textSub, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WarnaDesaPay.danger,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog konfirmasi
              await FirebaseAuth.instance.signOut(); // Pemutusan token sesi Firebase Auth
              
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false, // Membersihkan total seluruh tumpukan navigasi di memori
                );
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false, // Menghilangkan tombol back default pada tab menu utama
        title: const Text(
          "Profil Premium",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          // =========================================================================
          // 1. KARTU IDENTITAS USER (FINTECH GOLD SHINE STYLE)
          // =========================================================================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WarnaDesaPay.lightCard,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: WarnaDesaPay.shadow.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: WarnaDesaPay.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 32,
                    backgroundColor: WarnaDesaPay.primary,
                    // PERBAIKAN: Menghapus hardcoded NetworkImage menjadi Icon default yang elegan
                    child: Icon(Icons.person_rounded, size: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? "Agen DesaPay",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: WarnaDesaPay.textMain),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.phoneNumber ?? user?.email ?? "Kontak belum terverifikasi",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      
                      // Badge Premium Member dengan Aksen Amber Halus
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: WarnaDesaPay.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: WarnaDesaPay.warning.withOpacity(0.3), width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_rounded, color: WarnaDesaPay.warning, size: 12),
                            SizedBox(width: 4),
                            Text(
                              "Premium Member", 
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: WarnaDesaPay.warning, letterSpacing: 0.3)
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 28),

          // =========================================================================
          // 2. KELOMPOK MENU: KEAMANAN LENGKAP
          // =========================================================================
          const Text("Pengaturan Keamanan", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: WarnaDesaPay.textSub, letterSpacing: 0.3)),
          const SizedBox(height: 12),
          _buildMenuRow(Icons.lock_outline_rounded, "Ubah PIN Transaksi", () {
            // TODO: Integrasikan ke layar pembaruan PIN di tahap selanjutnya
          }),
          _buildMenuRow(Icons.fingerprint_rounded, "Keamanan Biometrik", () {}),
          _buildMenuRow(Icons.verified_user_outlined, "Verifikasi KTP (KYC)", () {}),
          
          const SizedBox(height: 24),
          
          // =========================================================================
          // 3. KELOMPOK MENU: BANTUAN OPERASIONAL
          // =========================================================================
          const Text("Pusat Bantuan", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: WarnaDesaPay.textSub, letterSpacing: 0.3)),
          const SizedBox(height: 12),
          _buildMenuRow(Icons.help_outline_rounded, "Syarat & Ketentuan Layanan", () {}),
          _buildMenuRow(Icons.headset_mic_rounded, "Hubungi CS (WhatsApp Aktif)", () {}),

          const SizedBox(height: 36),
          
          // =========================================================================
          // 4. TOMBOL KELUAR APLIKASI (TACTILE CRASH-FREE METHOD)
          // =========================================================================
          CustomBounce(
            onTap: () => _logout(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: WarnaDesaPay.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WarnaDesaPay.danger.withOpacity(0.15), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: WarnaDesaPay.danger, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Keluar Aplikasi", 
                    style: TextStyle(color: WarnaDesaPay.danger, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.2)
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100), // Buffer aman agar ujung bawah tidak terpotong oleh sistem navigasi
        ],
      ),
    );
  }

  /// Pembangun baris menu individual yang terintegrasi penuh dengan CustomBounce
  Widget _buildMenuRow(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CustomBounce(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: WarnaDesaPay.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WarnaDesaPay.lightField, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WarnaDesaPay.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: WarnaDesaPay.primary, size: 20),
            ),
            title: Text(
              title, 
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: WarnaDesaPay.textMain)
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: WarnaDesaPay.textSub),
          ),
        ),
      ),
    );
  }
}
