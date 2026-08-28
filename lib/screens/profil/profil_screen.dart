import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/warna.dart';
import 'edit_profil_screen.dart';
import 'keamanan_screen.dart';
import 'bantuan_cs_screen.dart';
import 'tentang_screen.dart';
import '../login/login_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _nama = "Member DesaPay";
  String _kontak = "Belum terverifikasi";
  String? _fotoProfil;
  String _kycStatus = "BELUM";

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data() ?? {};

        setState(() {
          _nama = (data['nama'] ??
                  user.displayName ??
                  "Member DesaPay")
              .toString();

          _kontak = (data['phone'] ??
                  user.phoneNumber ??
                  data['email'] ??
                  user.email ??
                  "Belum terverifikasi")
              .toString();

          _fotoProfil = data['fotoProfil']?.toString();

          _kycStatus =
              (data['kycStatus'] ?? "BELUM").toString().toUpperCase();
        });
      } else {
        setState(() {
          _nama = user.displayName ?? "Member DesaPay";
          _kontak =
              user.phoneNumber ?? user.email ?? "Belum terverifikasi";
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat profil: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _labelKyc() {
    switch (_kycStatus) {
      case "APPROVED":
        return "Terverifikasi";
      case "PENDING":
        return "Menunggu Verifikasi";
      case "REJECTED":
        return "Ditolak";
      default:
        return "Belum Verifikasi";
    }
  }

  Color _kycColor() {
    switch (_kycStatus) {
      case "APPROVED":
        return WarnaDesaPay.success;
      case "PENDING":
        return WarnaDesaPay.warning;
      case "REJECTED":
        return WarnaDesaPay.danger;
      default:
        return WarnaDesaPay.textSub;
    }
  }

  Future<void> _bukaEditProfil() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfilScreen(),
      ),
    );

    if (result == true) {
      await _loadProfil();
    }
  }

  Future<void> _logout() async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: WarnaDesaPay.danger,
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                "Keluar Akun",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: WarnaDesaPay.textMain,
                ),
              ),
            ],
          ),
          content: const Text(
            "Apakah Anda yakin ingin keluar dari sesi aktif DesaPay?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Batal",
                style: TextStyle(
                  color: WarnaDesaPay.textSub,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: WarnaDesaPay.danger,
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Keluar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (keluar != true) return;

    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            backgroundColor: WarnaDesaPay.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      WarnaDesaPay.primary,
                      Color(0xFF1E40AF),
                      WarnaDesaPay.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Profil Pengguna",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.85),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white,
                              backgroundImage: _fotoProfil != null &&
                                      _fotoProfil!.isNotEmpty
                                  ? NetworkImage(_fotoProfil!)
                                  : null,
                              child: _fotoProfil == null ||
                                      _fotoProfil!.isEmpty
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 50,
                                      color: WarnaDesaPay.primary,
                                    )
                                  : null,
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _kycColor(),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _kycStatus == "APPROVED"
                                  ? Icons.verified_rounded
                                  : Icons.person_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ==========================================
                  // DATA PROFIL
                  // ==========================================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: WarnaDesaPay.shadow.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_loading)
                          const SizedBox(
                            height: 28,
                            width: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                        else ...[
                          Text(
                            _nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: WarnaDesaPay.textMain,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            _kontak,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: WarnaDesaPay.textSub,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _kycColor().withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _labelKyc(),
                              style: TextStyle(
                                color: _kycColor(),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Divider(
                            color: WarnaDesaPay.lightField,
                            height: 1,
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: _PressScale(
                              onTap: _bukaEditProfil,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: WarnaDesaPay.primary
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: WarnaDesaPay.primary
                                        .withOpacity(0.20),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      color: WarnaDesaPay.primary,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Ubah Profil & Verifikasi KTP",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: WarnaDesaPay.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Pengaturan & Keamanan",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: WarnaDesaPay.textSub,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              WarnaDesaPay.shadow.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _menu(
                          Icons.security_rounded,
                          "Keamanan Akun",
                          "PIN Transaksi & Biometrik",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const KeamananScreen(),
                              ),
                            );
                          },
                        ),

                        const Divider(
                          height: 1,
                          indent: 56,
                          color: WarnaDesaPay.lightField,
                        ),

                        _menu(
                          Icons.headset_mic_rounded,
                          "Pusat Bantuan CS",
                          "Layanan Pelanggan 24/7",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const BantuanCsScreen(),
                              ),
                            );
                          },
                        ),

                        const Divider(
                          height: 1,
                          indent: 56,
                          color: WarnaDesaPay.lightField,
                        ),

                        _menu(
                          Icons.info_outline_rounded,
                          "Tentang Aplikasi",
                          "DesaPay v1.0.0 (Production)",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const TentangScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  _PressScale(
                    onTap: _logout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: WarnaDesaPay.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              WarnaDesaPay.danger.withOpacity(0.15),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: WarnaDesaPay.danger,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Keluar Aplikasi",
                            style: TextStyle(
                              color: WarnaDesaPay.danger,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: WarnaDesaPay.primary.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: WarnaDesaPay.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: WarnaDesaPay.textMain,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: WarnaDesaPay.textSub,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: WarnaDesaPay.textSub,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

// ============================================================
// MICRO INTERACTION KHUSUS PROFIL
// Tidak bergantung pada menu_item.dart
// ============================================================

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressScale({
    required this.child,
    required this.onTap,
  });

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.04,
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.scale(
            scale: 1.0 - _controller.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
