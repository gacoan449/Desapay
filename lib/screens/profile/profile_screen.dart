import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/warna.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium untuk Menu Akun
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _bukaWhatsApp() async {
    const nomor = "6285642131263";
    final Uri url = Uri.https(
      'wa.me',
      '/$nomor',
      {'text': 'Halo CS DesaPay, saya butuh bantuan terkait akun saya.'},
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
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
          "Profil Saya",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ==========================================
            // 1. PREMIUM GRADIENT HEADER CARD
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
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person_rounded, size: 48, color: WarnaDesaPay.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Pengguna DesaPay",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "081234567890",
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500),
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
                  // 2. HORIZONTAL QUICK INFO METRICS
                  // ==========================================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickInfoItem(Icons.verified_user_rounded, "Tipe Akun", "Premium"),
                        Container(width: 1, height: 30, color: Colors.grey.shade200),
                        _buildQuickInfoItem(Icons.calendar_month_rounded, "Bergabung", "2026"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    "Pengaturan Pengguna",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),

                  // ==========================================
                  // 3. MODERN FLOATING MENU LIST
                  // ==========================================
                  _buildMenuOption(Icons.person_outline_rounded, "Data Akun", () {}),
                  _buildMenuOption(Icons.lock_outline_rounded, "Ubah Kode Keamanan PIN", () {}),
                  _buildMenuOption(Icons.history_toggle_off_rounded, "Riwayat Transaksi PPOB", () {}),

                  const SizedBox(height: 16),
                  Text(
                    "Pusat Bantuan & Informasi",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),

                  // ==========================================
                  // 4. PUSAT BANTUAN PREMIUM & WHATSAPP
                  // ==========================================
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.support_agent_rounded, color: Colors.green, size: 22),
                      ),
                      title: const Text("Pusat Bantuan Live WA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "WhatsApp: 085642131263\nEmail: gacoan449@gmail.com",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.4),
                        ),
                      ),
                      trailing: CustomBounce(
                        onTap: _bukaWhatsApp,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Hubungi",
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // VERSI APLIKASI
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.grey.shade400, size: 20),
                            const SizedBox(width: 12),
                            Text("Versi Aplikasi Resmi", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const Text("DesaPay v2.1.1-Premium", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // TOMBOL KELUAR AKUN PREMIUM
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
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: WarnaDesaPay.primary, size: 20),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
      ],
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
