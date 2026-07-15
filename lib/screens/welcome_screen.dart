import 'package:flutter/material.dart';
import '../../config/warna.dart';
import 'home/home_screen.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium untuk Tombol Utama
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

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC), // Latar belakang abu-putih premium melunakkan kontras
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // ==========================================
              // 1. WIDGET TAMPILAN LOGO UTAMA PENDAPATAN
              // ==========================================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.04),
                      spreadRadius: 6,
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    'ChatGPT Image 8 Jul 2026, 22.03.40.png',
                    height: 130, 
                    width: 130,  
                    fit: BoxFit.contain, // DIKOREKSI: Mengubah properti Alignment menjadi BoxFit yang valid
                    errorBuilder: (context, error, stackTrace) {
                      return CircleAvatar(
                        radius: 65,
                        backgroundColor: WarnaDesaPay.primary.withOpacity(0.08),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 72,
                          color: WarnaDesaPay.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ==========================================
              // 2. TEKS JUDUL DAN JARGON KEAGENAN
              // ==========================================
              const Text(
                "Selamat Datang di DesaPay",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "Solusi terbaik loket pembayaran digital, pulsa, dan tagihan PPOB modern. Mudah digunakan, aman, dan tepercaya untuk kemajuan ekonomi desa.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // ==========================================
              // 3. TOMBOL UTAMA DENGAN CUSTOM BOUNCE ANIMATION
              // ==========================================
              CustomBounce(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: WarnaDesaPay.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: WarnaDesaPay.primary.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "MULAI JUALAN SEKARANG",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
