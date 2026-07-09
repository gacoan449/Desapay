import 'package:flutter/material.dart';
import '../../config/warna.dart';
// Hubungkan ke service digiflazz
import '../../services/digiflazz_service.dart'; 

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

          // Kita panggil fungsi _nominal dengan mengirimkan Teks dan Angka Murni
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

  // Fungsi konfirmasi dan menembak tiket deposit ke Digiflazz
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
              Navigator.pop(context); // Tutup dialog tanya

              // Tampilkan loading screen
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              // Tembak API request deposit ke Digiflazz
              Map<String, dynamic> hasil = await _digiflazzService.mintaTiketDeposit(
                jumlahNominal: angkaMurni,
              );

              if (mounted) Navigator.pop(context); // Tutup loading screen

              String statusDeposit = hasil['rc'] == '00' ? 'Sukses' : 'Gagal';
              String pesanServer = hasil['message'] ?? 'Tidak ada pesan';
              
              // Digiflazz akan memberikan nominal unik baru di field 'amount'
              int nominalHarusDitransfer = hasil['amount'] ?? angkaMurni;

              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      statusDeposit == 'Gagal' ? "❌ Gagal Mengambil Tiket" : "✅ Tiket Deposit Berhasil",
                      style: TextStyle(
                        color: statusDeposit == 'Gagal' ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      statusDeposit == 'Gagal' 
                      ? "Pesan: $pesanServer"
                      : "Silakan transfer tepat sampai 3 angka terakhir:\n\n"
                        "💰 TOTAL: Rp $nominalHarusDitransfer\n"
                        "🏦 BANK: ${hasil['bank'] ?? 'BCA'}\n"
                        "👤 A/N: ${hasil['owner_name'] ?? '-'}\n\n"
                        "Keterangan: $pesanServer",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Paham"),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text("Proses"),
          ),
        ],
      ),
    );
  }
}
