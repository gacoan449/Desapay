import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/saldo_service.dart';

/// Palet Warna Resmi DesaPay Premium untuk Kebutuhan Visual UI Fintech
class WarnaDesaPay {
  static const Color primary = Color(0xFF1E3A8A);   // Royal Blue Utama DesaPay
  static const Color secondary = Color(0xFF06B6D4); // Cyan/Teal Aksen Modern
}

/// Widget Dashboard Informasi Saldo Pengguna DesaPay (Presentation Layer)
class KotakSaldo extends StatefulWidget {
  const KotakSaldo({super.key});

  @override
  State<KotakSaldo> createState() => _KotakSaldoState();
}

class _KotakSaldoState extends State<KotakSaldo> with SingleTickerProviderStateMixin {
  final ISaldoService _saldoService = SaldoService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late AnimationController _rotationController;
  Stream<int>? _saldoStream;
  bool _isRefreshing = false;

  // Nilai konstan visual dideklarasikan di tingkat kelas demi efisiensi render (No Memory Leak)
  static const LinearGradient _premiumCardGradient = LinearGradient(
    colors: [
      WarnaDesaPay.primary,
      Color(0xFF1E40AF), // Royal Blue gelap untuk dimensi kedalaman visual
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

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _inisialisasiStreamSaldo();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// Membangun koneksi pipa data reaktif ke Firestore berdasarkan ID pengguna aktif
  void _inisialisasiStreamSaldo() {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      _saldoStream = _saldoService.streamSaldo(currentUser.uid);
    }
  }

  /// Simulasi manual trigger refresh untuk memberikan animasi taktil premium pada ikon
  Future<void> _manualRefreshTrigger() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });
    
    _rotationController.repeat();

    // Memberikan delay jeda visual agar animasi rotasi berputar halus setara GoPay/OVO
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;
    
    _rotationController.stop();
    _rotationController.reset();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  /// Helper format mata uang Rupiah internal berbasis int (Type-Safe & No Crash)
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
            // 1. DEKORASI ORNAMEN LINGKARAN ABSTRAK (PREMIUM FINTECH GLOWING STYLE)
            // =========================================================================
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
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
            // 2. KONTEN DYNAMIC STREAM BUILDER (ANTI INFINITE REBUILD)
            // =========================================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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
                        const SizedBox(height: 14),
                        StreamBuilder<int>(
                          stream: _saldoStream,
                          initialData: 0,
                          builder: (context, snapshot) {
                            final int saldoAktif = snapshot.data ?? 0;
                            
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatKeRupiah(saldoAktif),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // =========================================================================
                  // 3. REVOLVING REFRESH BUTTON (ANIMATED GENTLE SPLASH)
                  // =========================================================================
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: RotationTransition(
                      turns: _rotationController,
                      child: IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                        tooltip: "Perbarui Tampilan",
                        onPressed: _isRefreshing ? null : _manualRefreshTrigger,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
