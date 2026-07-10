import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart';

class PaketScreen extends StatefulWidget {
  const PaketScreen({super.key});

  @override
  State<PaketScreen> createState() => _PaketScreenState();
}

class _PaketScreenState extends State<PaketScreen> {

  final TextEditingController nomorController =
      TextEditingController();

  final DigiflazzService _digiflazzService =
      DigiflazzService();

  List<dynamic> daftarPaket = [];

  bool loading = false;

  String operator = "";

  @override
  void dispose() {
    nomorController.dispose();
    super.dispose();
  }

  // ==========================
  // DETEKSI OPERATOR OTOMATIS
  // ==========================

  void deteksiOperator(String nomor) {

    if (nomor.length < 4) {
      setState(() {
        operator = "";
        daftarPaket = [];
      });
      return;
    }

    String prefix = nomor.substring(0, 4);

    if ([
      '0811',
      '0812',
      '0813',
      '0821',
      '0822',
      '0823',
      '0851',
      '0852',
      '0853'
    ].contains(prefix)) {
      operator = "TELKOMSEL";
    }

    else if ([
      '0814',
      '0815',
      '0816',
      '0855',
      '0856',
      '0857',
      '0858'
    ].contains(prefix)) {
      operator = "INDOSAT";
    }

    else if ([
      '0817',
      '0818',
      '0819',
      '0877',
      '0878',
      '0859'
    ].contains(prefix)) {
      operator = "XL";
    }

    else if ([
      '0831',
      '0832',
      '0833',
      '0838'
    ].contains(prefix)) {
      operator = "AXIS";
    }

    else if ([
      '0895',
      '0896',
      '0897',
      '0898',
      '0899'
    ].contains(prefix)) {
      operator = "THREE";
    }

    else if ([
      '0881',
      '0882',
      '0883',
      '0884',
      '0885',
      '0886',
      '0887',
      '0888',
      '0889'
    ].contains(prefix)) {
      operator = "SMARTFREN";
    }

    else {
      operator = "";
    }

    setState(() {});

    if (operator.isNotEmpty) {
      ambilProduk(operator);
    }
  }

  // ==========================
  // AMBIL PRODUK DIGIFLAZZ
  // ==========================

  Future<void> ambilProduk(String brand) async {

    setState(() {
      loading = true;
    });

    List<dynamic> semuaProduk =
        await _digiflazzService.ambilSemuaProduk();

    daftarPaket = semuaProduk.where((item) {

      String kategori =
          (item['category'] ?? "")
              .toString()
              .toUpperCase();

      String merk =
          (item['brand'] ?? "")
              .toString()
              .toUpperCase();

      return kategori.contains("DATA") &&
          merk.contains(brand);

    }).toList();

    daftarPaket.sort(
      (a, b) =>
          (a['price'] ?? 0)
              .compareTo(b['price'] ?? 0),
    );

    setState(() {
      loading = false;
    });
  }

  // ==========================
  // BUILD
  // ==========================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Paket Data",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [const Text(
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
              onChanged: deteksiOperator,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: "08xxxxxxxxxx",
                hintStyle: const TextStyle(
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(
                  Icons.phone_android,
                  color: Colors.green,
                ),
                suffixText:
                    operator.isEmpty ? null : operator,
                suffixStyle: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Colors.green,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (operator.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Text(
                  "Operator : $operator",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),

            const SizedBox(height: 18),

            Expanded(
              child: loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : nomorController.text.length < 4
                      ? const Center(
                          child: Text(
                            "Masukkan nomor HP terlebih dahulu",
                          ),
                        )
                      : daftarPaket.isEmpty
                          ? const Center(
                              child: Text(
                                "Produk belum tersedia atau IP belum di-whitelist.",
                              ),
                            )
                          : GridView.builder(
                              itemCount:
                                  daftarPaket.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.4,
                              ),
                              itemBuilder:
                                  (context, index) {

                                final produk =
                                    daftarPaket[index];

                                return InkWell(
                                  borderRadius:
                                      BorderRadius.circular(
                                          16),
                                  onTap: () {
                                    prosesBayar(
                                        produk);
                                  },
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(
                                            12),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(
                                              16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors
                                              .grey
                                              .withOpacity(
                                                  0.15),
                                          blurRadius: 10,
                                          offset:
                                              const Offset(
                                                  0, 3),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: [

                                        Icon(
                                          Icons.wifi,
                                          color: Colors
                                              .green,
                                          size: 32,
                                        ),

                                        const SizedBox(
                                            height: 8),

                                        Text(
                                          produk[
                                                  'product_name'] ??
                                              "-",
                                          textAlign:
                                              TextAlign
                                                  .center,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                          style:
                                              const TextStyle(
                                            color: Colors
                                                .black87,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize: 13,
                                          ),
                                        ),

                                        const SizedBox(
                                            height: 8),

                                        Text(
                                          "Rp ${produk['price']}",
                                          style:
                                              const TextStyle(
                                            color: Colors
                                                .green,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
                     // =========================================
  // PROSES PEMBELIAN LANGSUNG KE DIGIFLAZZ
  // =========================================

  Future<void> prosesBayar(dynamic produk) async {

    bool? setuju = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Konfirmasi Pembelian",
          ),
          content: Text(
            "Beli\n\n"
            "${produk['product_name']}\n\n"
            "Nomor : ${nomorController.text}\n"
            "Harga : Rp ${produk['price']} ?",
          ),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Batal"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    Map<String, dynamic> hasil =
        await _digiflazzService.kirimTransaksi(
      buyerSkuCode: produk['buyer_sku_code'],
      customerNo: nomorController.text,
    );

    if (mounted) {
      Navigator.pop(context);
    }

    String status =
        (hasil['status'] ?? "GAGAL").toString();

    String pesan =
        hasil['message'] ??
        hasil['sn'] ??
        "Menunggu respon server.";

    Color warna =
        status.toUpperCase() == "SUKSES"
            ? Colors.green
            : Colors.orange;

    IconData icon =
        status.toUpperCase() == "SUKSES"
            ? Icons.check_circle
            : Icons.access_time;

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
            ),

            title: Row(
              children: [

                Icon(
                  icon,
                  color: warna,
                ),

                const SizedBox(width: 8),

                Text(
                  status,
                  style: TextStyle(
                    color: warna,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),

            content: Text(
              "Produk : ${produk['product_name']}\n\n"
              "Nomor : ${nomorController.text}\n\n"
              "$pesan",
            ),

            actions: [

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {

                  Navigator.pop(context);

                  nomorController.clear();

                  setState(() {
                    operator = "";
                    daftarPaket.clear();
                  });

                },
                child: const Text("Selesai"),
              ),

            ],
          );
        },
      );
    }
  }
                     }
