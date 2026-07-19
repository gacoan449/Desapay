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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text("Profil Premium", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          // KARTU PROFIL UTAMA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: WarnaDesaPay.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: const CircleAvatar(
                    radius: 36,
                    backgroundColor: WarnaDesaPay.primary,
                    child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? "Member DesaPay",
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: WarnaDesaPay.textMain),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.phoneNumber ?? user?.email ?? "Belum terverifikasi",
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      
                      CustomBounce(
                        onTap: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilScreen()));
                          if (result == true) setState(() {}); 
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: WarnaDesaPay.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: WarnaDesaPay.primary.withOpacity(0.3), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded, color: WarnaDesaPay.primary, size: 14),
                              SizedBox(width: 6),
                              Text("Ubah Profil & KTP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: WarnaDesaPay.primary)),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 36), // Jarak lega ke tombol keluar
          
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
    );
  }
}
