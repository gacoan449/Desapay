import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/warna.dart';

class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {

  final nama = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final uid = auth.currentUser!.uid;

    final doc = await firestore.collection("users").doc(uid).get();

    if (!doc.exists) return;

    final data = doc.data()!;

    nama.text = data["nama"] ?? "";
    email.text = data["email"] ?? "";
    phone.text = data["phone"] ?? "";
  }

  @override
  void dispose() {
    nama.dispose();
    email.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> simpan() async {
    if (nama.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        phone.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua data wajib diisi"),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final uid = auth.currentUser!.uid;

      await firestore.collection("users").doc(uid).update({
        "nama": nama.text.trim(),
        "email": email.text.trim(),
        "phone": phone.text.trim(),
      });

      setState(() {
        loading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil berhasil diperbarui"),
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Edit Profil"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          TextField(
            controller: nama,
            decoration: const InputDecoration(
              labelText: "Nama Lengkap",
              prefixIcon: Icon(Icons.person),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "Email",
              prefixIcon: Icon(Icons.email),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Nomor HP",
              prefixIcon: Icon(Icons.phone),
            ),
          ),

          const SizedBox(height: 35),

          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: loading ? null : simpan,
              child: loading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text("SIMPAN"),
            ),
          ),
        ],
      ),
    );
  }
}
