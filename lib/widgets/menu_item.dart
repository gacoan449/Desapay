import 'package:flutter/material.dart';

// Mengarahkan ke konfigurasi warna pusat DesaPay untuk menghindari error duplikasi impor
import '../config/warna.dart';

/// Pembungkus Animasi Memantul (Micro-interaction) Premium untuk Menu Grid DesaPay
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
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
      onTapUp: (_) async {
        await _controller.reverse();
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

/// Widget Item Menu Grid Fintek Premium Adaptif (Presentation Layer)
class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final Color badgeColor;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = WarnaDesaPay.primary,
    this.badgeColor = const Color(0xFFEFF6FF), // Default ke Biru Sangat Muda (Slate/Blue 50)
  });

  @override
  Widget build(BuildContext context) {
    // Optimasi Bayangan Konstan untuk Menghemat Alokasi Memori Perangkat
    final List<BoxShadow> itemShadow = [
      BoxShadow(
        color: WarnaDesaPay.shadow.withOpacity(0.06),
        blurRadius: 14,
        spreadRadius: 0,
        offset: const Offset(0, 6),
      ),
    ];

    return CustomBounce(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: itemShadow,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // =========================================================================
            // 1. ICON CONTAINER DENGAN GLASS DYNAMIC EFFECT ELEGAN
            // =========================================================================
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 26,
                color: iconColor,
              ),
            ),

            const SizedBox(height: 10),

            // =========================================================================
            // 2. TYPOGRAPHY DENGAN SLATE-NEUTRAL & PROTEKSI OVERFLOW
            // =========================================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700, // Tebal proporsional premium
                  color: WarnaDesaPay.textMain,
                  height: 1.25,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
