import 'package:flutter/material.dart';

// Widget MenuItem untuk Grid Layanan Beranda
class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color badgeColor;
  final Color iconColor;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.badgeColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBounce(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Widget CustomBounce Premium (Mendukung isDisabled)
class CustomBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isDisabled; // Parameter untuk menonaktifkan tombol

  const CustomBounce({
    super.key,
    required this.child,
    required this.onTap,
    this.isDisabled = false, // Default false agar tombol lain tidak mati
  });

  @override
  State<CustomBounce> createState() => _CustomBounceState();
}

class _CustomBounceState extends State<CustomBounce> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isDisabled) _controller.forward();
      },
      onTapUp: (_) {
        if (!widget.isDisabled) {
          _controller.reverse();
          widget.onTap();
        }
      },
      onTapCancel: () {
        if (!widget.isDisabled) _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
