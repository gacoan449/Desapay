import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/warna.dart';
import '../../widgets/menu_item.dart';
import '../../services/digiflazz_service.dart';

class PpobGenericScreen extends StatefulWidget {
  final String kategori;
  const PpobGenericScreen({super.key, required this.kategori});

  @override
  State<PpobGenericScreen> createState() => _PpobGenericScreenState();
}

class _PpobGenericScreenState extends State<PpobGenericScreen> {
  final TextEditingController _nomorController = TextEditingController();
  final FocusNode _nomorFocus = FocusNode();
  
  // Menggunakan Service Digiflazz yang baru
  final DigiflazzService _apiService = DigiflazzService();
  
  bool _isProcessingTransaction = false;
  bool _isLoadingData = true;
  String? _selectedSku; 
  Map<String, dynamic>? _selectedProductData;

  List<dynamic> _produkList = [];

  @override
  void initState() {
    super.initState();
    _fetchDataDigiflazz();
  }

  Future<void> _fetchDataDigiflazz() async {
    setState(() => _isLoadingData = true);
    
    try {
      // 1. Ambil SEMUA data menggunakan fungsi dari Service Anda
      final allProducts = await _apiService.ambilSemuaProduk();

      // 2. Pemetaan kategori dari UI ke "brand" atau "category" Digiflazz
      String targetKategori = "";
      if (widget.kategori.toLowerCase().contains("game")) targetKategori = "Games";
      else if (widget.kategori.toLowerCase().contains("pdam")) targetKategori = "PDAM";
      else if (widget.kategori.toLowerCase().contains("pln")) targetKategori = "PLN";
      else if (widget.kategori.toLowerCase().contains("e-wallet")) targetKategori = "E-Money";
      else targetKategori = widget.kategori;

      // 3. Filter produk agar hanya muncul yang sesuai kategori dan sedang aktif
      List<dynamic> filteredProducts = allProducts.where((p) {
        final category = p['category']?.toString().toLowerCase() ?? '';
        final brand = p['brand']?.toString().toLowerCase() ?? '';
        
        final isKategoriMatch = category.contains(targetKategori.toLowerCase()) || 
                                brand.contains(targetKategori.toLowerCase());
                                
        final isAktif = p['buyer_product_status'] == true && p['seller_product_status'] == true;
        
        return isKategoriMatch && isAktif;
      }).toList();

      // 4. Urutkan berdasarkan harga dari yang termurah
      filteredProducts.sort((a, b) {
        final int priceA = int.tryParse(a['price'].toString()) ?? 0;
        final int priceB = int.tryParse(b['price'].toString()) ?? 0;
        return priceA.compareTo(priceB);
      });

      if (mounted) {
        setState(() {
          _produkList = filteredProducts;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat produk: $e"), backgroundColor: WarnaDesaPay.danger),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomorController.dispose();
    _nomorFocus.dispose();
    super.dispose();
  }

  String _formatRupiah(int nominal) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(nominal);
  }

  void _prosesTransaksi() {
    if (_nomorController.text.trim().isEmpty || _selectedSku == null) return;
    setState(() => _isProcessingTransaction = true);
    
    // TODO: Nanti kita hubungkan ini ke _apiService.kirimTransaksi()
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessingTransaction = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksi sedang diproses...")));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        elevation: 0, backgroundColor: WarnaDesaPay.primary, foregroundColor: Colors.white, centerTitle: true,
        title: Text(widget.kategori, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nomorController, focusNode: _nomorFocus,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Masukkan Nomor/ID Tujuan",
                    filled: true, fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.numbers_rounded, color: WarnaDesaPay.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),
                
                // KONDISI RENDERING LAYAR
                if (_isLoadingData)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: WarnaDesaPay.primary)))
                else if (_produkList.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.inventory_2_outlined, size: 64, color: WarnaDesaPay.textSub.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text("Produk belum tersedia\natau sedang gangguan dari pusat.", textAlign: TextAlign.center, style: TextStyle(color: WarnaDesaPay.textSub)),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
                    ),
                    itemCount: _produkList.length,
                    itemBuilder: (context, index) {
                      final produk = _produkList[index];
                      // Sesuai JSON Digiflazz
                      final sku = produk['buyer_sku_code'];
                      final nama = produk['product_name'];
                      // Harga sudah dimarkup Rp 1.000 dari service Anda
                      final hargaJual = int.tryParse(produk['price'].toString()) ?? 0; 
                      
                      final isSelected = _selectedSku == sku;

                      return CustomBounce(
                        onTap: () {
                          _nomorFocus.unfocus();
                          setState(() {
                            _selectedSku = sku;
                            _selectedProductData = {'nama': nama, 'harga': hargaJual};
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? WarnaDesaPay.primary.withOpacity(0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? WarnaDesaPay.primary : WarnaDesaPay.lightField, width: isSelected ? 2 : 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(nama, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isSelected ? WarnaDesaPay.primary : WarnaDesaPay.textMain)),
                              const Spacer(),
                              Text(_formatRupiah(hargaJual), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? WarnaDesaPay.primary : WarnaDesaPay.textSub)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          
          // BOTTOM PANEL PEMBAYARAN
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: WarnaDesaPay.shadow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Pembayaran", style: TextStyle(fontSize: 11, color: WarnaDesaPay.textSub)),
                        Text(
                          _selectedProductData != null ? _formatRupiah(_selectedProductData!['harga']) : "Rp 0", 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: WarnaDesaPay.primary)
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WarnaDesaPay.primary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: (_isProcessingTransaction || _selectedSku == null) ? null : _prosesTransaksi,
                    child: _isProcessingTransaction 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Lanjutkan", style: TextStyle(fontWeight: FontWeight.bold)),
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
