import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../widgets/menu_item.dart';

class MetodePembayaranScreen extends StatelessWidget {
  final String nominal;

  const MetodePembayaranScreen({super.key, required this.nominal});

  @override
  Widget build(BuildContext context) {
    // Daftar channel pembayaran statis yang didukung oleh konfigurasi TriPay DesaPay
    final List<Map<String, String>> channels = [
      {'nama': 'QRIS (Otomatis/Instan)', 'kode': 'QRIS', 'tipe': 'E-Wallet & QR'},
      {'nama': 'BRIVA (Bank BRI)', 'kode': 'BRIVA', 'tipe': 'Virtual Account'},
      {'nama': 'BNI Virtual Account', 'kode': 'BNIVA', 'tipe': 'Virtual Account'},
      {'nama': 'BCA Virtual Account', 'kode': 'BCAVA', 'tipe': 'Virtual Account'},
      {'nama': 'Mandiri Virtual Account', 'kode': 'MANDIRIVA', 'tipe': 'Virtual Account'},
      {'nama': 'Alfamart', 'kode': 'ALFAMART', 'tipe': 'Gerai Retail'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      appBar: AppBar(
        title: const Text("Pilih Metode Bayar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: WarnaDesaPay.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final ch = channels[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WarnaDesaPay.primary.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    ch['kode'] == 'QRIS' ? Icons.qr_code_2_rounded : Icons.account_balance_wallet_rounded,
                    color: WarnaDesaPay.primary,
                  ),
                ),
                title: Text(
                  ch['nama']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: WarnaDesaPay.textMain),
                ),
                subtitle: Text(
                  ch['tipe']!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                onTap: () {
                  // Mengembalikan kode channel pembayaran ke layar pemanggil (TopupSaldoScreen)
                  Navigator.pop(context, ch['kode']);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
