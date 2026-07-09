import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/warna.dart';
// Hubungkan ke service digiflazz yang sudah kita update
import '../../services/digiflazz_service.dart'; 

class PlnScreen extends StatefulWidget {
  const PlnScreen({super.key});

  @override
  State<PlnScreen> createState() => _PlnScreenState();
}

class _PlnScreenState extends State<PlnScreen> {
  bool _isMenuTokenAktif = false; 

  final TextEditingController _nomorController = TextEditingController();
  final DigiflazzService _digiflazzService = DigiflazzService();
  
  List<dynamic> _daftarToken = [];
  bool _sedangMemuat = false;

  Future<void> _panggilProdukDigiflazz() async {
    setState(() {
      _sedangMemuat = true;
    });

    List<dynamic> semuaProduk = await _digiflazzService.ambilSemuaProduk();
    
    List<dynamic> produkPln = semuaProduk.where((produk) {
      return produk['category'] == 'PLN' && produk['brand'] == 'PLN';
    }).toList();

    setState(() {
      _daftarToken = produkPln;
      _sedangMemuat = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isMenuTokenAktif ? "Beli Token PLN" : "PLN"),
        leading: _isMenuTokenAktif 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _isMenuTokenAktif = false;
                });
              },
            )
          : null,
      ),
      backgroundColor: WarnaDesaPay.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isMenuTokenAktif ? _tampilanFormToken() : _tampilanMenuUtama(),
      ),
    );
  }

  Widget _tampilanMenuUtama() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.flash_on, color: Colors.orange),
            title: const Text("Token PLN"),
            subtitle: const Text("Beli token listrik prabayar"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              setState(() {
                _isMenuTokenAktif = true;
              });
              _panggilProdukDigiflazz();
            },
          ),
        ),
        const SizedBox(height: 15),
        Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.blue),
            title: const Text("Tagihan PLN"),
            subtitle: const Text("Bayar listrik pascabayar"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Menu Tagihan PLN belum otomatis")),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tampilanFormToken() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nomor Meter / ID Pelanggan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nomorController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Contoh: 53123456789",
            prefixIcon: Icon(Icons.electric_bolt),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Pilih Nominal Token",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _sedangMemuat
              ? const Center(child: CircularProgressIndicator())
              : _daftarToken.isEmpty
                  ? const Center(child: Text("Produk tidak ditemukan atau IP belum di-whitelist"))
                  : ListView.builder(
                      itemCount: _daftarToken.length,
                      itemBuilder: (context, index) {
                        final produk = _daftarToken[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(produk['product_name'] ?? '-'),
                            subtitle: Text("Kode: ${produk['buyer_sku_code']}"),
                            trailing: Text(
                              "Rp ${produk['price']}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              if (_nomorController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Isi nomor meteran terlebih dahulu!")),
                                );
                                return;
                              }
                              _prosesKonfirmasiBayar(produk);
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // DIALOG KONFIRMASI YANG SUDAH TERHUBUNG KE TRANSAKSI ASLI DIGIFLAZZ
  void _prosesKonfirmasiBayar(dynamic produk) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Pembelian"),
        content: Text(
            "Apakah Anda yakin ingin membeli ${produk['product_name']} ke nomor ${_nomorController.text} seharga Rp ${produk['price']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup popup tanya

              // Munculkan lingkaran loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              // Tembak API Transaksi
              Map<String, dynamic> hasil = await _digiflazzService.kirimTransaksi(
                buyerSkuCode: produk['buyer_sku_code'],
                customerNo: _nomorController.text,
              );

              if (mounted) Navigator.pop(context); // Tutup lingkaran loading

              String statusTransaksi = hasil['status'] ?? 'Gagal';
              String pesanServer = hasil['sn'] ?? hasil['message'] ?? 'Tidak ada pesan';

              // Munculkan struk hasil akhir
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
