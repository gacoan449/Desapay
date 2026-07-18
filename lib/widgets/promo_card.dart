import 'package:flutter/material.dart';
import 'menu_item.dart'; // Menggunakan CustomBounce yang sudah distandarisasi sebelumnya

/// Widget Komponen Kartu Promo Horizontal Premium Fintek DesaPay (Presentation Layer)
class PromoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const PromoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Pembentukan gradasi dimensi warna premium secara dinamis berdasarkan input tema
    final LinearGradient cardGradient = LinearGradient(
      colors: [
        color,
        color.withOpacity(0.80),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final List<BoxShadow> cardShadow = [
      BoxShadow(
        color: color.withOpacity(0.18),
        blurRadius: 14,
        spreadRadius: 0,
        offset: const Offset(0, 6),
      ),
    ];

    return CustomBounce(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: cardGradient,
          boxShadow: cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // =========================================================================
              // 1. ORNAMEN GEOMETRIS LATAR BELAKANG (PREMIUM FINTECH GLOW AXIS)
              // =========================================================================
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -40,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),

              // =========================================================================
              // 2. KONTEN UTAMA KARTU PROMO & INTEGRASI TYPOGRAPHY MEWAH
              // =========================================================================
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CONTAINER IKON DENGAN BACKGROUND GLASS EFFECT ELEGAN
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),

                    const SizedBox(height: 32), // Mengganti Spacer untuk konsistensi tinggi pada list horizontal
                    
                    // TYPOGRAPHY JUDUL PROMO MEWAH TERPROTEKSI
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // TYPOGRAPHY DESKRIPSI PROMO ADAPTIF SLATE-WHITE
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
