import 'package:flutter/material.dart';
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
    if (_produkTerpilih == null || _nomorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih produk dan masukkan nomor pelanggan."), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Inquiry dan pembayaran pascabayar belum tersedia. Tidak ada transaksi yang dibuat."), behavior: SnackBarBehavior.floating),
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
