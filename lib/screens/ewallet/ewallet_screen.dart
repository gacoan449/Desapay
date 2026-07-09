import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../../config/warna.dart';
// Pastikan jalur import DigiflazzService di bawah ini sudah sesuai dengan proyek Anda
import '../../services/digiflazz_service.dart'; 

class EwalletScreen extends StatefulWidget {
  const EwalletScreen({super.key});

  @override
  State<EwalletScreen> createState() => _EwalletScreenState();
}

class _EwalletScreenState extends State<EwalletScreen> {
  // Variabel untuk mengontrol status menu dan nama E-Wallet yang dipilih
  bool _isMenuDetailAktif = false;
  String _ewalletTerpilih = "";

  final TextEditingController _nomorController = TextEditingController();
  final DigiflazzService _digiflazzService = DigiflazzService();
  
  List<dynamic> _daftarProdukEwallet = [];
  bool _sedangMemuat = false;

  // Fungsi otomatis mengambil data dari Digiflazz dan menyaring berdasarkan brand E-Wallet
  Future<void> _panggilProdukEwallet(String brand) async {
    setState(() {
      _sedangMemuat = true;
    });

    List<dynamic> semuaProduk = await _digiflazzService.ambilSemuaProduk();
    
    // Menyaring produk berdasarkan kategori E-Money dan mencocokkan nama brand (DANA, OVO, dll)
    // Digiflazz biasanya menggunakan huruf besar untuk brand e-money
    List<dynamic> produkDisaring = semuaProduk.where((produk) {
      String kategori = (produk['category'] ?? '').toString().toUpperCase();
      String namaBrand = (produk['brand'] ?? '').toString().toUpperCase();
      
      // Filter untuk kategori E-Money / E-Wallet dan mencocokkan substring nama brand
      return (kategori.contains('E-MONEY') || kategori.contains('VOUCHER')) && 
             namaBrand.contains(brand.toUpperCase());
    }).toList();

    setState(() {
      _daftarProdukEwallet = produkDisaring;
      _sedangMemuat = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: Text(_isMenuDetailAktif ? "Top Up $_ewalletTerpilih" : "Top Up E-Wallet"),
        // Tombol kembali jika sedang berada di dalam menu detail produk
        leading: _isMenuDetailAktif 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _isMenuDetailAktif = false; // Kembali ke daftar E-Wallet utama
                  _nomorController.clear();  // Bersihkan inputan nomor HP
                });
              },
            )
          : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isMenuDetailAktif ? _tampilanFormEwallet() : _tampilanMenuUtama(),
      ),
    );
  }

  // TAMPILAN AWAL: Daftar pilihan E-Wallet jualan Anda
  Widget _tampilanMenuUtama() {
    return ListView(
      children: [
        _menu(Icons.account_balance_wallet, "DANA", "Top Up Saldo DANA"),
        _menu(Icons.account_balance_wallet, "OVO", "Top Up Saldo OVO"),
        _menu(Icons.account_balance_wallet, "GoPay", "Top Up Saldo GoPay"),
        _menu(Icons.account_balance_wallet, "ShopeePay", "Top Up Saldo ShopeePay"),
        _menu(Icons.account_balance_wallet, "LinkAja", "Top Up Saldo LinkAja"),
      ],
    );
  }

  // Widget pembantu untuk membuat baris menu E-Wallet
  Widget _menu(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: WarnaDesaPay.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: WarnaDesaPay.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          setState(() {
            _ewalletTerpilih = title;
            _isMenuDetailAktif = true; // Buka form pengisian
          });
          _panggilProdukEwallet(title); // Ambil harga produk dari Digiflazz khusus brand ini
        },
      ),
    );
  }

  // TAMPILAN KEDUA: Muncul otomatis setelah salah satu E-Wallet ditekan
  Widget _tampilanFormEwallet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nomor Handphone / ID Akun",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nomorController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: "Contoh: 081234567890",
            prefixIcon: const Icon(Icons.phone_android),
            labelText: "Nomor $_ewalletTerpilih",
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Pilih Nominal Saldo $_ewalletTerpilih",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _sedangMemuat
              ? const Center(child: CircularProgressIndicator())
              : _daftarProdukEwallet.isEmpty
                  ? const Center(
                      child: Text(
                        "Produk tidak ditemukan.\nPastikan IP sudah di-whitelist di Digiflazz.",
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _daftarProdukEwallet.length,
                      itemBuilder: (context, index) {
                        final produk = _daftarProdukEwallet[index];
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
                                  SnackBar(content: Text("Isi nomor HP $_ewalletTerpilih terlebih dahulu!")),
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

  // Dialog Popup Konfirmasi Bayar E-Wallet
  void _prosesKonfirmasiBayar(dynamic produk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Pembelian"),
        content: Text(
            "Apakah Anda yakin ingin mengisi ${produk['product_name']} ke nomor ${_nomorController.text} seharga Rp ${produk['price']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Bagian ini siap kita hubungkan ke fungsi transaksi nembak saldo di langkah berikutnya
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
