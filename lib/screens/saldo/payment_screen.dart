import 'package:flutter/material.dart';
import '../../config/warna.dart';
// Hubungkan ke service digiflazz
import '../../services/digiflazz_service.dart'; 

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const PaymentScreen({
    super.key,
    required this.data,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final DigiflazzService _digiflazzService = DigiflazzService();
  late Map<String, dynamic> _currentTxData;

  @override
  void initState() {
    super.initState();
    // Menyimpan data kiriman awal ke dalam variabel state lokal
    _currentTxData = widget.data["data"] ?? {};
  }

  // Fungsi untuk mengecek status terbaru ke server Digiflazz
  Future<void> _periksaStatusPembayaran() async {
    // Tampilkan lingkaran memuat (loading)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Ambil nominal angka untuk validasi status
    int nominalAngka = _currentTxData["amount"] ?? 0;

    // Ambil status paling baru dari server Digiflazz
    Map<String, dynamic> hasilTerbaru = await _digiflazzService.cekStatusDeposit(
      jumlahNominal: nominalAngka,
    );

    if (mounted) Navigator.pop(context); // Tutup lingkaran loading

    // Perbarui status tampilan di layar secara langsung
    setState(() {
      if (hasilTerbaru.isNotEmpty && hasilTerbaru['rc'] == '00') {
        _currentTxData["status"] = "PAID / BERHASIL";
      } else {
        // Mode simulasi testing: jika belum bayar sesungguhnya akan tetap menampilkan info dari server
        _currentTxData["status"] = hasilTerbaru["message"] ?? "UNPAID / BELUM BAYAR";
      }
    });

    // Tampilkan notifikasi kecil di bawah layar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status Terbaru: ${_currentTxData["status"]}"),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: const Text("Pembayaran"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 70,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _currentTxData["payment_name"] ?? "Deposit Digiflazz",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _item(
                    "Nominal",
                    "Rp ${_currentTxData["amount"]}",
                  ),
                  _item(
                    "Reference",
                    _currentTxData["reference"] ?? "REF-AUTOMATIC",
                  ),
                  _item(
                    "Status",
                    _currentTxData["status"] ?? "UNPAID",
                  ),
                  if (_currentTxData["pay_code"] != null)
                    _item(
                      "Kode Bayar",
                      _currentTxData["pay_code"],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_currentTxData["qr_url"] != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Scan QRIS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Image.network(
                      _currentTxData["qr_url"],
                      height: 250,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("CEK STATUS"),
              onPressed: () {
                _periksaStatusPembayaran(); // Jalankan fungsi cek status saat ditekan
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: SelectableText(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
