import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/warna.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium untuk Tombol Aksi
class CustomBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isDisabled;

  const CustomBounce({
    super.key, 
    required this.child, 
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  State<CustomBounce> createState() => _CustomBounceState();
}

class _CustomBounceState extends State<CustomBounce> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.isDisabled ? null : _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (!widget.isDisabled) widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

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
    final user = auth.currentUser;
    if (user == null) return;
    
    final uid = user.uid;
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
        SnackBar(
          content: const Text("Semua data wajib diisi secara lengkap"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final user = auth.currentUser;
      if (user != null) {
        final uid = user.uid;

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
          SnackBar(
            content: const Text("Profil berhasil diperbarui"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.green.shade600,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        loading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        title: const Text(
          "Ubah Data Profil",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // AVATAR DECORATION TOP BANNER LOOK
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: WarnaDesaPay.primary.withOpacity(0.08),
                      child: Icon(Icons.person_rounded, size: 54, color: WarnaDesaPay.primary),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // FORM INPUT PREMIUM CARD PANEL
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernTextField(
                    controller: nama,
                    label: "Nama Lengkap Sesuai KTP",
                    hint: "Masukkan nama lengkap",
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildModernTextField(
                    controller: email,
                    label: "Alamat Email Aktif",
                    hint: "contoh@domain.com",
                    icon: Icons.email_outlined,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildModernTextField(
                    controller: phone,
                    label: "Nomor Handphone Terdaftar",
                    hint: "Contoh: 08xxxxxxxxxx",
                    icon: Icons.phone_android_rounded,
                    type: TextInputType.phone,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ELEVATED BUTTON WITH BOUNCE MICRO-INTERACTION
            CustomBounce(
              onTap: simpan,
              isDisabled: loading,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: loading ? Colors.grey.shade400 : WarnaDesaPay.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: loading 
                    ? [] 
                    : [
                        BoxShadow(
                          color: WarnaDesaPay.primary.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                ),
                alignment: Alignment.center,
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "SIMPAN PERUBAHAN",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: WarnaDesaPay.primary, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
