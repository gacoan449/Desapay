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

  //==========================================
  // DETEKSI OPERATOR OTOMATIS
  //==========================================

  void deteksiOperator(String nomor) {

    if (nomor.length < 4) {

      setState(() {
        operator = "";
        daftarPaket.clear();
      });

      return;
    }

    final prefix = nomor.substring(0, 4);

    if ([
      "0811","0812","0813",
      "0821","0822","0823",
      "0851","0852","0853"
    ].contains(prefix)) {

      operator = "TELKOMSEL";

    } else if ([
      "0814","0815","0816",
      "0855","0856","0857","0858"
    ].contains(prefix)) {

      operator = "INDOSAT";

    } else if ([
      "0817","0818","0819",
      "0859","0877","0878"
    ].contains(prefix)) {

      operator = "XL";

    } else if ([
      "0831","0832","0833","0838"
    ].contains(prefix)) {

      operator = "AXIS";

    } else if ([
      "0895","0896","0897",
      "0898","0899"
    ].contains(prefix)) {

      operator = "THREE";

    } else if ([
      "0881","0882","0883",
      "0884","0885","0886",
      "0887","0888","0889"
    ].contains(prefix)) {

      operator = "SMARTFREN";

    } else {

      operator = "";

    }

    setState(() {});

    if (operator.isNotEmpty) {
      ambilProduk(operator);
    } else {
      daftarPaket.clear();
    }
  }

  //==========================================
  // AMBIL PRODUK DARI DIGIFLAZZ
  //==========================================

  Future<void> ambilProduk(String brand) async {

    setState(() {
      loading = true;
    });

    try {

      final semuaProduk =
          await _digiflazzService.ambilSemuaProduk();

      daftarPaket =
          semuaProduk.where((item) {

        final kategori =
            (item["category"] ?? "")
                .toString()
                .toUpperCase();

        final merk =
            (item["brand"] ?? "")
                .toString()
                .toUpperCase();

        return kategori.contains("DATA") &&
               merk.contains(brand);

      }).toList();

      daftarPaket.sort(
        (a, b) =>
            (a["price"] ?? 0)
                .compareTo(
            b["price"] ?? 0),
      );

    } catch (e) {

      daftarPaket = [];

    }

    setState(() {
      loading = false;
    });

  }

  //==========================================
  // HITUNG HARGA JUAL
  //==========================================

  int hargaJual(int modal) {

    if (modal < 10000) {
      return modal + 1000;
    }

    if (modal < 50000) {
      return modal + 1500;
    }

    if (modal < 100000) {
      return modal + 2000;
    }

    return modal + 3000;
  }

  //==========================================
  // FORMAT RUPIAH
  //==========================================

  String rupiah(int angka) {

    return angka
        .toString()
        .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

  }

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

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(

              "Nomor Tujuan",

              style: TextStyle(

                fontSize: 16,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 10),

            TextField(

              controller: nomorController,

              keyboardType: TextInputType.phone,

              onChanged: deteksiOperator,

              decoration: InputDecoration(

                hintText: "08xxxxxxxxxx",

                prefixIcon: const Icon(

                  Icons.phone_android,

                  color: Colors.green,

                ),

                suffixIcon: operator.isEmpty
                    ? null
                    : Container(

                        alignment: Alignment.center,

                        width: 90,

                        child: Text(

                          operator,

                          style: const TextStyle(

                            color: Colors.green,

                            fontWeight: FontWeight.bold,

                          ),

                        ),

                      ),

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(

                  borderRadius: BorderRadius.circular(15),

                  borderSide: BorderSide.none,

                ),

              ),

            ),

            const SizedBox(height: 20),

            Expanded(

              child: loading

                  ? const Center(

                      child: CircularProgressIndicator(),

                    )

                  : daftarPaket.isEmpty

                      ? const Center(

                          child: Text(

                            "Masukkan nomor HP untuk melihat paket.",

                            style: TextStyle(

                              color: Colors.grey,

                            ),

                          ),

                        )

                      : ListView.builder(

                          itemCount: daftarPaket.length,

                          itemBuilder: (context, index) {

                            final produk =
                                daftarPaket[index];

                            final modal =
                                produk["price"] ?? 0;

                            final jual =
                                hargaJual(modal);

                            return Card(

                              elevation: 2,

                              margin: const EdgeInsets.only(

                                bottom: 12,

                              ),

                              shape: RoundedRectangleBorder(

                                borderRadius:
                                    BorderRadius.circular(15),

                              ),

                              child: ExpansionTile(

                                leading: const CircleAvatar(

                                  backgroundColor: Colors.green,

                                  child: Icon(

                                    Icons.wifi,

                                    color: Colors.white,

                                  ),

                                ),

                                title: Text(

                                  produk["product_name"] ?? "",

                                  style: const TextStyle(

                                    fontWeight: FontWeight.bold,

                                  ),

                                ),

                                subtitle: Text(

                                  "Rp ${rupiah(jual)}",

                                  style: const TextStyle(

                                    color: Colors.green,

                                    fontWeight: FontWeight.bold,

                                  ),

                                ),

                                children: [

                                  Padding(

                                    padding:
                                        const EdgeInsets.all(16),

                                    child: Column(

                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [

                                        Text(

                                          produk["desc"] ??
                                              "Produk Paket Data",

                                          style: const TextStyle(

                                            color: Colors.grey,

                                          ),

                                        ),

                                        const SizedBox(height: 15),

                                        SizedBox(

                                          width: double.infinity,

                                          child: ElevatedButton.icon(

                                            style:
                                                ElevatedButton.styleFrom(

                                              backgroundColor:
                                                  Colors.green,

                                              foregroundColor:
                                                  Colors.white,

                                            ),

                                            icon: const Icon(

                                              Icons.shopping_cart,

                                            ),

                                            label: const Text(

                                              "BELI SEKARANG",

                                            ),

                                            onPressed: () {

                                              prosesBayar(produk);

                                            },

                                          ),

                                        ),

                                      ],

                                    ),

                                  ),

                                ],

                              ),

                            );

                          },

                        ),

            ),

          ],

        ),

      ),

    );

  }
  //==========================================
  // PROSES PEMBELIAN
  //==========================================

  Future<void> prosesBayar(dynamic produk) async {

    if (nomorController.text.isEmpty) {
      return;
    }

    final modal = produk["price"] ?? 0;
    final jual = hargaJual(modal);

    bool? lanjut = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Konfirmasi Pembelian"),
          content: Text(
            "Produk : ${produk["product_name"]}\n\n"
            "Nomor : ${nomorController.text}\n\n"
            "Harga : Rp ${rupiah(jual)}",
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

    if (lanjut != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final hasil =
        await _digiflazzService.kirimTransaksi(
      buyerSkuCode: produk["buyer_sku_code"],
      customerNo: nomorController.text,
    );

    if (mounted) {
      Navigator.pop(context);
    }

    String status =
        (hasil["status"] ?? "PENDING")
            .toString()
            .toUpperCase();

    String pesan =
        hasil["message"] ??
        hasil["sn"] ??
        "Menunggu respon server.";

    Color warna = Colors.orange;
    IconData icon = Icons.access_time;

    if (status == "SUKSES") {
      warna = Colors.green;
      icon = Icons.check_circle;
    } else if (status == "GAGAL") {
      warna = Colors.red;
      icon = Icons.cancel;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: Row(
            children: [

              Icon(
                icon,
                color: warna,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color: warna,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            ],
          ),

          content: Text(
            "Produk : ${produk["product_name"]}\n\n"
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
