import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/warna.dart';
import '../../widgets/menu_item.dart'; 

class PpobGenericScreen extends StatefulWidget {
  final String kategori;
  
  const PpobGenericScreen({super.key, required this.kategori});

  @override
  State<PpobGenericScreen> createState() => _PpobGenericScreenState();
}

class _PpobGenericScreenState extends State<PpobGenericScreen> {
  final TextEditingController _nomorController = TextEditingController();
  final FocusNode _nomorFocus = FocusNode();
  
  bool _isLoading = false;
  String? _selectedSku; 

  late final List<Map<String, dynamic>> _produkList;

  @override
  void initState() {
    super.initState();
    _produkList = _generateMockDigiflazzData(widget.kategori);
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

  List<Map<String, dynamic>> _generateMockDigiflazzData(String kategori) {
    if (kategori.toLowerCase().contains("game")) {
      return [
        {'sku': 'ML_1', 'nama': '53 Diamonds', 'harga': 14500, 'desc': 'Mobile Legends'},
        {'sku': 'FF_1', 'nama': '140 Diamonds', 'harga': 25000, 'desc': 'Free Fire'},
      ];
    } else if (kategori.toLowerCase().contains("pdam") || kategori.toLowerCase().contains("bpjs")) {
      return [{'sku': 'CEK_TAGIHAN', 'nama': 'Cek Tagihan $kategori', 'harga': 0, 'desc': 'Biaya admin Rp 2.500'}];
    } else {
      return [
        {'sku': 'GEN_1', 'nama': 'Paket Basic', 'harga': 50000, 'desc': 'Layanan standar'},
        {'sku': 'GEN_2', 'nama': 'Paket Premium', 'harga': 100000, 'desc': 'Layanan cepat'},
      ];
    }
  }

  void _prosesTransaksi() {
    if (_nomorController.text.trim().isEmpty || _selectedSku == null) return;
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? selectedProduct = _selectedSku != null ? _produkList.firstWhere((p) => p['sku'] == _selectedSku) : null;

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
                  decoration: InputDecoration(
                    hintText: "Masukkan Nomor/ID",
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),
                GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
                  ),
                  itemCount: _produkList.length,
                  itemBuilder: (context, index) {
                    final produk = _produkList[index];
                    final isSelected = _selectedSku == produk['sku'];
                    return CustomBounce(
                      onTap: () {
                        _nomorFocus.unfocus();
                        setState(() => _selectedSku = produk['sku']);
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
                            Text(produk['nama'], maxLines: 1, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isSelected ? WarnaDesaPay.primary : WarnaDesaPay.textMain)),
                            Text(produk['harga'] == 0 ? "Cek Detail" : _formatRupiah(produk['harga']), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? WarnaDesaPay.primary : WarnaDesaPay.textSub)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              child: Row(
                children: [
                  Expanded(
                    child: Text(selectedProduct != null ? (selectedProduct['harga'] == 0 ? "-" : _formatRupiah(selectedProduct['harga'])) : "Rp 0", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: WarnaDesaPay.primary, foregroundColor: Colors.white),
                    onPressed: _isLoading ? null : _prosesTransaksi,
                    child: const Text("Lanjutkan"),
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
