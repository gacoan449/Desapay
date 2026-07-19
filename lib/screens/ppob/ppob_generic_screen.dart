import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Import Konfigurasi & Reusable Widget
import '../../config/warna.dart';
import '../../widgets/menu_item.dart'; // Untuk mendapatkan CustomBounce

/// Layar Sapu Jagat (Generic) untuk menangani multi-kategori PPOB via Digiflazz
/// (Game, PDAM, BPJS, TV Kabel, Internet, dll)
class PpobGenericScreen extends StatefulWidget {
  final String kategori; // Nama layanan (Cth: "PDAM Nasional", "Topup Game")
  
  const PpobGenericScreen({super.key, required this.kategori});

  @override
  State<PpobGenericScreen> createState() => _PpobGenericScreenState();
}

class _PpobGenericScreenState extends State<PpobGenericScreen> {
  final TextEditingController _nomorController = TextEditingController();
  final FocusNode _nomorFocus = FocusNode();
  
  bool _isLoading = false;
  String? _selectedSku; // Menyimpan SKU produk Digiflazz yang dipilih

  // =======================================================================
  // DUMMY DATA: Representasi respons API Digiflazz (Buyer SKU Code)
  // Nantinya ini diisi dinamis dari service pemanggilan API berdasarkan widget.kategori
  // =======================================================================
  late final List<Map<String, dynamic>> _produkList;

  @override
  void initState() {
    super.initState();
    // Membangun data dummy yang cerdas berdasarkan kategori yang diklik
    _produkList = _generateMockDigiflazzData(widget.kategori);
  }

  @override
  void dispose() {
    _nomorController.dispose();
    _nomorFocus.dispose();
    super.dispose();
  }

  // Helper pemformatan Rupiah
  String _formatRupiah(int nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(nominal);
  }

  // Simulator respons API Digiflazz
  List<Map<String, dynamic>> _generateMockDigiflazzData(String kategori) {
    if (kategori.toLowerCase().contains("game")) {
      return [
        {'sku': 'ML_1', 'nama': '53 Diamonds', 'harga': 14500, 'desc': 'Mobile Legends'},
        {'sku': 'ML_2', 'nama': '77 Diamonds', 'harga': 21000, 'desc': 'Mobile Legends'},
        {'sku': 'FF_1', 'nama': '140 Diamonds', 'harga': 25000, 'desc': 'Free Fire'},
        {'sku': 'PUBG_1', 'nama': '60 UC', 'harga': 15000, 'desc': 'PUBG Mobile'},
      ];
    } else if (kategori.toLowerCase().contains("pdam") || kategori.toLowerCase().contains("bpjs")) {
      return [
        {'sku': 'CEK_TAGIHAN', 'nama': 'Cek Tagihan $kategori', 'harga': 0, 'desc': 'Biaya admin Rp 2.500'},
      ];
    } else {
      return [
        {'sku': 'GEN_1', 'nama': 'Paket Basic', 'harga': 50000, 'desc': 'Layanan standar'},
        {'sku': 'GEN_2', 'nama': 'Paket Premium', 'harga': 100000, 'desc': 'Layanan super cepat'},
      ];
    }
  }

  void _prosesTransaksi() {
    // Validasi form dasar
    if (_nomorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Mohon masukkan Nomor Pelanggan / ID terlebih dahulu."),
          backgroundColor: WarnaDesaPay.danger,
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    if (_selectedSku == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Mohon pilih layanan/nominal yang tersedia."),
          backgroundColor: WarnaDesaPay.warning,
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    // TODO: Arahkan ke Layar Konfirmasi / PIN Transaksi sebelum tembak API Digiflazz
    setState(() => _isLoading = true);
    
    // Simulasi loading jaringan
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Berhasil memproses SKU: $_selectedSku"),
            backgroundColor: WarnaDesaPay.success,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Menentukan hint text secara cerdas
    final String hintInput = widget.kategori.toLowerCase().contains("game") 
        ? "Masukkan ID Game & Server" 
        : "Masukkan Nomor Pelanggan";

    final IconData iconInput = widget.kategori.toLowerCase().contains("game") 
        ? Icons.sports_esports_rounded 
        : Icons.confirmation_number_rounded;

    // Mendapatkan detail produk yang sedang dipilih untuk BottomBar
    final Map<String, dynamic>? selectedProduct = _selectedSku != null 
        ? _produkList.firstWhere((p) => p['sku'] == _selectedSku)
        : null;

    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          widget.kategori,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3),
        ),
      ),
      body: Stack(
        children: [
          // ==========================================
          // 1. LAYER KONTEN UTAMA (SCROLLABLE)
          // ==========================================
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 120), // Bottom padding untuk area floating bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INFO HEADER BANNER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WarnaDesaPay.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: WarnaDesaPay.primary.withOpacity(0.15), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: WarnaDesaPay.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Pastikan nomor yang Anda masukkan benar. Kesalahan input bukan tanggung jawab sistem.",
                          style: TextStyle(color: WarnaDesaPay.textMain.withOpacity(0.8), fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // INPUT NOMOR PELANGGAN
                Text("Data Pelanggan", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: WarnaDesaPay.textMain)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: TextField(
                    controller: _nomorController,
                    focusNode: _nomorFocus,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: hintInput,
                      hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, fontSize: 14),
                      prefixIcon: Icon(iconInput, color: WarnaDesaPay.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // DAFTAR PRODUK (GRID/LIST)
                Text("Pilih Layanan", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: WarnaDesaPay.textMain)),
                const SizedBox(height: 12),
                
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6, // Mengatur rasio lebar:tinggi kartu
                  ),
                  itemCount: _produkList.length,
                  itemBuilder: (context, index) {
                    final produk = _produkList[index];
                    final bool isSelected = _selectedSku == produk['sku'];

                    return CustomBounce(
                      onTap: () {
                        // Menutup keyboard saat user memilih produk
                        _nomorFocus.unfocus();
                        setState(() => _selectedSku = produk['sku']);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? WarnaDesaPay.primary.withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? WarnaDesaPay.primary : WarnaDesaPay.lightField,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              produk['nama'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800, 
                                fontSize: 14, 
                                color: isSelected ? WarnaDesaPay.primary : WarnaDesaPay.textMain
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              produk['harga'] == 0 ? "Cek Detail" : _formatRupiah(produk['harga']),
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 13, 
                                color: isSelected ? WarnaDesaPay.primary : WarnaDesaPay.textSub
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              produk['desc'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ==========================================
          // 2. LAYER BOTTOM ACTION BAR (FLOATING)
          // ==========================================
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), // Padding bawah ekstra untuk area gesture swipe OS
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))
                ]
              ),
              child: Row(
                children: [
                  // Sisi Kiri: Informasi Harga Total
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Pembayaran", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          selectedProduct != null 
                              ? (selectedProduct['harga'] == 0 ? "-" : _formatRupiah(selectedProduct['harga']))
                              : "Rp 0",
                          style: const TextStyle(color: WarnaDesaPay.textMain, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Sisi Kanan: Tombol Eksekusi
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WarnaDesaPay.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isLoading ? null : _prosesTransaksi,
                    child: _isLoading 
                        ? const SizedBox(
                            width: 20, height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          )
                        : const Text("Lanjutkan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
