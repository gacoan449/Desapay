import 'package:flutter/material.dart';
import '../../config/warna.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium untuk Menu Grid
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
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
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

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBounce(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // Sudut melengkung halus yang modern
          boxShadow: [
            BoxShadow(
              color: WarnaDesaPay.shadow.withOpacity(0.06),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 6), // Bayangan melayang halus yang realistis
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ==========================================
            // 1. ICON CONTAINER DENGAN GLASS EFFECT
            // ==========================================
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: WarnaDesaPay.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 26,
                color: WarnaDesaPay.primary,
              ),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // 2. TYPOGRAPHY DENGAN SLATE-NEUTRAL
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: WarnaDesaPay.textMain, // Slate 900 untuk kontras premium
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
