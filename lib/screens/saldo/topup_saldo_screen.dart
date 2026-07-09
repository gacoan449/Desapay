import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart'; 
// Panggil halaman struk pembayaran yang dikirimkan tadi
import 'payment_screen.dart'; 

class TopupSaldoScreen extends StatefulWidget {
  const TopupSaldoScreen({super.key});

  @override
  State<TopupSaldoScreen> createState() => _TopupSaldoScreenState();
}

class _TopupSaldoScreenState extends State<TopupSaldoScreen> {
  final DigiflazzService _digiflazzService = DigiflazzService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: const Text("Isi Saldo DesaPay"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Pilih Nominal",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _nominal("Rp10.000", 10000),
          _nominal("Rp20.000", 20000),
          _nominal("Rp50.000", 50000),
          _nominal("Rp100.000", 100000),
          _nominal("Rp200.000", 200000),
          _nominal("Rp500.000", 500000),
          _nominal("Rp1.000.000", 1000000),
        ],
      ),
    );
  }

  Widget _nominal(String teksNominal, int angkaMurni) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.account_balance_wallet),
        ),
        title: Text(teksNominal),
        subtitle: const Text("Saldo akan masuk otomatis"),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          _prosesMintaTiket(teksNominal, angkaMurni);
        },
      ),
    );
  }

  void _prosesMintaTiket(String teksNominal, int angkaMurni) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Isi Saldo"),
        content: Text("Apakah Anda ingin membuat tiket deposit sebesar $teksNominal?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog konfirmasi

              // Tampilkan lingkaran loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              // Ambil tiket deposit ke Digiflazz
              Map<String, dynamic> hasil = await _digiflazzService.mintaTiketDeposit(
                jumlahNominal: angkaMurni,
              );

              if (mounted) Navigator.pop(context); // Tutup loading

              // Cek jika request disetujui server (Response Code: 00)
              if (hasil.isNotEmpty && hasil['rc'] == '00') {
                // Modifikasi struktur data agar cocok dengan kebutuhan data di PaymentScreen
                Map<String, dynamic> dataBungkus = {
                  "data": {
                    "payment_name": "Transfer Bank ${hasil['bank'] ?? 'BCA'}",
                    "amount": hasil['amount'] ?? angkaMurni,
                    "reference": "DEP-${DateTime.now().millisecondsSinceEpoch}",
                    "status": "UNPAID / BELUM TRANSFER",
                    // Jika kelak versi live menyertakan kode bayar atau url gambar QRIS
                    "pay_code": "A/N: ${hasil['owner_name'] ?? '-'}", 
                    "qr_url": null 
                  }
                };

                // Buka halaman PaymentScreen secara otomatis dengan membawa data tiket
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(data: dataBungkus),
                    ),
                  );
                }
              } else {
                // Tampilkan notifikasi jika server menolak permintaan tiket
                String pesanGagal = hasil['message'] ?? 'Gagal menghubungi server';
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal: $pesanGagal"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Proses"),
          ),
        ],
      ),
    );
  }
}
