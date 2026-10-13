import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/warna.dart';
import '../../widgets/menu_item.dart';

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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  
  // Data dari Firestore
  String _kycStatus = "Belum"; // Belum, Pending, Terverifikasi, Ditolak
  String? _fotoProfilUrl;
  String? _fotoKtpUrl;
  String? _fotoSelfieUrl;

  // File lokal yang baru dipilih pengguna (sebelum diupload)
  File? _imageProfilBaru;
  File? _imageKtpBaru;
  File? _imageSelfieBaru;

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
        
        _fotoProfilUrl = data["fotoProfil"];
        _fotoKtpUrl = data["fotoKtp"];
        _fotoSelfieUrl = data["fotoSelfie"];
        _kycStatus = data["kycStatus"] ?? "Belum";
      });
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  /// Fungsi untuk memilih gambar dari Galeri atau Kamera
  Future<void> _pilihGambar(String tipe) async {
    final XFile? image = await _picker.pickImage(
      source: tipe == 'profil' ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 70, // Kompresi agar tidak memberatkan server
    );

    if (image != null) {
      setState(() {
        if (tipe == 'profil') _imageProfilBaru = File(image.path);
        if (tipe == 'ktp') _imageKtpBaru = File(image.path);
        if (tipe == 'selfie') _imageSelfieBaru = File(image.path);
      });
    }
  }

  /// Fungsi untuk mengunggah gambar ke Firebase Storage dan mengembalikan URL-nya
  Future<String?> _uploadKeStorage(File file, String path) async {
    try {
      TaskSnapshot snapshot = await _storage.ref().child(path).putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> _simpanPerubahan() async {
    final String namaTrim = _namaController.text.trim();
    final String emailTrim = _emailController.text.trim();
    final String phoneTrim = _phoneController.text.trim();

    if (namaTrim.isEmpty || emailTrim.isEmpty || phoneTrim.isEmpty) {
      _tampilkanSnackBar("Semua data teks wajib diisi", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        String? finalProfilUrl = _fotoProfilUrl;
        String? finalKtpUrl = _fotoKtpUrl;
        String? finalSelfieUrl = _fotoSelfieUrl;
        

        // 1. Upload Foto Profil jika ada yang baru
        if (_imageProfilBaru != null) {
          final url = await _uploadKeStorage(_imageProfilBaru!, 'profiles/${user.uid}/profil_${DateTime.now().millisecondsSinceEpoch}.jpg');
          if (url == null) throw StateError("Gagal mengunggah foto profil.");
          finalProfilUrl = url;
        }

        // 2. Upload KTP jika ada yang baru
        if (_imageKtpBaru != null) {
          final url = await _uploadKeStorage(_imageKtpBaru!, 'kyc/${user.uid}/ktp_${DateTime.now().millisecondsSinceEpoch}.jpg');
          if (url == null) throw StateError("Gagal mengunggah foto KTP.");
          finalKtpUrl = url;
        }

        // 3. Upload Selfie jika ada yang baru
        if (_imageSelfieBaru != null) {
          final url = await _uploadKeStorage(_imageSelfieBaru!, 'kyc/${user.uid}/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg');
          if (url == null) throw StateError("Gagal mengunggah foto selfie.");
          finalSelfieUrl = url;
        }

        // 4. Simpan semua data & URL foto ke Firestore
        await user.updateDisplayName(namaTrim);
        final updateData = <String, dynamic>{
          "nama": namaTrim,
          "email": emailTrim,
          "phone": phoneTrim,
          "fotoProfil": finalProfilUrl,
          "fotoKtp": finalKtpUrl,
          "fotoSelfie": finalSelfieUrl,
        };

        final dokumenKycLengkap =
            finalKtpUrl != null && finalKtpUrl.isNotEmpty &&
            finalSelfieUrl != null && finalSelfieUrl.isNotEmpty;
        final adaDokumenBaru =
            _imageKtpBaru != null || _imageSelfieBaru != null;
        final statusSudahTerverifikasi =
            _kycStatus.toUpperCase() == "TERVERIFIKASI" ||
            _kycStatus.toUpperCase() == "APPROVED";

        // Client hanya boleh mengajukan status Pending, tidak dapat menyetujui KYC.
        if (dokumenKycLengkap && adaDokumenBaru && !statusSudahTerverifikasi) {
          updateData["kycStatus"] = "Pending";
        }

        await _firestore.collection("users").doc(user.uid).update(updateData);

        if (!mounted) return;
        _tampilkanSnackBar("Data Profil & Dokumen berhasil disimpan!", isError: false);
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (!mounted) return;
      _tampilkanSnackBar("Gagal menyimpan data: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg, 
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Ubah Data Profil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // FOTO PROFIL SECTION
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: WarnaDesaPay.primary.withOpacity(0.08),
                      // Tampilkan gambar baru, atau gambar dari internet, atau ikon default
                      backgroundImage: _imageProfilBaru != null 
                          ? FileImage(_imageProfilBaru!) 
                          : (_fotoProfilUrl != null ? NetworkImage(_fotoProfilUrl!) : null) as ImageProvider?,
                      child: (_imageProfilBaru == null && _fotoProfilUrl == null) 
                          ? const Icon(Icons.person_rounded, size: 54, color: WarnaDesaPay.primary) 
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 2, right: 2,
                    child: CustomBounce(
                      onTap: () => _pilihGambar('profil'),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(color: WarnaDesaPay.warning, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // FORM DATA DIRI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernTextField(controller: _namaController, label: "Nama Lengkap (Sesuai KTP)", hint: "Masukkan nama lengkap", icon: Icons.person_outline_rounded),
                  const SizedBox(height: 20),
                  _buildModernTextField(controller: _emailController, label: "Alamat Email Aktif", hint: "contoh@domain.com", icon: Icons.email_outlined, type: TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  _buildModernTextField(controller: _phoneController, label: "Nomor Handphone Terdaftar", hint: "Contoh: 08xxxxxxxxxx", icon: Icons.phone_android_rounded, type: TextInputType.phone),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // DOKUMEN KYC (KTP & SELFIE) SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _kycStatus == "Terverifikasi" ? WarnaDesaPay.success : 
                         _kycStatus == "Pending" ? WarnaDesaPay.warning : WarnaDesaPay.danger.withOpacity(0.5), 
                  width: 1.5
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kycStatus == "Terverifikasi" ? WarnaDesaPay.success.withOpacity(0.1) : WarnaDesaPay.warning.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _kycStatus == "Terverifikasi" ? Icons.verified_user_rounded : Icons.pending_actions_rounded, 
                          color: _kycStatus == "Terverifikasi" ? WarnaDesaPay.success : WarnaDesaPay.warning, 
                          size: 20
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Verifikasi Identitas (KYC)", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: WarnaDesaPay.textMain)),
                            Text("Status: $_kycStatus", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kycStatus == "Terverifikasi" ? WarnaDesaPay.success : WarnaDesaPay.warning)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_kycStatus == "Belum" || _kycStatus == "Ditolak") ...[
                    const Text("Upload foto KTP dan Selfie memegang KTP agar Anda bisa menikmati limit saldo yang lebih besar.", style: TextStyle(fontSize: 12, color: WarnaDesaPay.textSub)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildUploadBox("Foto e-KTP", _imageKtpBaru, _fotoKtpUrl, () => _pilihGambar('ktp')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildUploadBox("Selfie + KTP", _imageSelfieBaru, _fotoSelfieUrl, () => _pilihGambar('selfie')),
                        ),
                      ],
                    ),
                  ] else if (_kycStatus == "Pending") ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text("Data dokumen Anda sedang diperiksa oleh Admin. Mohon tunggu.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: WarnaDesaPay.textSub)),
                      ),
                    )
                  ] else if (_kycStatus == "Terverifikasi") ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text("Akun Anda telah Terverifikasi. Identitas Anda aman terlindungi.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WarnaDesaPay.success)),
                      ),
                    )
                  ]
                ],
              ),
            ),

            const SizedBox(height: 36),

            // TOMBOL SIMPAN
            CustomBounce(
              onTap: _simpanPerubahan,
              isDisabled: _isLoading,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey.shade400 : WarnaDesaPay.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isLoading ? [] : [BoxShadow(color: WarnaDesaPay.primary.withOpacity(0.24), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text("SIMPAN PERUBAHAN & UPLOAD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadBox(String title, File? newImage, String? oldUrl, VoidCallback onTap) {
    return CustomBounce(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: WarnaDesaPay.lightBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WarnaDesaPay.lightField, width: 2),
          image: newImage != null 
              ? DecorationImage(image: FileImage(newImage), fit: BoxFit.cover)
              : (oldUrl != null ? DecorationImage(image: NetworkImage(oldUrl), fit: BoxFit.cover) : null),
        ),
        alignment: Alignment.center,
        child: (newImage == null && oldUrl == null)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, color: WarnaDesaPay.textSub, size: 24),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WarnaDesaPay.textSub)),
                ],
              )
            : Container( // Overlay gelap tipis agar tombol ganti terlihat
                width: double.infinity, height: double.infinity,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Text("Ganti", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
      ),
    );
  }

  Widget _buildModernTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: WarnaDesaPay.textSub, letterSpacing: 0.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: WarnaDesaPay.textMain),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: WarnaDesaPay.primary, size: 20),
            filled: true,
            fillColor: WarnaDesaPay.lightBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
