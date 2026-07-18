import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'menu_item.dart'; // Menggunakan standarisasi CustomBounce dari arsitektur menu sebelumnya

/// Palet Warna Resmi DesaPay Premium untuk Komponen Kebutuhan Visual UI Fintech
class WarnaDesaPay {
  static const Color primary = Color(0xFF1E3A8A);   // Royal Blue Utama DesaPay
  static const Color secondary = Color(0xFF06B6D4); // Cyan/Teal Aksen Modern
}

/// Dummy Screen Fallback jika TopupSaldoScreen belum diinisialisasi secara penuh di modul lain
class TopupSaldoScreen extends StatelessWidget {
  const TopupSaldoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Top Up Saldo"),
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text("Halaman Pengisian Saldo DesaPay"),
      ),
    );
  }
}

/// Widget Stateless Komponen Kartu Informasi Saldo Premium DesaPay (Presentation Layer)
class SaldoCard extends StatelessWidget {
  final int saldo; // Menggunakan tipe data int untuk menjamin konsistensi skema database finansial kita

  const SaldoCard({
    super.key, 
    required this.saldo,
  });

  // Deklarasi properti desain di tingkat kelas sebagai konstanta untuk menjaga efisiensi RAM (Zero Memory Leak)
  static const LinearGradient _premiumCardGradient = LinearGradient(
    colors: [
      WarnaDesaPay.primary,
      Color(0xFF1E40AF), // Royal Blue gelap untuk kedalaman dimensi visual
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: WarnaDesaPay.primary.withOpacity(0.12),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  /// Helper pemformatan mata uang Rupiah berbasis int (Type-Safe & No Crash)
  String _formatKeRupiah(int nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(nominal);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: _premiumCardGradient,
        boxShadow: _cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // =========================================================================
            // 1. DEKORASI ORNAMEN LINGKARAN ABSTRAK (PREMIUM FINTECH GLOW AXIS)
            // =========================================================================
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

            // =========================================================================
            // 2. KONTEN UTAMA INFORMASI SALDO & PROTEKSI OVERFLOW TATA LETAK
            // =========================================================================
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
                  
                  // Proteksi Total Nominal Besar agar tulisan mengecil secara otomatis & tidak pecah
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatKeRupiah(saldo),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 22),

                  // =========================================================================
                  // 3. TOMBOL TOP UP DENGAN ANIMASI MEMANTUL PREMIUM (`CustomBounce`)
                  // =========================================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomBounce(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TopupSaldoScreen(),
                            ),
                          );
                        },
                        child: Container(
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
