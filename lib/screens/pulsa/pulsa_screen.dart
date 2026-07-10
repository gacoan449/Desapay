import 'package:flutter/material.dart';

import '../../config/warna.dart';
import '../../services/digiflazz_service.dart';

class PulsaScreen extends StatefulWidget {
  const PulsaScreen({super.key});

  @override
  State<PulsaScreen> createState() => _PulsaScreenState();
}

class _PulsaScreenState extends State<PulsaScreen> {
  final TextEditingController nomorController = TextEditingController();
  final DigiflazzService _digiflazzService = DigiflazzService();

  List<dynamic> _daftarPulsaReguler = [];

  bool _sedangMemuat = false;

  String _operatorTerdeteksi = "";

  @override
  void dispose() {
    nomorController.dispose();
    super.dispose();
  }

  //==================================================
  // DETEKSI OPERATOR OTOMATIS
  //==================================================

  void _deteksiOperatorOtomatis(String nomor) {
    if (nomor.length < 4) {
      setState(() {
        _operatorTerdeteksi = "";
        _daftarPulsaReguler = [];
      });
      return;
    }

    String prefix = nomor.substring(0, 4);

    String operator = "";

    if ([
      "0811",
      "0812",
      "0813",
      "0821",
      "0822",
      "0823",
      "0851",
      "0852",
      "0853"
    ].contains(prefix)) {
      operator = "TELKOMSEL";
    }

    else if ([
      "0814",
      "0815",
      "0816",
      "0855",
      "0856",
      "0857",
      "0858"
    ].contains(prefix)) {
      operator = "INDOSAT";
    }

    else if ([
      "0817",
      "0818",
      "0819",
      "0877",
      "0878",
      "0859"
    ].contains(prefix)) {
      operator = "XL";
    }

    else if ([
      "0831",
      "0832",
      "0833",
      "0838"
    ].contains(prefix)) {
      operator = "AXIS";
    }

    else if ([
      "0895",
      "0896",
      "0897",
      "0898",
      "0899"
    ].contains(prefix)) {
      operator = "THREE";
    }

    else if ([
      "0881",
      "0882",
      "0883",
      "0884",
      "0885",
      "0886",
      "0887",
      "0888",
      "0889"
    ].contains(prefix)) {
      operator = "SMARTFREN";
    }

    if (operator != _operatorTerdeteksi && operator.isNotEmpty) {
      setState(() {
        _operatorTerdeteksi = operator;
      });

      _ambilProdukPulsa(operator);
    }
  }

  //==================================================
  // AMBIL PRODUK DIGIFLAZZ
  //==================================================

  Future<void> _ambilProdukPulsa(String operator) async {
    setState(() {
      _sedangMemuat = true;
    });

    List<dynamic> semuaProduk =
        await _digiflazzService.ambilSemuaProduk();

    List<dynamic> hasil = semuaProduk.where((item) {

      String kategori =
          (item["category"] ?? "").toString().toUpperCase();

      String brand =
          (item["brand"] ?? "").toString().toUpperCase();

      return kategori == "PULSA" &&
          brand.contains(operator);

    }).toList();

    hasil.sort((a, b) {

      return (a["price"] ?? 0)
          .compareTo(b["price"] ?? 0);

    });

    setState(() {
      _daftarPulsaReguler = hasil;
      _sedangMemuat = false;
    });
  }

  //==================================================
  // BUILD
  //==================================================

  @override
  Widget build(BuildContext context) {return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Pulsa"),
        centerTitle: true,
        elevation: 0,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Nomor Tujuan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: nomorController,
                keyboardType: TextInputType.phone,

                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),

                onChanged: (value) {
                  setState(() {});
                  _deteksiOperatorOtomatis(value);
                },

                decoration: InputDecoration(

                  filled: true,
                  fillColor: Colors.grey.shade100,

                  hintText: "08xxxxxxxxxx",

                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                  ),

                  prefixIcon: const Icon(
                    Icons.phone_android,
                    color: Colors.blue,
                  ),

                  suffix: _operatorTerdeteksi.isEmpty
                      ? null
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _operatorTerdeteksi,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_operatorTerdeteksi.isNotEmpty)

                Text(
                  "Pilih Nominal Pulsa $_operatorTerdeteksi",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),

              const SizedBox(height: 12),

              Expanded(

                child: _sedangMemuat

                    ? const Center(
                        child: CircularProgressIndicator(),
                      )

                    : nomorController.text.length < 4

                        ? const Center(
                            child: Text(
                              "Masukkan nomor HP terlebih dahulu",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          )

                        : _daftarPulsaReguler.isEmpty

                            ? const Center(
                                child: Text(
                                  "Produk tidak ditemukan atau IP belum di-whitelist",
                                  textAlign: TextAlign.center,
                                ),
                              )

                            : GridView.builder(

                                itemCount: _daftarPulsaReguler.length,

                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(

                                  crossAxisCount: 2,

                                  crossAxisSpacing: 12,

                                  mainAxisSpacing: 12,

                                  childAspectRatio: 1.35,

                                ),

                                itemBuilder: (context, index) {

                                  final produk =
                                      _daftarPulsaReguler[index];

                                  return Container(

                                    decoration: BoxDecoration(

                                      color: Colors.white,

                                      borderRadius:
                                          BorderRadius.circular(18),

                                      boxShadow: [

                                        BoxShadow(

                                          color: Colors.grey.withOpacity(0.15),

                                          blurRadius: 8,

                                          offset: const Offset(0, 3),

                                        )

                                      ],

                                    ),

                                    child: Material(

                                      color: Colors.transparent,

                                      child: InkWell(

                                        borderRadius:
                                            BorderRadius.circular(18),

                                        onTap: () {

                                          _prosesKonfirmasiBayar(produk);

                                        },

                                        child: Padding(

                                          padding:
                                              const EdgeInsets.all(12),

                                          child: Column(

                                            mainAxisAlignment:
                                                MainAxisAlignment.center,

                                            children: [

                                              const Icon(
                                                Icons.phone_android,
                                                color: Colors.orange,
                                                size: 28,
                                              ),

                                              const SizedBox(height: 10),

                                              Text(
                                                produk["product_name"] ?? "-",
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),

                                              const SizedBox(height: 8),

                                              Text(
                                                "Rp ${produk["price"]}",
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
     }
 Future<void> _prosesKonfirmasiBayar(dynamic produk) async {

    final setuju = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi Pembelian"),
          content: Text(
            "Produk : ${produk['product_name']}\n\n"
            "Nomor : ${nomorController.text}\n\n"
            "Harga : Rp ${produk['price']}\n\n"
            "Lanjutkan pembelian?",
          ),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Batal"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Bayar"),
            ),

          ],
        );
      },
    );

    if (setuju != true) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final hasil = await _digiflazzService.kirimTransaksi(
      buyerSkuCode: produk["buyer_sku_code"],
      customerNo: nomorController.text,
    );

    if (mounted) {
      Navigator.pop(context);
    }

    final status =
        (hasil["status"] ?? "GAGAL").toString().toUpperCase();

    final pesan =
        hasil["sn"] ??
        hasil["message"] ??
        "Tidak ada keterangan dari server.";

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(

          title: Row(
            children: [

              Icon(
                status == "GAGAL"
                    ? Icons.cancel
                    : Icons.check_circle,
                color: status == "GAGAL"
                    ? Colors.red
                    : Colors.green,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  status == "GAGAL"
                      ? "Transaksi Gagal"
                      : "Transaksi Diproses",
                ),
              ),

            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                "Produk",
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              Text(
                produk["product_name"] ?? "-",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Nomor",
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              Text(
                nomorController.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Status",
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              Text(
                status,
                style: TextStyle(
                  color: status == "GAGAL"
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Keterangan",
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              Text(pesan),

            ],
          ),

          actions: [

            ElevatedButton(
              onPressed: () {

                Navigator.pop(context);

                if (status != "GAGAL") {

                  nomorController.clear();

                  setState(() {
                    _operatorTerdeteksi = "";
                    _daftarPulsaReguler.clear();
                  });

                }

              },
              child: const Text("Selesai"),
            ),

          ],
        );
      },
    );
  }

}
