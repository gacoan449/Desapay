import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart';
import 'payment_screen.dart';

class TopupSaldoScreen extends StatefulWidget {
  const TopupSaldoScreen({super.key});

  @override
  State<TopupSaldoScreen> createState() => _TopupSaldoScreenState();
}

class _TopupSaldoScreenState extends State<TopupSaldoScreen> {

  final DigiflazzService _digiflazzService = DigiflazzService();

  final TextEditingController _nominalController =
      TextEditingController();

  int _saldo = 0;

  bool _loadingSaldo = true;

  @override
  void initState() {
    super.initState();
    _ambilSaldo();
  }

  Future<void> _ambilSaldo() async {
    try {
      final saldo = await _digiflazzService.cekSaldoModal();

      if (!mounted) return;

      setState(() {
        _saldo = saldo;
        _loadingSaldo = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingSaldo = false;
      });
    }
  }

  String rupiah(int angka) {
    String hasil = angka.toString();

    final reg = RegExp(r'(\d)(?=(\d{3})+(?!\d))');

    return "Rp ${hasil.replaceAllMapped(reg, (m) => "${m[1]}.")}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        title: const Text(
          "Isi Saldo DesaPay",
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),

        children: [

          Container(
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: WarnaDesaPay.primary,
              borderRadius: BorderRadius.circular(20),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Text(
                  "Saldo Modal Anda",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 8),

                _loadingSaldo
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text(
                        rupiah(_saldo),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                const SizedBox(height: 6),

                const Text(
                  "Saldo Digiflazz akan digunakan untuk transaksi pelanggan.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "Masukkan Nominal Top Up",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _nominalController,

            keyboardType: TextInputType.number,

            decoration: InputDecoration(
              prefixText: "Rp ",

              hintText: "Contoh 50000",

              filled: true,

              fillColor: Colors.white,

              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),

                borderSide: BorderSide(
                  color: WarnaDesaPay.primary,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Minimal Top Up Rp10.000",
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.account_balance_wallet),
              style: ElevatedButton.styleFrom(
                backgroundColor: WarnaDesaPay.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              label: const Text(
                "LANJUTKAN PEMBAYARAN",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                final nominal = int.tryParse(
                  _nominalController.text.replaceAll(".", ""),
                );

                if (nominal == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Masukkan nominal terlebih dahulu.",
                      ),
                    ),
                  );
                  return;
                }

                if (nominal < 10000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Minimal Top Up Rp10.000",
                      ),
                    ),
                  );
                  return;
                }

                _prosesMintaTiket(
                  nominal,
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.amber.shade300,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Informasi",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10),

                Text(
                  "• Nominal bebas.\n"
                  "• Minimal Top Up Rp10.000.\n"
                  "• Setelah tiket dibuat silakan transfer sesuai nominal.\n"
                  "• Saldo otomatis masuk setelah pembayaran diterima Digiflazz.",
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }Future<void> _prosesMintaTiket(int nominal) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi Top Up"),
          content: Text(
            "Buat tiket deposit sebesar ${rupiah(nominal)} ?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Lanjut"),
            ),
          ],
        );
      },
    );

    if (konfirmasi != true) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final hasil = await _digiflazzService.mintaTiketDeposit(
      jumlahNominal: nominal,
    );

    if (mounted) Navigator.pop(context);

    if (hasil.isNotEmpty && hasil["rc"] == "00") {
      final dataPembayaran = {
        "data": {
          "payment_name":
              "Transfer Bank ${hasil["bank"] ?? "BCA"}",
          "amount": hasil["amount"] ?? nominal,
          "reference":
              hasil["deposit_id"] ??
                  "DEP-${DateTime.now().millisecondsSinceEpoch}",
          "status": hasil["status"] ?? "UNPAID",
          "pay_code": hasil["pay_code"] ??
              hasil["owner_name"] ??
              "-",
          "qr_url": hasil["qr_url"],
        }
      };

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            data: dataPembayaran,
          ),
        ),
      );

      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          hasil["message"] ??
              "Gagal membuat tiket deposit.",
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }
}
