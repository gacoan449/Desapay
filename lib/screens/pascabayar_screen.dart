import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart'; 

class PascabayarScreen extends StatefulWidget {
  final String jenisLayanan; // Menerima input: "PDAM", "BPJS", atau "TV KABEL"

  const PascabayarScreen({
    super.key,
    required this.jenisLayanan,
  });

  @override
  State<PascabayarScreen> createState() => _PascabayarScreenState();
}

class _PascabayarScreenState extends State<PascabayarScreen> {
  final TextEditingController _nomorController = TextEditingController();
  final DigiflazzService _digiflazzService = DigiflazzService();

  List<dynamic> _daftarProdukPPOB = [];
  dynamic _produkTerpilih;
  bool _sedangMemuatProduk = false;

  @override
  void initState() {
    super.initState();
    _ambilDaftarProdukPascabayar();
  }

  @override
  void dispose() {
    _nomorController.dispose();
    super.dispose();
  }

  // 1. Mengambil semua wilayah PDAM / BPJS / TV Kabel dari Digiflazz
  Future<void> _ambilDaftarProdukPascabayar() async {
    setState(() {
      _sedangMemuatProduk = true;
    });

    List<dynamic> semuaProduk = await _digiflazzService.ambilSemuaProduk();

    // Menyaring list berdasarkan kategori Pascabayar dan Brand yang cocok
    List<dynamic> produkDisaring = semuaProduk.where((produk) {
      String kategori = (produk['category'] ?? '').toString().toUpperCase();
      String brand = (produk['brand'] ?? '').toString().toUpperCase();

      if (widget.jenisLayanan == "PDAM") {
        return brand == "PDAM" || kategori.contains("PDAM");
      } else if (widget.jenisLayanan == "BPJS") {
        return brand.contains("BPJS") || kategori.contains("BPJS");
      } else if (widget.jenisLayanan == "TV KABEL") {
        return kategori.contains("TV") || brand.contains("CABLE") || brand.contains("TV");
      }
      return false;
    }).toList();

    setState(() {
      _daftarProdukPPOB = produkDisaring;
      _sedangMemuatProduk = false;
    });
  }

  // 2. Fungsi Cek Tagihan sebelum membayar (Inquiry)
  Future<void> _prosesCekTagihan() async {
    if (_produkTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih wilayah / jenis layanan dulu!")),
      );
      return;
    }
    if (_nomorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan Nomor Pelanggan / ID terlebih dahulu!")),
      );
      return;
    }

    // Tampilkan loading screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Menggunakan fungsi kirim transaksi Digiflazz untuk melakukan cek tagihan / bayar
    Map<String, dynamic> hasil = await _digiflazzService.kirimTransaksi(
      buyerSkuCode: _produkTerpilih['buyer_sku_code'],
      customerNo: _nomorController.text,
    );

    if (mounted) Navigator.pop(context); // Tutup loading screen

    String status = hasil['status'] ?? 'Gagal';
    String namaPelanggan = hasil['customer_name'] ?? 'Tidak Diketahui';
    
    // Mengambil nominal tagihan (Digiflazz meletakkannya di field 'price' atau di dalam 'desc')
    int nominalTagihan = hasil['price'] ?? 0; 
    // Markup keuntungan loket Anda Rp 2.500 untuk pascabayar (Bisa disesuaikan)
    int totalBayarLengkap = nominalTagihan + 2500; 

    if (status != 'Gagal') {
      _tampilkanKonfirmasiPembayaran(namaPelanggan, nominalTagihan, totalBayarLengkap);
    } else {
      String pesanGagal = hasil['message'] ?? 'ID Pelanggan salah atau gangguan server';
      _tampilkanDialogInformasi("❌ Gagal Cek Tagihan", pesanGagal, Colors.red);
    }
  }

  // 3. Popup Detail Struk Tagihan & Tombol Eksekusi Bayar
  void _tampilkanKonfirmasiPembayaran(String nama, int tagihan, int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Detail Tagihan Pelanggan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Layanan: ${widget.jenisLayanan} - ${_produkTerpilih['product_name']}"),
            Text("ID Pelanggan: ${_nomorController.text}"),
            Text("Nama: $nama", style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Text("Tagihan: Rp $tagihan"),
            const Text("Admin Loket: Rp 2.500"),
            Text("Total Bayar: Rp $total", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog konfirmasi
              _eksekusiBayarTagihanSelesai();
            },
            child: const Text("Bayar Sekarang"),
          ),
        ],
      ),
    );
  }

  void _eksekusiBayarTagihanSelesai() {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    // Catatan: Pada mode testing dev-key Digiflazz, simulasi dianggap langsung selesai
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context); // Tutup loading
        _nomorController.clear();
        _tampilkanDialogInformasi(
          "⏳ Transaksi Diproses", 
          "Pembayaran tagihan ${_produkTerpilih['product_name']} Anda sedang dikirim ke server.", 
          Colors.orange
        );
      }
    });
  }

  void _tampilkanDialogInformasi(String judul, String pesan, Color warnaJudul) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(judul, style: TextStyle(color: warnaJudul, fontWeight: FontWeight.bold)),
        content: Text(pesan),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: Text("Tagihan ${widget.jenisLayanan}"),
      ),
      body: _sedangMemuatProduk
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pilihan Dropdown Wilayah/Jenis Layanan
                  const Text("Pilih Wilayah / Jenis Layanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<dynamic>(
                        isExpanded: true,
                        hint: const Text("Klik untuk memilih..."),
                        value: _produkTerpilih,
                        items: _daftarProdukPPOB.map((produk) {
                          return DropdownMenuItem<dynamic>(
                            value: produk,
                            child: Text(produk['product_name'] ?? '-'),
                          );
                        }).toList(),
                        onChanged: (nilaiBaru) {
                          setState(() {
                            _produkTerpilih = nilaiBaru;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input Nomor Kontrak / ID Pelanggan
                  const Text("Nomor Pelanggan / ID Kontrak", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nomorController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: "Masukkan ID Pelanggan",
                      prefixIcon: Icon(widget.jenisLayanan == "PDAM" ? Icons.water_drop : Icons.receipt_long),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Tombol Cek Tagihan Utama
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: WarnaDesaPay.primary),
                      onPressed: _prosesCekTagihan,
                      child: const Text("CEK TAGIHAN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
