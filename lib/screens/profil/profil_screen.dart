import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/warna.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'edit_profil_screen.dart';
import 'admin_dashboard_screen.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium untuk Tombol Menu
class CustomBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const CustomBounce({super.key, required this.child, required this.onTap});

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
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final auth = AuthService();
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  String rupiah(dynamic angka) {
    int value = int.tryParse(angka.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
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
          "Akun Saya",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
          final String emailUser = (data["email"] ?? "").toString().trim().toLowerCase();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ==========================================
                // 1. PREMIUM GRADIENT AVATAR HEADER
                // ==========================================
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [WarnaDesaPay.primary, const Color(0xFF007BE6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 32, top: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person_rounded, size: 48, color: WarnaDesaPay.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        data["nama"] ?? "-",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          data["member"] ?? "Anggota Biasa",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==========================================
                      // 2. ACCOUNT METRICS CARD (SALDO & POIN GRID)
                      // ==========================================
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Saldo Utama", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text("Rp ${rupiah(data["saldo"])}", style: TextStyle(color: WarnaDesaPay.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 35, color: Colors.grey.shade200),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Poin Loyalitas", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text("${data["poin"] ?? 0} Pts", style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text("Informasi Kredensial", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                      const SizedBox(height: 12),

                      // FIELD INFO LIST DATA
                      _buildInfoField(Icons.phone_android_rounded, "Nomor Handphone", data["phone"] ?? "-"),
                      _buildInfoField(Icons.email_rounded, "Alamat Email", data["email"] ?? "-"),

                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text("Pengaturan Akun", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                      const SizedBox(height: 12),

                      // ==========================================
                      // 3. ADMIN DASHBOARD LUXURY CARD (IF MATCH)
                      // ==========================================
                      if (emailUser == "annisaualinayah55@gmail.com")
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: CustomBounce(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.amber.shade700, Colors.orange.shade600],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: const Row(
                                children: [
                                  CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white)),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Dashboard Administrasi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                        SizedBox(height: 2),
                                        Text("Kelola penawaran promo, banner info, & menu data", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // MENU BUTTON LIST OPTIONS
                      _buildMenuOption(Icons.edit_rounded, "Ubah Detail Profil", () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilScreen()));
                      }),
                      _buildMenuOption(Icons.lock_reset_rounded, "Ganti Keamanan PIN/Password", () {}),
                      _buildMenuOption(Icons.help_center_rounded, "Pusat Pelayanan Kendala", () {}),
                      _buildMenuOption(Icons.info_outline_rounded, "Legalitas & Tentang DesaPay", () {}),

                      const SizedBox(height: 32),

                      // ELEVATED LOGOUT BUTTON PREMIUM LOOK
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text("KELUAR DARI AKUN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            await auth.logout();
                            if (!context.mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoField(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: WarnaDesaPay.primary, size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: WarnaDesaPay.primary.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: WarnaDesaPay.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
