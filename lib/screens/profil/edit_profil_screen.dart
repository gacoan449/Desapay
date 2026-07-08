import 'package:flutter/material.dart';

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

  bool loading = false;

  @override
  void dispose() {
    nama.dispose();
    email.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> simpan() async {

    setState(() {
      loading = true;
    });

    // Firebase update nanti

    await Future.delayed(
      const Duration(seconds: 1),
    );

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
