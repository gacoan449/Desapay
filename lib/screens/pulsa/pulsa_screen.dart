import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/warna.dart';
// Hubungkan ke service digiflazz yang sudah kita buat sebelumnya
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

  // Fungsi otomatis membaca 4 angka pertama nomor HP pembeli untuk mendeteksi operator
  void _deteksiOperatorOtomatis(String nomor) {
    if (nomor.length < 4) {
      setState(() {
        _operatorTerdeteksi = "";
        _daftarPulsaReguler = [];
      });
      return;
    }

    // Ambil 4 angka terdepan (contoh: 0812, 0857)
    String awalan = nomor.substring(0, 4);
    String namaBrand = "";

    // Database prefix/awalan operator seluler Indonesia
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

    // Jika operator ditemukan dan berbeda dari yang sebelumnya, ambil data dari Digiflazz
    if (namaBrand.isNotEmpty && namaBrand != _operatorTerdeteksi) {
      setState(() {
        _operatorTerdeteksi = namaBrand;
      });
      _panggilProdukPulsaReguler(namaBrand);
    }
  }

  // Fungsi mengambil produk pulsa ke Digiflazz berdasarkan brand operator
  Future<void> _panggilProdukPulsaReguler(String brand) async {
    setState(() {
      _sedangMemuat = true;
    });

    List<dynamic> semuaProduk = await _digiflazzService.ambilSemuaProduk();

    // Menyaring produk khusus kategori Pulsa reguler (bukan paket data)
    List<dynamic> produkDisaring = semuaProduk.where((produk) {
      String kategori = (produk['category'] ?? '').toString().toUpperCase();
      String namaBrand = (produk['brand'] ?? '').toString().toUpperCase();

      // Memastikan kategori adalah PULSA dan mencocokkan nama operatornya
      return kategori == 'PULSA' && namaBrand.contains(brand);
    }).toList();

    // Mengurutkan produk berdasarkan harga terendah ke tertinggi agar tampilan rapi
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nomorController,
              keyboardType: TextInputType.phone,
              onChanged: _deteksiOperatorOtomatis, // Jalankan deteksi otomatis setiap mengetik angka baru
              decoration: InputDecoration(
                hintText: "08xxxxxxxxxx",
                prefixIcon: const Icon(Icons.phone_android),
                suffixText: _operatorTerdeteksi.isNotEmpty ? _operatorTerdeteksi : null,
                suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_operatorTerdeteksi.isNotEmpty)
              Text(
                "Pilih Nominal Pulsa $_operatorTerdeteksi",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 15),

            // Tampilan daftar nominal pulsa otomatis berbentuk grid kotak-kotak
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
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Rp ${produk['price']}",
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
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

  // Dialog Popup Transaksi Mandiri (Satu Halaman Tanpa File Tambahan)
  void _prosesKonfirmasiBayar(dynamic produk) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Pembelian"),
        content: Text(
            "Apakah Anda yakin ingin mengisi ${produk['product_name']} ke nomor ${nomorController.text} seharga Rp ${produk['price']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup popup dialog konfirmasi

              // Tampilkan indikator memuat (loading)
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              // Tembak transaksi pengisian pulsa reguler ke server Digiflazz
              Map<String, dynamic> hasil = await _digiflazzService.kirimTransaksi(
                buyerSkuCode: produk['buyer_sku_code'],
                customerNo: nomorController.text,
              );

              if (mounted) Navigator.pop(context); // Tutup indikator loading setelah server merespon

              String statusTransaksi = hasil['status'] ?? 'Gagal';
              String pesanServer = hasil['sn'] ?? hasil['message'] ?? 'Tidak ada pesan';

              // Tampilkan struk digital hasil transaksi pulsa
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      statusTransaksi == 'Gagal' ? "❌ Transaksi Gagal" : "⏳ Transaksi Diproses",
                      style: TextStyle(
                        color: statusTransaksi == 'Gagal' ? Colors.red : Colors.orange,
