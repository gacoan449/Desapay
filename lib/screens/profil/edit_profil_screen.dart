import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

// Import Konfigurasi & Widget Modular Utama (CTO Standard)
import '../../config/warna.dart';
import '../../widgets/menu_item.dart'; // Menggunakan CustomBounce pusat terstandardisasi

/// Halaman Ubah Data Profil Fintek Premium DesaPay (Presentation Layer)
class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  
  // Status KTP (Bisa diambil dari database nanti, default true untuk contoh KYC)
  final bool _isKtpVerified = true; 

  @override
  void initState() {
    super.initState();
    _loadDataPengguna();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Memuat data terkini pengguna dari repositori Firestore
  Future<void> _loadDataPengguna() async {
    final User? user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final doc = await _firestore.collection("users").doc(user.uid).get();
      if (!doc.exists || !mounted) return;

      final data = doc.data()!;
      setState(() {
        _namaController.text = data["nama"] ?? user.displayName ?? "";
        _emailController.text = data["email"] ?? user.email ?? "";
        _phoneController.text = data["phone"] ?? user.phoneNumber ?? "";
      });
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  /// Mengirim pembaruan entitas profil ke Firestore dengan validasi ketat
  Future<void> _simpanPerubahan() async {
    final String namaTrim = _namaController.text.trim();
    final String emailTrim = _emailController.text.trim();
    final String phoneTrim = _phoneController.text.trim();

    if (namaTrim.isEmpty || emailTrim.isEmpty || phoneTrim.isEmpty) {
      _tampilkanSnackBar("Semua data wajib diisi secara lengkap", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Update ke Firebase Auth
        await user.updateDisplayName(namaTrim);
        
        // Update ke Firestore
        await _firestore.collection("users").doc(user.uid).update({
          "nama": namaTrim,
          "email": emailTrim,
          "phone": phoneTrim,
        });

        if (!mounted) return;
        setState(() => _isLoading = false);
        _tampilkanSnackBar("Profil Anda berhasil diperbarui", isError: false);
        Navigator.pop(context, true); // Kirim flag 'true' agar layar sebelumnya ter-refresh
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _tampilkanSnackBar(e.toString(), isError: true);
    }
  }

  /// Fungsi untuk menghubungi Admin via WhatsApp jika ingin ubah KTP
  Future<void> _hubungiAdminKtp() async {
    const String phone = "6285642131263";
    const String message = "Halo Admin DesaPay, saya ingin mengajukan perubahan data e-KTP di akun saya. Mohon panduannya.";
    final Uri waUrl = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");

    try {
      if (!await launchUrl(waUrl, mode: LaunchMode.externalApplication)) {
        _tampilkanSnackBar("Tidak dapat membuka WhatsApp", isError: true);
      }
    } catch (e) {
      _tampilkanSnackBar("Terjadi kesalahan sistem", isError: true);
    }
  }

  /// Helper penampil notifikasi SnackBar premium
  void _tampilkanSnackBar(String pesan, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isError ? WarnaDesaPay.danger : WarnaDesaPay.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Penyesuaian tema, menggunakan default ke false jika tidak ada setup dark mode penuh
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? WarnaDesaPay.lightBg : WarnaDesaPay.lightBg, // Fallback aman
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Ubah Data Profil",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3),
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
            // =========================================================================
            // 1. DEKORASI FOTO PROFIL & CIRCLING CAMERA ICON PANEL
            // =========================================================================
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
                          color: WarnaDesaPay.shadow.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: WarnaDesaPay.primary.withOpacity(0.08),
                      child: const Icon(Icons.person_rounded, size: 54, color: WarnaDesaPay.primary),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: CustomBounce(
                      onTap: () {
                        _tampilkanSnackBar("Fitur upload foto wajah sedang dikembangkan.", isError: false);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: WarnaDesaPay.warning,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // =========================================================================
            // 2. FORM INPUT PREMIUM DENGAN DUKUNGAN THEMED COMPATIBILITY
            // =========================================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: WarnaDesaPay.shadow.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernTextField(
                    context: context,
                    controller: _namaController,
                    label: "Nama Lengkap / Username",
                    hint: "Masukkan nama lengkap",
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildModernTextField(
                    context: context,
                    controller: _emailController,
                    label: "Alamat Email Aktif",
                    hint: "contoh@domain.com",
                    icon: Icons.email_outlined,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildModernTextField(
                    context: context,
                    controller: _phoneController,
                    label: "Nomor Handphone Terdaftar",
                    hint: "Contoh: 08xxxxxxxxxx",
                    icon: Icons.phone_android_rounded,
                    type: TextInputType.phone,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =========================================================================
            // 3. KEAMANAN IDENTITAS (KYC/KTP) YANG DIKUNCI
            // =========================================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: WarnaDesaPay.lightCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: WarnaDesaPay.lightField, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isKtpVerified ? WarnaDesaPay.success.withOpacity(0.1) : WarnaDesaPay.warning.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isKtpVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded, 
                          color: _isKtpVerified ? WarnaDesaPay.success : WarnaDesaPay.warning, 
                          size: 20
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text("Data e-KTP (KYC)", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: WarnaDesaPay.textMain)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Demi keamanan akun dari tindak pencurian identitas, perubahan foto e-KTP dan NIK hanya dapat dilakukan melalui validasi Admin.",
                    style: TextStyle(fontSize: 12, color: WarnaDesaPay.textSub, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  CustomBounce(
                    onTap: _hubungiAdminKtp,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: WarnaDesaPay.primary.withOpacity(0.3), width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.support_agent_rounded, color: WarnaDesaPay.primary, size: 18),
                          SizedBox(width: 8),
                          Text("Hubungi Admin", style: TextStyle(color: WarnaDesaPay.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 36),

            // =========================================================================
            // 4. E-WALLET ACTION BUTTON DENGAN UKURAN KONSISTEN & MIKRO INTERAKSI
            // =========================================================================
            CustomBounce(
              onTap: _simpanPerubahan,
              isDisabled: _isLoading,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey.shade400 : WarnaDesaPay.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isLoading 
                    ? [] 
                    : [
                        BoxShadow(
                          color: WarnaDesaPay.primary.withOpacity(0.24),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                ),
                alignment: Alignment.center,
                child: _isLoading
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
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.6,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builder modular Input Field terintegrasi dengan Dekorasi Global Aplikasi
  Widget _buildModernTextField({
    required BuildContext context,
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
          style: const TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.w800, 
            color: WarnaDesaPay.textSub,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(
            fontSize: 15, 
            fontWeight: FontWeight.w700, 
            color: WarnaDesaPay.textMain
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: WarnaDesaPay.primary, size: 20),
            filled: true,
            fillColor: WarnaDesaPay.lightBg,
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
