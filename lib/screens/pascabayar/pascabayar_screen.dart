import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Untuk mendapatkan UID
import '../../config/warna.dart';
import '../../services/firestore_service.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium untuk Tombol Eksekusi
class CustomBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const CustomBounce({super.key, required this.child, required this.onTap});

  @override
  State<CustomBounce> createState() => _CustomBounceState();
}

class _CustomBounceState extends State<CustomBounce> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

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

  List<Map<String, dynamic>> _daftarProdukPPOB = [];
  Map<String, dynamic>? _produkTerpilih;
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

  //==========================================
  // AMBIL PRODUK DARI FIRESTORE (SIAP GO LIVE)
  //==========================================
  Future<void> _ambilDaftarProdukPascabayar() async {
    setState(() => _sedangMemuatProduk = true);

    try {
      List<Map<String, dynamic>> semuaProduk = await FirestoreService.ambilProdukAktif();
      
      List<Map<String, dynamic>> produkDisaring = semuaProduk.where((produk) {
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

      // Urutkan berdasarkan nama agar rapi di dropdown
      produkDisaring.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

      setState(() => _daftarProdukPPOB = produkDisaring);
    } catch (_) {
      setState(() => _daftarProdukPPOB = []);
    }

    setState(() => _sedangMemuatProduk = false);
  }

  String rupiah(dynamic angka) {
    int value = int.tryParse(angka.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  IconData _getLayananIcon() {
    if (widget.jenisLayanan == "PDAM") return Icons.water_drop_rounded;
    if (widget.jenisLayanan == "BPJS") return Icons.health_and_safety_rounded;
    return Icons.tv_rounded;
  }

  //==========================================
  // SIMULASI CEK TAGIHAN (INQUIRY)
  //==========================================
  Future<void> _prosesCekTagihan() async {
    if (_produkTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih wilayah / penyedia layanan Anda!"), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_nomorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan Nomor Pelanggan / ID Kontrak Anda!"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // MENSIMULASIKAN INQUIRY KE SERVER (Delay 2 detik)
    // Di tahap produksi, ganti delay ini dengan panggilan ke Firebase Cloud Functions Anda.
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) Navigator.pop(context);

    // Data Simulasi Tagihan (Ganti dengan response asli dari Cloud Functions Anda)
    String namaPelanggan = "Pelanggan DesaPay";
    int nominalTagihan = 50000; // Contoh tagihan pokok
    
    // Ambil margin dari Firestore sebagai Biaya Admin
    int biayaAdmin = (_produkTerpilih!['margin'] as num? ?? 2500).toInt(); 
    int totalBayarLengkap = nominalTagihan + biayaAdmin; 

    _tampilkanBottomSheetInvoice(namaPelanggan, nominalTagihan, biayaAdmin, totalBayarLengkap);
  }

  //==========================================
  // PREMIUM BOTTOM SHEET INVOICE
  //==========================================
  void _tampilkanBottomSheetInvoice(String nama, int tagihanPokok, int admin, int total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24, left: 24, right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text("Detail Tagihan Pascabayar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildInvoiceRow("Jenis Layanan", widget.jenisLayanan),
              _buildInvoiceRow("Penyedia / Wilayah", _produkTerpilih!['name'] ?? '-'),
              _buildInvoiceRow("ID Pelanggan", _nomorController.text.trim()),
              _buildInvoiceRow("Nama Pelanggan", nama),
              _buildInvoiceRow("Biaya Pokok", "Rp ${rupiah(tagihanPokok)}"),
              _buildInvoiceRow("Biaya Admin Loket", "Rp ${rupiah(admin)}"),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Pembayaran", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    "Rp ${rupiah(total)}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WarnaDesaPay.primary),
                  )
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarnaDesaPay.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _eksekusiBayarKeFirestore(tagihanPokok, admin, total);
                  },
                  child: const Text("Konfirmasi & Bayar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //==========================================
  // EKSEKUSI TRANSAKSI KE FIRESTORE
  //==========================================
  void _eksekusiBayarKeFirestore(int tagihanPokok, int admin, int total) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'USER_UNKNOWN';
      final refId = 'DPAY-PASCA-${DateTime.now().millisecondsSinceEpoch}';

      final trxData = {
        'ref_id': refId,
        'uid': uid,
        'sku': _produkTerpilih!['sku'],
        'productName': _produkTerpilih!['name'],
        'category': _produkTerpilih!['category'],
        'brand': _produkTerpilih!['brand'],
        'customerNo': _nomorController.text.trim(),
        'amount': total,        // Total tagihan + admin yang dipotong dari saldo user
        'cost': tagihanPokok,   // Modal / Tagihan pokok
        'margin': admin,        // Keuntungan loket / Admin
        'status': 'PENDING',    // Akan diproses oleh Cloud Functions
        'isTest': false,
      };

      await FirestoreService.simpanTransaksi(trxData);

      if (mounted) {
        Navigator.pop(context); 
        _tampilkanStatusSheet(true, "Pembayaran tagihan ${_produkTerpilih!['name']} berhasil dikirim ke antrean server.", total);
        _nomorController.clear();
        setState(() {
          _produkTerpilih = null;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _tampilkanStatusSheet(false, "Gagal memproses transaksi: $e", 0);
      }
    }
  }

  //==========================================
  // PREMIUM DIGITAL RECEIPT SHEET
  //==========================================
  void _tampilkanStatusSheet(bool isSukses, String pesan, int total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSukses ? Icons.access_time_filled_rounded : Icons.cancel_rounded,
                size: 72,
                color: isSukses ? Colors.orange : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                isSukses ? "Transaksi Diproses" : "Transaksi Gagal",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildInvoiceRow("Layanan", widget.jenisLayanan),
                    _buildInvoiceRow("ID Pelanggan", _nomorController.text.trim()),
                    if (isSukses) _buildInvoiceRow("Total Bayar", "Rp ${rupiah(total)}"),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Keterangan", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(width: 16),
                          Expanded(child: Text(pesan, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87), textAlign: TextAlign.end)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSukses ? WarnaDesaPay.primary : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final IconData iconLayanan = _getLayananIcon();

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        title: Text(
          "Tagihan ${widget.jenisLayanan}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _sedangMemuatProduk
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // WADAH LAYOUT DROPDOWN & INPUT PREMIUM
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pilihan Dropdown Wilayah/Jenis Layanan
                        Text(
                          "Pilih Wilayah / Penyedia Layanan",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, dynamic>>(
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              hint: Text("Klik untuk memilih...", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                              value: _produkTerpilih,
                              items: _daftarProdukPPOB.map((produk) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: produk,
                                  child: Text(
                                    produk['name'] ?? '-',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                                  ),
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
                        Text(
                          "Nomor Pelanggan / ID Kontrak",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nomorController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            hintText: "Masukkan ID Pelanggan Kontrak",
                            hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 0),
                            prefixIcon: Icon(iconLayanan, color: WarnaDesaPay.primary),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 36),

                  // Tombol Cek Tagihan Utama
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomBounce(
                      onTap: _prosesCekTagihan,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: WarnaDesaPay.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: WarnaDesaPay.primary?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "PERIKSA DATA TAGIHAN",
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
