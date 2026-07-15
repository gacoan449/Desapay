import 'package:flutter/material.dart';
import '../../config/warna.dart'; // DIKOREKSI: Menggunakan path relatif standar modular Anda
import '../../screens/saldo/topup_saldo_screen.dart';

class SaldoCard extends StatelessWidget {
  // DIKOREKSI: Menggunakan num agar fleksibel menerima int atau double tanpa memicu type mismatch
  final num saldo;

  const SaldoCard({
    super.key, 
    required this.saldo,
  });

  // Helper fungsi untuk format mata uang rupiah dengan pemisah titik
  String _formatRupiah(num nominal) {
    final int value = nominal.toInt();
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gradasi Royal Blue Premium diselaraskan dengan WarnaDesaPay Baru
    final LinearGradient premiumCardGradient = LinearGradient(
      colors: [
        WarnaDesaPay.primary,
        const Color(0xFF1E40AF), // Royal Blue gelap untuk dimensi kedalaman
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: premiumCardGradient,
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
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WarnaDesaPay.secondary.withOpacity(0.08),
                ),
              ),
            ),

            // ==========================================
            // 2. KONTEN UTAMA INFORMASI SALDO
            // ==========================================
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Saldo DesaPay Anda",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Rp ${_formatRupiah(saldo)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ==========================================
                  // 3. TOMBOL TOP UP (SAFE INKWELL INTEGRATION)
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TopupSaldoScreen(),
                              ),
                            );
                          },
                          child: Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded, 
                                  color: Colors.white, 
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Isi Saldo",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
