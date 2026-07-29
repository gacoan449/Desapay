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
    // Menembak API secara asinkron
    final result = await _apiService.getProdukByKategori(widget.kategori);
    
    // Urutkan berdasarkan harga dari yang termurah
    result.sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));

    if (mounted) {
      setState(() {
        _produkList = result;
        _isLoadingData = false;
      });
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
    
    // TODO: Arahkan ke form konfirmasi PIN atau langsung tembak API Transaksi Digiflazz
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessingTransaction = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksi diproses!")));
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
                      // Menyesuaikan dengan key JSON Digiflazz
                      final sku = produk['buyer_sku_code'];
                      final nama = produk['product_name'];
                      // Tambahkan margin keuntungan Anda (misal + Rp 1500 dari harga asli Digiflazz)
                      final hargaAsli = produk['price'] as int;
                      final hargaJual = hargaAsli + 1500; 
                      
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
