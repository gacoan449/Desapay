import 'package:flutter/material.dart';
import '../../config/warna.dart';

class BannerPromo extends StatelessWidget {
  const BannerPromo({super.key});

  @override
  Widget build(BuildContext context) {
    // Gradasi Royal Blue Premium diselaraskan dengan WarnaDesaPay Baru
    final LinearGradient premiumPromoGradient = LinearGradient(
      colors: [
        WarnaDesaPay.primary,
        const Color(0xFF1E40AF), // Royal Blue gelap untuk dimensi kedalaman
        const Color(0xFF00C4FF), // Electric Teal di ujung kanan untuk efek pendaran cahaya
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      height: 175,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: premiumPromoGradient,
        boxShadow: [
          BoxShadow(
            color: WarnaDesaPay.primary.withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 8), // Efek bayangan melayang yang realistis
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ==========================================
            // 1. DEKORASI ORNAMEN LINGKARAN ABSTRAK (FINTECH STYLE)
            // ==========================================
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: -10,
              bottom: -60,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WarnaDesaPay.secondary.withOpacity(0.12),
                ),
              ),
            ),

            // ==========================================
            // 2. KONTEN UTAMA TEXT & BADGE
            // ==========================================
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // BADGE PROMO SPESIAL
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: Color(0xFFFFD700), // Gold Star Icon
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "PROMO SPESIAL HARI INI",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // JUDUL CASHBACK MEWAH
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cashback Untung",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              "Hingga 10%",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                        // SUBTITLE PRODUK DENGAN AKSEN SLATE GENTLE
                        Text(
                          "Pulsa • Paket Data • PLN • E-Wallet",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // 3. IKON UTAMA DENGAN EFEK EMBOSSED GLOW
                  // ==========================================
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Efek pendaran di belakang ikon utama
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.local_offer_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
