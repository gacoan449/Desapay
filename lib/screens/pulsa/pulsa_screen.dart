import 'dart:convert';
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

  void _deteksiOperatorOtomatis(String nomor) {
    if (nomor.length < 4) {
      setState(() {
        _operatorTerdeteksi = "";
        _daftarPulsaReguler = [];
      });
      return;
    }

    String awalan = nomor.substring(0, 4);
    String namaBrand = "";

    if (['0811', '0812', '0813', '0821', '0822', '0823', '0851', '0852', '0853'].contains(awalan)) {
      namaBrand = "TELKOMSEL";
    } else if (['0814', '0815', '0816', '0855', '0856', '0857', '0858'].contains(awalan)) {
      namaBrand = "INDOSAT";
    } else if (['0817', '0818', '0819', '0859', '0877', '0878'].contains(awalan)) {
      namaBrand = "XL";
    } else if (['0831', '0832', '0833', '0838'].contains(awalan)) {
      namaBrand = "AXIS";
    } else if (['0895', '0896', '0897', '0898', '0899'].contains(awalan)) {
      namaBrand = "THREE";
    } else if (['0881', '0882', '0883', '0884', '0885', '0886', '0887', '0888', '0889'].contains(awalan)) {
      namaBrand = "SMARTFREN";
    }

    if (namaBrand.isNotEmpty && namaBrand != _operatorTerdeteksi) {
      setState(() {
        _operatorTerdeteksi = namaBrand;
      });
      _panggilProdukPulsaReguler(namaBrand);
    }
  }

  Future<void> _panggilProdukPulsaReguler(String brand) async {
    setState(() {
      _sedangMemuat = true;
    });

    List<dynamic> semuaProduk = await _digiflazzService.ambilSemuaProduk();

    List<dynamic> produkDisaring = semuaProduk.where((produk) {
      String kategori = (produk['category'] ?? '').toString().toUpperCase();
      String namaBrand = (produk['brand'] ?? '').toString().toUpperCase();
      return kategori == 'PULSA' && namaBrand.contains(brand);
    }).toList();

    produkDisaring.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));

    setState(() {
      _daftarPulsaReguler = produkDisaring;
      _sedangMemuat = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: const Text("Pulsa"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nomor Tujuan",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nomorController,
              keyboardType: TextInputType.phone,
              onChanged: _deteksiOperatorOtomatis,
              decoration: InputDecoration(
                hintText: "08xxxxxxxxxx",
                prefixIcon: const Icon(Icons.phone_android),
                suffixText: _operatorTerdeteksi.isNotEmpty ? _operatorTerdeteksi : null,
                suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            if (_operatorTerdeteksi.isNotEmpty)
              Text(
                "Pilih Nominal Pulsa $_operatorTerdeteksi",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            const SizedBox(height: 15),
            Expanded(
              child: _sedangMemuat
                  ? const Center(child: CircularProgressIndicator())
                  : nomorController.text.length < 4
                      ? const Center(child: Text("Masukkan nomor HP terlebih dahulu."))
                      : _daftarPulsaReguler.isEmpty
                          ? const Center(child: Text("Produk tidak ditemukan atau IP belum di-whitelist"))
                          : GridView.builder(
                              itemCount: _daftarPulsaReguler.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.8,
                              ),
                              itemBuilder: (context, index) {
                                final produk = _daftarPulsaReguler[index];
                                return Card(
                                  elevation: 3,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      _prosesKonfirmasiBayar(produk);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            produk['product_name'] ?? '-',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Rp ${produk['price']}",
                                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
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
    );
  }

  void _prosesKonfirmasiBayar(dynamic produk) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Pembelian"),
        content: Text("Apakah Anda yakin ingin membeli ${produk['product_name']} ke nomor ${nomorController.text} seharga Rp ${produk['price']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              Map<String, dynamic> hasil = await _digiflazzService.kirimTransaksi(
                buyerSkuCode: produk['buyer_sku_code'],
                customerNo: nomorController.text,
              );

              if (mounted) Navigator.pop(context);

              String statusTransaksi = hasil['status'] ?? 'Gagal';
              String pesanServer = hasil['sn'] ?? hasil['message'] ?? 'Tidak ada pesan';

              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      statusTransaksi == 'Gagal' ? "❌ Transaksi Gagal" : "⏳ Transaksi Diproses",
                      style: TextStyle(
                        color: statusTransaksi == 'Gagal' ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      "Produk: ${produk['product_name']}\n"
                      "Tujuan: ${nomorController.text}\n"
                      "Status Server: $statusTransaksi\n\n"
                      "Keterangan/SN:\n$pesanServer",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (statusTransaksi != 'Gagal') {
                            nomorController.clear();
                            setState(() {
                              _operatorTerdeteksi = "";
                              _daftarPulsaReguler = [];
                            });
                          }
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text("Bayar Sekarang"),
          ),
        ],
      ),
    );
  }
}
