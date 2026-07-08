import 'package:flutter/material.dart';

import '../../config/warna.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Profil Saya"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.blue,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 50,
            ),
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              "Pengguna DesaPay",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Center(
            child: Text(
              "081234567890",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 30),

          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("Data Akun"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text("Ubah PIN"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Riwayat Transaksi"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text("Pusat Bantuan"),
              subtitle: const Text(
                "WA : 085642131263\nEmail : gacoan449@gmail.com",
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("Versi Aplikasi"),
              subtitle: const Text("DesaPay v1.0.0"),
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 50,

            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Keluar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {},
            ),
          ),

          const SizedBox(height: 30),

        ],
      ),
    );
  }
}
