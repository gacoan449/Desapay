import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart'; 

class PaketScreen extends StatefulWidget {
  const PaketScreen({super.key});

  @override
  State<PaketScreen> createState() => _PaketScreenState();
}

class _PaketScreenState extends State<PaketScreen> {
  final TextEditingController _nomorController = TextEditingController();
  final DigiflazzService _digiflazzService = DigiflazzService();

  List<dynamic> _daftarPaketData = [];
  bool _sedangMemuat = false;
  String _operatorTerdeteksi = "";

  void _deteksiOperatorOtomatis(String nomor) {
    if (nomor.length < 4) {
      setState(() {
        _operatorTerdeteksi = "";
        _daftarPaketData = [];
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
      _panggilProdukPaketData(namaBrand);
    }
  }

  Future<void> _panggilProdukPaketData(String brand) async {
    setState(() {
      _sedangMemuat = true;
    });

    List<dynamic> semuaProduk = await _digiflazzService.ambilSemuaProduk();

    List<dynamic> produkDisaring = semuaProduk.where((produk) {
      String kategori = (produk['category'] ?? '').toString().toUpperCase();
      String namaBrand = (produk['brand'] ?? '').toString().toUpperCase();
      return kategori.contains('DATA') && namaBrand.contains(brand);
    }).toList();

    setState(() {
      _daftarPaketData = produkDisaring;
      _sedangMemuat = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paket Data"),
      ),
      backgroundColor: WarnaDesaPay.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nomorController,
              keyboardType: TextInputType.phone,
              onChanged: _deteksiOperatorOtomatis,
              decoration: InputDecoration(
                hintText: "Masukkan Nomor HP",
                prefixIcon: const Icon(Icons.phone_android),
                suffixText: _operatorTerdeteksi.isNotEmpty ? _operatorTerdeteksi : null,
                suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            if (_operatorTerdeteksi.isNotEmpty)
              Text(
                "Pilihan Paket $_operatorTerdeteksi",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: _sedangMemuat
                  ? const Center(child: CircularProgressIndicator())
                  : _nomorController.text.length < 4
                      ? const Center(child: Text("Silakan masukkan nomor HP terlebih dahulu"))
                      : _daftarPaketData.isEmpty
                          ? const Center(child: Text("Produk tidak ditemukan atau IP belum di-whitelist"))
                          : GridView.builder(
                              itemCount: _daftarPaketData.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.5,
                              ),
                              itemBuilder: (context, index) {
                                final produk = _daftarPaketData[index];
                                return Card(
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
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 5),
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
        content: Text("Apakah Anda yakin ingin mengisi ${produk['product_name']} ke nomor ${_nomorController.text} seharga Rp ${produk['price']}?"),
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
                customerNo: _nomorController.text,
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
                      "Tujuan: ${_nomorController.text}\n"
                      "Status Server: $statusTransaksi\n\n"
                      "Keterangan/SN:\n$pesanServer",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (statusTransaksi != 'Gagal') {
                            _nomorController.clear();
                            setState(() {
                              _operatorTerdeteksi = "";
                              _daftarPaketData = [];
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
