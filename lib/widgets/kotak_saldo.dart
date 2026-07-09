import 'package:flutter/material.dart';
import '../config/warna.dart';
import '../services/digiflazz_service.dart'; 

class KotakSaldo extends StatefulWidget {
  const KotakSaldo({super.key});

  @override
  State<KotakSaldo> createState() => _KotakSaldoState();
}

class _KotakSaldoState extends State<KotakSaldo> {
  final DigiflazzService _digiflazzService = DigiflazzService();
  
  int _saldoAgen = 0;
  bool _memuatSaldo = false;

  @override
  void initState() {
    super.initState();
    _ambilSaldoTerbaru(); 
  }

  Future<void> _ambilSaldoTerbaru() async {
    if (!mounted) return;
    setState(() {
      _memuatSaldo = true;
    });
    
    int hasilSaldo = await _digiflazzService.cekSaldoModal();
    
    if (!mounted) return;
    setState(() {
      _saldoAgen = hasilSaldo;
      _memuatSaldo = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: WarnaDesaPay.primary, 
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          // KUNCINYA DI SINI: Sudah diperbaiki menggunakan kapital yang benar agar tidak error build
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Saldo Modal DesaPay",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _memuatSaldo 
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      "Rp $_saldoAgen",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: "Perbarui Saldo",
                onPressed: _ambilSaldoTerbaru,
              ),
            )
          ],
        ),
      ),
    );
  }
}
