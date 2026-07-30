import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/warna.dart';
import '../../widgets/menu_item.dart'; // Untuk CustomBounce
import '../login/login_screen.dart'; 
import 'edit_profil_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  
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
            Text("Keluar Akun", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: WarnaDesaPay.textMain)),
          ],
        ),
        content: const Text("Apakah Anda yakin ingin keluar dari sesi aktif aplikasi DesaPay?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: WarnaDesaPay.textSub, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: WarnaDesaPay.danger, elevation: 0),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false,
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HEADER GRADIENT MEWAH
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            backgroundColor: WarnaDesaPay.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [WarnaDesaPay.primary, Color(0xFF1E40AF), WarnaDesaPay.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Profil Pengguna",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 20),
                      // FOTO PROFIL DENGAN RING EMAS/PUTIH GLOW
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: const CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person_rounded, size: 50, color: WarnaDesaPay.primary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle), // Aksen Gold VIP
                            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // KONTEN UTAMA HALAMAN PROFIL
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KARTU IDENTITAS UTAMA
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Column(
                      children: [
                        Text(
                          user?.displayName ?? "Member DesaPay",
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: WarnaDesaPay.textMain),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.phoneNumber ?? user?.email ?? "Belum terverifikasi",
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: WarnaDesaPay.lightField, height: 1),
                        const SizedBox(height: 16),
                        
                        // TOMBOL UBAH PROFIL & KTP
                        SizedBox(
                          width: double.infinity,
                          child: CustomBounce(
                            onTap: () async {
                              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilScreen()));
                              if (result == true) setState(() {}); 
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: WarnaDesaPay.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: WarnaDesaPay.primary.withOpacity(0.2), width: 1),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_rounded, color: WarnaDesaPay.primary, size: 16),
                                  SizedBox(width: 8),
                                  Text("Ubah Profil & Verifikasi KTP", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: WarnaDesaPay.primary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // SEKSI MENU PENGATURAN & KEAMANAN
                  const Text("Pengaturan & Keamanan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: WarnaDesaPay.textSub)),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _buildMenuTile(Icons.security_rounded, "Keamanan Akun", "PIN Transaksi & Biometrik", () {}),
                        const Divider(height: 1, indent: 56, color: WarnaDesaPay.lightField),
                        _buildMenuTile(Icons.headset_mic_rounded, "Pusat Bantuan CS", "Layanan Pelanggan 24/7", () {}),
                        const Divider(height: 1, indent: 56, color: WarnaDesaPay.lightField),
                        _buildMenuTile(Icons.info_outline_rounded, "Tentang Aplikasi", "DesaPay v1.0.0 (Production)", () {}),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32), 
                  
                  // TOMBOL KELUAR APLIKASI
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
                          Text("Keluar Aplikasi", style: TextStyle(color: WarnaDesaPay.danger, fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pendukung untuk menu list yang rapi
  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: WarnaDesaPay.primary.withOpacity(0.08), shape: BoxShape.circle),
        child: Icon(icon, color: WarnaDesaPay.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: WarnaDesaPay.textMain)),
      subtitle: Text(subtitle, style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 11, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: WarnaDesaPay.textSub),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
