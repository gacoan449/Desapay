import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../../config/warna.dart';
// Hubungkan ke service digiflazz yang sudah dibuat sebelumnya
import '../../services/digiflazz_service.dart'; 

class PlnScreen extends StatefulWidget {
  const PlnScreen({super.key});

  @override
  State<PlnScreen> createState() => _PlnScreenState();
}

class _PlnScreenState extends State<PlnScreen> {
  // Variabel untuk mengontrol menu mana yang sedang aktif
  bool _isMenuTokenAktif = false; 

  final TextEditingController _nomorController = TextEditingController();
  final DigiflazzService _digiflazzService = DigiflazzService();
  
  List<dynamic> _daftarToken = [];
  bool _sedangMemuat = false;

  // Fungsi otomatis mengambil data dari Digiflazz
  Future<void> _panggilProdukDigiflazz() async {
    setState(() {
      _sedangMemuat = true;
    });

    List<dynamic> semuaProduk = await _digiflazzService.ambilSemuaProduk();
    
    // Menyaring khusus produk PLN Prabayar saja
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
        // Tombol kembali jika sedang berada di dalam menu Token
        leading: _isMenuTokenAktif 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _isMenuTokenAktif = false; // Kembali ke menu utama PLN
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

  // TAMPILAN AWAL: Berisi pilihan Token PLN dan Tagihan PLN
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
                _isMenuTokenAktif = true; // Aktifkan halaman isi token
              });
              _panggilProdukDigiflazz(); // Ambil harga dari server
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

  // TAMPILAN KEDUA: Muncul otomatis setelah tombol "Token PLN" ditekan
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

  // Dialog Popup Konfirmasi Bayar
  void _prosesKonfirmasiBayar(dynamic produk) {
    showDialog(
      context: context,
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
            onPressed: () {
              Navigator.pop(context);
              // Bagian ini siap kita hubungkan ke fungsi transaksi nembak saldo
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Memproses ${produk['buyer_sku_code']} ke ${_nomorController.text}")),
              );
            },
            child: const Text("Bayar Sekarang"),
          ),
        ],
      ),
    );
  }
}
