import 'package:flutter/material.dart';

/// Palet Warna Resmi DesaPay Premium untuk Kebutuhan Visual UI Fintech
class WarnaDesaPay {
  static const Color primary = Color(0xFF1E3A8A);   // Royal Blue Utama DesaPay
  static const Color secondary = Color(0xFF06B6D4); // Cyan/Teal Aksen Modern
}

/// Widget Komponen Visual Banner Promo Premium DesaPay (Presentation Layer)
class BannerPromo extends StatelessWidget {
  const BannerPromo({super.key});

  // Deklarasi properti desain di tingkat kelas sebagai konstanta demi optimalisasi memori perangkat (Zero Memory Leak)
  static const LinearGradient _premiumPromoGradient = LinearGradient(
    colors: [
      WarnaDesaPay.primary,
      Color(0xFF1E40AF), // Royal Blue gelap untuk dimensi kedalaman visual
      Color(0xFF00C4FF), // Electric Teal di ujung kanan untuk efek pendaran cahaya modern
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final List<BoxShadow> _bannerShadow = [
    BoxShadow(
      color: WarnaDesaPay.primary.withOpacity(0.12),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 8), // Efek bayangan melayang yang realistis
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 175,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: _premiumPromoGradient,
        boxShadow: _bannerShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // =========================================================================
            // 1. DEKORASI ORNAMEN LINGKARAN ABSTRAK (PREMIUM FINTECH GLOWING STYLE)
            // =========================================================================
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

            // =========================================================================
            // 2. KONTEN UTAMA TEXT, BADGE & PROTEKSI OVERFLOW
            // =========================================================================
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // BADGE PROMO SPESIAL (Auto Wrap / No Clipping)
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: Color(0xFFFFD700), // Gold Star Icon Premium
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "PROMO SPESIAL HARI INI",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: MediaQuery.of(context).size.width < 360 ? 8 : 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // JUDUL CASHBACK MEWAH DENGAN ADAPTIF KETINGGIAN FONT
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cashback Untung",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Hingga 10%",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // SUBTITLE DAFTAR LAYANAN PPOB DESAPAY (PROTEKSI OVERFLOW TOTAL)
                        Text(
                          "Pulsa • Paket Data • PLN • E-Wallet",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

                  const SizedBox(width: 12),

                  // =========================================================================
                  // 3. IKON UTAMA DENGAN EFEK EMBOSSED GLOW ADAPTIF
                  // =========================================================================
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
