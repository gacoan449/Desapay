import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart';

class KotakSaldo extends StatefulWidget {
  const KotakSaldo({super.key});

  @override
  State<KotakSaldo> createState() => _KotakSaldoState();
}

class _KotakSaldoState extends State<KotakSaldo> with SingleTickerProviderStateMixin {
  final DigiflazzService _digiflazzService = DigiflazzService();
  late AnimationController _rotationController;
  
  int _saldoAgen = 0;
  bool _memuatSaldo = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _ambilSaldoTerbaru(); 
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _ambilSaldoTerbaru() async {
    if (!mounted) return;
    setState(() {
      _memuatSaldo = true;
    });
    
    // Memutar ikon refresh selama loading berjalan
    _rotationController.repeat();
    
    final int hasilSaldo = await _digiflazzService.cekSaldoModal();
    
    if (!mounted) return;
    
    _rotationController.stop();
    _rotationController.reset();

    setState(() {
      _saldoAgen = hasilSaldo;
      _memuatSaldo = false;
    });
  }

  // Fungsi pemformat mata uang rupiah agar rapi dengan pemisah titik
  String _formatRupiah(dynamic angka) {
    final int value = int.tryParse(angka.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gradasi Royal Blue Premium disinkronkan dengan WarnaDesaPay Baru
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

            // ==========================================
            // 2. KONTEN UTAMA TEXT & ACTION
            // ==========================================
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
                              "Saldo Modal DesaPay",
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
                        _memuatSaldo 
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white.withOpacity(0.9),
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Text(
                              "Rp ${_formatRupiah(_saldoAgen)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // 3. REVOLVING REFRESH BUTTON (ANIMATED)
                  // ==========================================
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
                        tooltip: "Perbarui Saldo",
                        onPressed: _memuatSaldo ? null : _ambilSaldoTerbaru,
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
