import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/warna.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'edit_profil_screen.dart';
// REVISI 1: Menambahkan impor halaman admin dashboard agar sistem mengenalinya
import 'admin_dashboard_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final auth = AuthService();
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    const Color warnaTeksUtama = Color(0xFF1A1A1A); // Hitam pekat elegan
    const Color warnaTeksSekunder = Color(0xFF555555); // Abu-abu tua tegas
    const Color warnaIkon = Color(0xFF0D47A1); // Biru tua premium

    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: const Text("Profil"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestore.collection("users").doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data pengguna tidak ditemukan"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const CircleAvatar(
                radius: 45,
                child: Icon(
                  Icons.person,
                  size: 50,
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  data["nama"] ?? "-",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: warnaTeksUtama,
                  ),
                ),
              ),

              Center(
                child: Text(
                  data["member"] ?? "Anggota Biasa",
                  style: const TextStyle(
                    color: warnaTeksSekunder,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              ListTile(
                leading: const Icon(Icons.phone, color: warnaIkon),
                title: const Text(
                  "Nomor HP",
                  style: TextStyle(color: warnaTeksUtama, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  data["phone"] ?? "-",
                  style: const TextStyle(color: warnaTeksSekunder, fontSize: 15),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.email, color: warnaIkon),
                title: const Text(
                  "Email",
                  style: TextStyle(color: warnaTeksUtama, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  data["email"] ?? "-",
                  style: const TextStyle(color: warnaTeksSekunder, fontSize: 15),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: warnaIkon),
                title: const Text(
                  "Saldo",
                  style: TextStyle(color: warnaTeksUtama, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Rp ${data["saldo"] ?? 0}",
                  style: const TextStyle(color: warnaTeksSekunder, fontSize: 15),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.stars, color: warnaIkon),
                title: const Text(
                  "Poin",
                  style: TextStyle(color: warnaTeksUtama, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${data["poin"] ?? 0} Poin",
                  style: const TextStyle(color: warnaTeksSekunder, fontSize: 15),
                ),
              ),

              const Divider(color: Colors.grey, thickness: 0.5),

              // REVISI 2: MEMASANG TOMBOL EMAS ADMIN RAHASIA YANG AMAN DARI EROR HURUF BESAR/KECIL
              if (data["email"].toString().trim().toLowerCase() == "annisaualinayah55@gmail.com")
                Card(
                  color: Colors.amber[50],
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.amber, width: 1),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.amber, size: 28),
                    title: const Text(
                      "Dashboard Admin",
                      style: TextStyle(color: warnaTeksUtama, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Ubah promo, banner info, & kelola menu", style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                  ),
                ),

              ListTile(
                leading: const Icon(Icons.edit, color: warnaIkon),
                title: const Text("Edit Profil", style: TextStyle(color: warnaTeksUtama)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfilScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.lock_reset, color: warnaIkon),
                title: const Text("Ubah Password", style: TextStyle(color: warnaTeksUtama)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {},
              ),

              ListTile(
                leading: const Icon(Icons.help, color: warnaIkon),
                title: const Text("Pusat Bantuan", style: TextStyle(color: warnaTeksUtama)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {},
              ),

              ListTile(
                leading: const Icon(Icons.info, color: warnaIkon),
                title: const Text("Tentang DesaPay", style: TextStyle(color: warnaTeksUtama)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {},
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await auth.logout();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
