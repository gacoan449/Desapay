import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/warna.dart';
import '../../widgets/menu_item.dart';
import '../../services/firestore_service.dart';

class PpobGenericScreen extends StatefulWidget {
  final String kategori;

  const PpobGenericScreen({
    super.key,
    required this.kategori,
  });

  @override
  State<PpobGenericScreen> createState() =>
      _PpobGenericScreenState();
}

class _PpobGenericScreenState
    extends State<PpobGenericScreen> {
  // =========================================================
  // CONTROLLER
  // =========================================================

  final TextEditingController _nomorController =
      TextEditingController();

  final FocusNode _nomorFocus =
      FocusNode();

  // =========================================================
  // STATE
  // =========================================================

  bool _isLoadingData = true;
  bool _isProcessingTransaction = false;

  String? _selectedSku;

  Map<String, dynamic>? _selectedProductData;

  List<Map<String, dynamic>> _produkList = [];

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _fetchProdukDariFirestore();
  }

  // =========================================================
  // AMBIL PRODUK DARI FIRESTORE
  // =========================================================
  //
  // PENTING:
  //
  // Tidak lagi menggunakan DigiflazzService.
  //
  // Admin sudah melakukan:
  //
  // Digiflazz
  //     ↓
  // Firestore
  //
  // Pengguna:
  //
  // Firestore
  //     ↓
  // PpobGenericScreen
  //
  // =========================================================

  Future<void> _fetchProdukDariFirestore() async {
    if (!mounted) return;

    setState(() {
      _isLoadingData = true;
    });

    try {
      // =====================================================
      // AMBIL PRODUK AKTIF SAJA
      // =====================================================

      final allProducts =
          await FirestoreService.ambilProdukAktif();

      // =====================================================
      // PEMETAAN KATEGORI
      // =====================================================

      String targetKategori = '';

      final kategori =
          widget.kategori.toLowerCase();

      if (kategori.contains('game')) {
        targetKategori = 'games';
      } else if (kategori.contains('pdam')) {
        targetKategori = 'pdam';
      } else if (kategori.contains('pln')) {
        targetKategori = 'pln';
      } else if (kategori.contains('e-wallet') ||
          kategori.contains('ewallet') ||
          kategori.contains('e wallet')) {
        targetKategori = 'e-money';
      } else {
        targetKategori = kategori;
      }

      // =====================================================
      // FILTER KATEGORI
      // =====================================================

      final filteredProducts =
          allProducts.where((product) {
        final category =
            product['category']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final brand =
            product['brand']
                    ?.toString()
                    .toLowerCase() ??
                '';

        return category.contains(targetKategori) ||
            brand.contains(targetKategori);
      }).toList();

      // =====================================================
      // URUTKAN HARGA JUAL TERMURAH
      // =====================================================

      filteredProducts.sort((a, b) {
        final costA =
            _parseDouble(a['cost']);

        final marginA =
            _parseDouble(a['margin']);

        final costB =
            _parseDouble(b['cost']);

        final marginB =
            _parseDouble(b['margin']);

        final hargaA =
            costA + marginA;

        final hargaB =
            costB + marginB;

        return hargaA.compareTo(hargaB);
      });

      if (!mounted) return;

      setState(() {
        _produkList = filteredProducts;
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingData = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Gagal memuat produk: $e'),
          backgroundColor:
              WarnaDesaPay.danger,
        ),
      );
    }
  }

  // =========================================================
  // PARSE ANGKA
  // =========================================================

  double _parseDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return 0;
    }

    final direct =
        double.tryParse(text);

    if (direct != null) {
      return direct;
    }

    return double.tryParse(
          text.replaceAll('.', ''),
        ) ??
        0;
  }

  // =========================================================
  // FORMAT RUPIAH
  // =========================================================

  String _formatRupiah(num nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(nominal);
  }

  // =========================================================
  // HARGA JUAL
  // =========================================================
  //
  // Harga jual TIDAK disimpan terpisah.
  //
  // cost   = modal dari Digiflazz
  // margin = pengaturan Admin
  //
  // harga jual = cost + margin
  //
  // =========================================================

  int _hargaJual(
    Map<String, dynamic> product,
  ) {
    final cost =
        _parseDouble(product['cost']);

    final margin =
        _parseDouble(product['margin']);

    return (cost + margin).round();
  }

  // =========================================================
  // PROSES TRANSAKSI
  // =========================================================
  //
  // Untuk tahap ini tombol hanya melakukan validasi.
  //
  // BELUM menembak Digiflazz.
  //
  // Data produk yang dipilih berasal dari Firestore.
  //
  // =========================================================

  Future<void> _prosesTransaksi() async {
    final nomor =
        _nomorController.text.trim();

    if (nomor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Nomor/ID tujuan wajib diisi.'),
        ),
      );
      return;
    }

    if (_selectedSku == null ||
        _selectedProductData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Silakan pilih produk terlebih dahulu.'),
        ),
      );
      return;
    }

    if (_isProcessingTransaction) {
      return;
    }

    setState(() {
      _isProcessingTransaction = true;
    });

    try {
      // =====================================================
      // DATA PRODUK DARI FIRESTORE
      // =====================================================

      final sku =
          _selectedSku!;

      final nama =
          _selectedProductData!['nama']
                  ?.toString() ??
              '-';

      final harga =
          _parseDouble(
        _selectedProductData!['harga'],
      );

      // =====================================================
      // SAMPAI SINI DATA SUDAH SIAP
      //
      // Nanti proses pembayaran/transaksi bisa dibuat
      // setelah struktur transaksi DesaPay ditentukan.
      //
      // =====================================================

      await Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Produk $nama ($sku) dipilih '
            'dengan harga ${_formatRupiah(harga)}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Gagal memproses: $e'),
          backgroundColor:
              WarnaDesaPay.danger,
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _isProcessingTransaction = false;
    });
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _nomorController.dispose();
    _nomorFocus.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          WarnaDesaPay.lightBg,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            WarnaDesaPay.primary,
        foregroundColor:
            Colors.white,
        centerTitle: true,
        title: Text(
          widget.kategori,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize: 18,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Refresh produk',
            onPressed:
                _isLoadingData
                    ? null
                    : _fetchProdukDariFirestore,
            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: 120,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // =================================================
                // NOMOR / ID TUJUAN
                // =================================================

                TextField(
                  controller:
                      _nomorController,
                  focusNode:
                      _nomorFocus,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Masukkan Nomor/ID Tujuan',
                    filled:
                        true,
                    fillColor:
                        Colors.white,
                    prefixIcon:
                        const Icon(
                      Icons.numbers_rounded,
                      color:
                          WarnaDesaPay.primary,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 32,
                ),

                // =================================================
                // LOADING
                // =================================================

                if (_isLoadingData)
                  const Center(
                    child:
                        Padding(
                      padding:
                          EdgeInsets.all(
                        40,
                      ),
                      child:
                          CircularProgressIndicator(
                        color:
                            WarnaDesaPay.primary,
                      ),
                    ),
                  )

                // =================================================
                // PRODUK KOSONG
                // =================================================

                else if (_produkList.isEmpty)
                  Center(
                    child:
                        Column(
                      children: [
                        const SizedBox(
                          height: 40,
                        ),

                        Icon(
                          Icons
                              .inventory_2_outlined,
                          size: 64,
                          color: WarnaDesaPay
                              .textSub
                              .withOpacity(
                            0.5,
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        const Text(
                          'Produk belum tersedia\n'
                          'atau belum disinkronkan oleh Admin.',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            color:
                                WarnaDesaPay.textSub,
                          ),
                        ),
                      ],
                    ),
                  )

                // =================================================
                // PRODUK
                // =================================================

                else
                  GridView.builder(
                    shrinkWrap:
                        true,
                    physics:
                        const NeverScrollableScrollPhysics(),

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          2,
                      crossAxisSpacing:
                          12,
                      mainAxisSpacing:
                          12,
                      childAspectRatio:
                          1.4,
                    ),

                    itemCount:
                        _produkList.length,

                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      final product =
                          _produkList[index];

                      final sku =
                          product['sku']
                                  ?.toString() ??
                              '';

                      final nama =
                          product['name']
                                  ?.toString() ??
                              '-';

                      // =========================================
                      // HARGA JUAL
                      // cost + margin
                      // =========================================

                      final hargaJual =
                          _hargaJual(
                        product,
                      );

                      final isSelected =
                          _selectedSku ==
                              sku;

                      return CustomBounce(
                        onTap: () {
                          _nomorFocus
                              .unfocus();

                          setState(() {
                            _selectedSku =
                                sku;

                            _selectedProductData =
                                {
                              'sku': sku,
                              'nama': nama,
                              'harga':
                                  hargaJual,
                              'cost':
                                  _parseDouble(
                                product[
                                    'cost'],
                              ),
                              'margin':
                                  _parseDouble(
                                product[
                                    'margin'],
                              ),
                            };
                          });
                        },

                        child:
                            Container(
                          padding:
                              const EdgeInsets.all(
                            12,
                          ),

                          decoration:
                              BoxDecoration(
                            color: isSelected
                                ? WarnaDesaPay
                                    .primary
                                    .withOpacity(
                                    0.08,
                                  )
                                : Colors.white,

                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),

                            border:
                                Border.all(
                              color:
                                  isSelected
                                      ? WarnaDesaPay
                                          .primary
                                      : WarnaDesaPay
                                          .lightField,
                              width:
                                  isSelected
                                      ? 2
                                      : 1,
                            ),
                          ),

                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,

                            children: [
                              Text(
                                nama,
                                maxLines:
                                    2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.w800,
                                  fontSize:
                                      13,
                                  color:
                                      isSelected
                                          ? WarnaDesaPay
                                              .primary
                                          : WarnaDesaPay
                                              .textMain,
                                ),
                              ),

                              const Spacer(),

                              Text(
                                _formatRupiah(
                                  hargaJual,
                                ),
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize:
                                      13,
                                  color:
                                      isSelected
                                          ? WarnaDesaPay
                                              .primary
                                          : WarnaDesaPay
                                              .textSub,
                                ),
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

          // =====================================================
          // BOTTOM PAYMENT PANEL
          // =====================================================

          Align(
            alignment:
                Alignment.bottomCenter,

            child:
                Container(
              padding:
                  const EdgeInsets.fromLTRB(
                24,
                16,
                24,
                32,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.white,

                borderRadius:
                    const BorderRadius.vertical(
                  top:
                      Radius.circular(
                    24,
                  ),
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                        WarnaDesaPay.shadow
                            .withOpacity(
                      0.05,
                    ),
                    blurRadius:
                        10,
                    offset:
                        const Offset(
                      0,
                      -4,
                    ),
                  ),
                ],
              ),

              child:
                  Row(
                children: [
                  // =================================================
                  // TOTAL
                  // =================================================

                  Expanded(
                    child:
                        Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style:
                              TextStyle(
                            fontSize:
                                11,
                            color:
                                WarnaDesaPay.textSub,
                          ),
                        ),

                        Text(
                          _selectedProductData !=
                                  null
                              ? _formatRupiah(
                                  _parseDouble(
                                    _selectedProductData![
                                        'harga'],
                                  ),
                                )
                              : 'Rp 0',
                          style:
                              const TextStyle(
                            fontSize:
                                18,
                            fontWeight:
                                FontWeight.w900,
                            color:
                                WarnaDesaPay.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =================================================
                  // BUTTON
                  // =================================================

                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          WarnaDesaPay.primary,
                      foregroundColor:
                          Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal:
                            24,
                        vertical:
                            14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),

                    onPressed:
                        (_isProcessingTransaction ||
                                _selectedSku ==
                                    null)
                            ? null
                            : _prosesTransaksi,

                    child:
                        _isProcessingTransaction
                            ? const SizedBox(
                                width:
                                    20,
                                height:
                                    20,
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      Colors.white,
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Text(
                                'Lanjutkan',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
