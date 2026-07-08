import 'package:flutter/material.dart';

import '../../config/warna.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: const Text("Profil"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [

          CircleAvatar(
            radius: 45,
            child: Icon(
              Icons.person,
              size: 50,
            ),
          ),

          SizedBox(height: 15),

          Center(
            child: Text(
              "Pengguna DesaPay",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: 30),

          ListTile(
            leading: Icon(Icons.phone),
            title: Text("Nomor HP"),
            subtitle: Text("-"),
          ),

          ListTile(
            leading: Icon(Icons.email),
            title: Text("Email"),
            subtitle: Text("-"),
          ),

          Divider(),

          ListTile(
            leading: Icon(Icons.chat),
            title: Text("WhatsApp Bantuan"),
            subtitle: Text("085642131263"),
          ),

          ListTile(
            leading: Icon(Icons.mail),
            title: Text("Email Bantuan"),
            subtitle: Text("gacoan449@gmail.com"),
          ),

        ],
      ),
    );
  }
}
