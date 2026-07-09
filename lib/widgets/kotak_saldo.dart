import 'package:flutter/material.dart';
import '../../config/warna.dart';
// Hubungkan ke layanan API Digiflazz Anda
import '../../services/digiflazz_service.dart'; 

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
    _ambilSaldoTerbaru(); // Saldo otomatis ditarik saat aplikasi pertama dibuka
  }

  // Fungsi mandiri untuk mengambil sisa saldo modal dari Digiflazz
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
      // Gunakan warna utama DesaPay Anda sebagai latar belakang kotak
      color: WarnaDesaPay.primary, 
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.between,
          children: [
            // Bagian Informasi Angka Saldo
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

            // Tombol Refresh Kecil untuk update saldo tanpa perlu restart aplikasi
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
