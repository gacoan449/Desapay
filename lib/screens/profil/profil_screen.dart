import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/warna.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

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
                  ),
                ),
              ),

              Center(
                child: Text(
                  data["member"] ?? "Anggota Biasa",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 25),

              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text("Nomor HP"),
                subtitle: Text(data["phone"] ?? "-"),
              ),

              ListTile(
                leading: const Icon(Icons.email),
                title: const Text("Email"),
                subtitle: Text(data["email"] ?? "-"),
              ),

              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text("Saldo"),
                subtitle: Text("Rp ${data["saldo"] ?? 0}"),
              ),

              ListTile(
                leading: const Icon(Icons.stars),
                title: const Text("Poin"),
                subtitle: Text("${data["poin"] ?? 0} Poin"),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text("Ubah Password"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),

              ListTile(
                leading: const Icon(Icons.help),
                title: const Text("Pusat Bantuan"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),

              ListTile(
                leading: const Icon(Icons.info),
                title: const Text("Tentang DesaPay"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("LOGOUT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
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
