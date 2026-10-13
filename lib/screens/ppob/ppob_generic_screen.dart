import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../config/warna.dart';
import '../../services/firestore_service.dart';

class PpobGenericScreen extends StatefulWidget {
  final String kategori;

  const PpobGenericScreen({
    super.key,
    required this.kategori,
  });

  @override
  State<PpobGenericScreen> createState() => _PpobGenericScreenState();
}

class _PpobGenericScreenState extends State<PpobGenericScreen> {
  final TextEditingController _nomorController =
      TextEditingController();

  final TextEditingController _searchController =
      TextEditingController();

  final FocusNode _nomorFocus = FocusNode();

  bool _isLoadingData = true;
  bool _isProcessingTransaction = false;

  String? _selectedSku;
  String _selectedBrand = 'Semua';

  Map<String, dynamic>? _selectedProductData;

  List<Map<String, dynamic>> _produkList = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  List<String> _brands = ['Semua'];

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _transactionSubscription;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_filterProduk);
    _fetchProdukDariFirestore();
  }

  // ==========================================================
  // NORMALIZE
  // ==========================================================

  String _normalize(dynamic value) {
    if (value == null) return '';

    return value
        .toString()
        .toLowerCase()
        .trim()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  // ==========================================================
  // PRODUCT HELPERS
  // ==========================================================

  String _productName(Map<String, dynamic> product) {
    return product['name']?.toString() ??
        product['nama']?.toString() ??
        product['product_name']?.toString() ??
        product['productName']?.toString() ??
        product['description']?.toString() ??
        '-';
  }

  String _productSku(Map<String, dynamic> product) {
    return product['sku']?.toString() ??
        product['buyer_sku_code']?.toString() ??
        product['buyerSkuCode']?.toString() ??
        product['code']?.toString() ??
        '';
  }

  String _productBrand(Map<String, dynamic> product) {
    return product['brand']?.toString() ??
        product['operator']?.toString() ??
        product['provider']?.toString() ??
        '';
  }

  String _productCategory(Map<String, dynamic> product) {
    return product['category']?.toString() ??
        product['kategori']?.toString() ??
        product['type']?.toString() ??
        product['tipe']?.toString() ??
        '';
  }

  // ==========================================================
  // CATEGORY MATCH
  // ==========================================================

  bool _isProductMatch(
    Map<String, dynamic> product,
    String requestedCategory,
  ) {
    final category = _normalize(_productCategory(product));
    final brand = _normalize(_productBrand(product));
    final name = _normalize(_productName(product));
    final sku = _normalize(_productSku(product));

    if (requestedCategory == 'pulsa') {
      return category.contains('pulsa') ||
          category.contains('prabayar') ||
          category.contains('prepaid') ||
          name.contains('pulsa');
    }

    if (requestedCategory == 'paket data') {
      return category.contains('data') ||
          category.contains('internet') ||
          category.contains('paket data');
    }

    if (requestedCategory == 'paket sms telepon') {
      return category.contains('sms') ||
          category.contains('telepon') ||
          category.contains('telp') ||
          category.contains('voice');
    }

    if (requestedCategory == 'pln') {
      final isPln = category.contains('pln') ||
          name.contains('pln') ||
          brand == 'pln';

      final isPasca = category.contains('pascabayar') ||
          category.contains('pasca bayar') ||
          name.contains('pascabayar') ||
          name.contains('pasca bayar');

      return isPln && !isPasca;
    }

    if (requestedCategory == 'pln pascabayar') {
      return category.contains('pascabayar') ||
          category.contains('pasca bayar');
    }

    if (requestedCategory == 'telkom') {
      final isTelkom = category.contains('telkom') ||
          category.contains('indihome') ||
          category.contains('internet rumah') ||
          category.contains('wifi') ||
          category.contains('telepon rumah') ||
          brand == 'telkom' ||
          brand == 'indihome';

      final isTelkomsel = brand.contains('telkomsel') ||
          category.contains('telkomsel') ||
          name.contains('telkomsel') ||
          sku.contains('tsel');

      return isTelkom && !isTelkomsel;
    }

    if (requestedCategory == 'e money') {
      return category.contains('e money') ||
          category.contains('ewallet') ||
          category.contains('e wallet') ||
          category.contains('dompet digital') ||
          category.contains('wallet');
    }

    if (requestedCategory == 'games') {
      return category.contains('game') ||
          category.contains('games');
    }

    if (requestedCategory == 'voucher game') {
      return category.contains('voucher game') ||
          (category.contains('game') &&
              category.contains('voucher'));
    }

    if (requestedCategory == 'top up game') {
      return category.contains('top up game') ||
          category.contains('topup game') ||
          (category.contains('game') &&
              category.contains('topup'));
    }

    if (requestedCategory == 'pdam') {
      return category.contains('pdam') ||
          category.contains('air');
    }

    if (requestedCategory == 'bpjs kesehatan') {
      return category.contains('bpjs') ||
          category.contains('kesehatan');
    }

    if (requestedCategory == 'angsuran kredit') {
      return category.contains('angsuran') ||
          category.contains('kredit') ||
          category.contains('cicilan');
    }

    if (requestedCategory == 'hp pascabayar') {
      return category.contains('pascabayar') &&
          (category.contains('hp') ||
              category.contains('handphone') ||
              category.contains('seluler'));
    }

    if (requestedCategory == 'tv berlangganan') {
      return category.contains('tv') ||
          category.contains('televisi') ||
          category.contains('kabel');
    }

    if (requestedCategory == 'pbb') {
      return category.contains('pbb') ||
          category.contains('pajak bumi');
    }

    if (requestedCategory == 'pgn') {
      return category.contains('pgn') ||
          brand == 'pgn' ||
          name.contains('pgn');
    }

    if (requestedCategory == 'e samsat') {
      return category.contains('samsat') ||
          category.contains('e samsat');
    }

    if (requestedCategory == 'tiket perjalanan') {
      return category.contains('tiket') ||
          category.contains('travel') ||
          category.contains('perjalanan');
    }

    if (requestedCategory == 'streaming') {
      return category.contains('streaming') ||
          category.contains('digital');
    }

    if (requestedCategory == 'masa aktif') {
      return category.contains('masa aktif') ||
          category.contains('aktif');
    }

    if (requestedCategory == 'aktivasi voucher') {
      return category.contains('aktivasi') ||
          category.contains('voucher');
    }

    if (requestedCategory == 'paket perdana') {
      return category.contains('perdana') ||
          category.contains('starter');
    }

    if (requestedCategory == 'voucher digital') {
      return category.contains('voucher') ||
          category.contains('digital');
    }

    return category.contains(requestedCategory) ||
        brand.contains(requestedCategory);
  }

  // ==========================================================
  // RESOLVE CATEGORY
  // ==========================================================

  String _resolveRequestedCategory() {
    final kategori = _normalize(widget.kategori);

    if (kategori.contains('pln pasca')) {
      return 'pln pascabayar';
    }

    if (kategori.contains('telkom') ||
        kategori.contains('indihome') ||
        kategori.contains('wifi')) {
      return 'telkom';
    }

    if (kategori.contains('pulsa')) {
      return 'pulsa';
    }

    if (kategori.contains('paket data')) {
      return 'paket data';
    }

    if (kategori.contains('sms') ||
        kategori.contains('telepon') ||
        kategori.contains('telp')) {
      return 'paket sms telepon';
    }

    if (kategori.contains('token') &&
        kategori.contains('pln')) {
      return 'pln';
    }

    if (kategori.contains('top up game') ||
        kategori.contains('topup game')) {
      return 'top up game';
    }

    if (kategori.contains('voucher game')) {
      return 'voucher game';
    }

    if (kategori.contains('game')) {
      return 'games';
    }

    if (kategori.contains('e-wallet') ||
        kategori.contains('ewallet') ||
        kategori.contains('e wallet')) {
      return 'e money';
    }

    if (kategori.contains('pdam')) {
      return 'pdam';
    }

    if (kategori.contains('bpjs')) {
      return 'bpjs kesehatan';
    }

    if (kategori.contains('angsuran')) {
      return 'angsuran kredit';
    }

    if (kategori.contains('hp pasca')) {
      return 'hp pascabayar';
    }

    if (kategori.contains('tv')) {
      return 'tv berlangganan';
    }

    if (kategori.contains('pbb')) {
      return 'pbb';
    }

    if (kategori.contains('pgn')) {
      return 'pgn';
    }

    if (kategori.contains('samsat')) {
      return 'e samsat';
    }

    if (kategori.contains('tiket')) {
      return 'tiket perjalanan';
    }

    if (kategori.contains('streaming')) {
      return 'streaming';
    }

    if (kategori.contains('masa aktif')) {
      return 'masa aktif';
    }

    if (kategori.contains('aktivasi voucher')) {
      return 'aktivasi voucher';
    }

    if (kategori.contains('perdana')) {
      return 'paket perdana';
    }

    if (kategori.contains('voucher digital')) {
      return 'voucher digital';
    }

    return kategori;
  }

  // ==========================================================
  // LOAD PRODUCT
  // ==========================================================

  Future<void> _fetchProdukDariFirestore() async {
    if (!mounted) return;

    setState(() {
      _isLoadingData = true;
    });

    try {
      final allProducts =
          await FirestoreService.ambilProdukAktif();

      final requestedCategory =
          _resolveRequestedCategory();

      final filteredProducts = allProducts
          .where(
            (product) => _isProductMatch(
              product,
              requestedCategory,
            ),
          )
          .toList();

      filteredProducts.sort(
        (a, b) => _hargaJual(a).compareTo(
          _hargaJual(b),
        ),
      );

      final brandSet = <String>{};

      for (final product in filteredProducts) {
        final brand = _productBrand(product).trim();

        if (brand.isNotEmpty) {
          brandSet.add(brand);
        }
      }

      final brands = <String>[
        'Semua',
        ...brandSet.toList()
          ..sort(
            (a, b) => a.toLowerCase().compareTo(
              b.toLowerCase(),
            ),
          ),
      ];

      if (!mounted) return;

      setState(() {
        _produkList = filteredProducts;
        _filteredProducts = filteredProducts;
        _brands = brands;
        _selectedBrand = 'Semua';
        _isLoadingData = false;

        if (_selectedSku != null &&
            !_produkList.any(
              (p) => _productSku(p) == _selectedSku,
            )) {
          _selectedSku = null;
          _selectedProductData = null;
        }
      });

      _filterProduk();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingData = false;
      });

      _showMessage(
        'Gagal memuat produk.',
        danger: true,
      );
    }
  }

  // ==========================================================
  // FILTER
  // ==========================================================

  void _filterProduk() {
    final query = _normalize(
      _searchController.text,
    );

    final brand = _normalize(
      _selectedBrand,
    );

    final result = _produkList.where(
      (product) {
        final nama = _normalize(
          _productName(product),
        );

        final sku = _normalize(
          _productSku(product),
        );

        final productBrand = _normalize(
          _productBrand(product),
        );

        final searchMatch = query.isEmpty ||
            nama.contains(query) ||
            sku.contains(query) ||
            productBrand.contains(query);

        final brandMatch = _selectedBrand == 'Semua' ||
            productBrand == brand;

        return searchMatch && brandMatch;
      },
    ).toList();

    if (!mounted) return;

    setState(() {
      _filteredProducts = result;
    });
  }

  // ==========================================================
  // PRICE
  // ==========================================================

  double _parseDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    final text = value.toString().trim();

    if (text.isEmpty) return 0;

    final direct = double.tryParse(text);

    if (direct != null) {
      return direct;
    }

    return double.tryParse(
          text
              .replaceAll('Rp', '')
              .replaceAll('rp', '')
              .replaceAll(' ', '')
              .replaceAll('.', ''),
        ) ??
        0;
  }

  int _hargaJual(Map<String, dynamic> product) {
    final harga = product['harga_jual'] ??
        product['hargaJual'] ??
        product['selling_price'] ??
        product['sellingPrice'];

    if (harga != null) {
      final parsed = _parseDouble(harga);

      if (parsed > 0) {
        return parsed.round();
      }
    }

    final cost = _parseDouble(
      product['cost'],
    );

    final margin = _parseDouble(
      product['margin'],
    );

    return (cost + margin).round();
  }

  String _formatRupiah(num nominal) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(nominal);
  }

  // ==========================================================
  // SELECT PRODUCT
  // ==========================================================

  void _pilihProduk(
    Map<String, dynamic> product,
  ) {
    final sku = _productSku(product);

    if (sku.isEmpty) {
      _showMessage(
        'SKU produk tidak valid.',
        danger: true,
      );
      return;
    }

    final nama = _productName(product);
    final brand = _productBrand(product);
    final harga = _hargaJual(product);

    _nomorFocus.unfocus();

    setState(() {
      _selectedSku = sku;

      _selectedProductData = {
        'sku': sku,
        'nama': nama,
        'harga': harga,
        'brand': brand,
        'category': _productCategory(product),
        'cost': _parseDouble(product['cost']),
        'margin': _parseDouble(product['margin']),
      };
    });
  }

  // ==========================================================
  // EKSEKUSI PEMBELIAN
  //
  // FLUTTER -> transaction_requests
  // BACKEND -> VALIDASI SALDO USER
  // BACKEND -> DIGIFLAZZ
  // BACKEND -> UPDATE STATUS
  // ==========================================================

  Future<String?> _mintaPinTransaksi() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Verifikasi PIN transaksi'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(labelText: 'PIN 6 digit', counterText: ''),
            onSubmitted: (_) {
              final value = controller.text.trim();
              if (RegExp(r'^\d{6}$').hasMatch(value)) Navigator.of(dialogContext).pop(value);
            },
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (RegExp(r'^\d{6}$').hasMatch(value)) Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _prosesTransaksi() async {
    final nomor = _nomorController.text.trim();

    if (nomor.isEmpty) {
      _showMessage(
        'Nomor / ID tujuan wajib diisi.',
      );
      _nomorFocus.requestFocus();
      return;
    }

    if (_selectedSku == null ||
        _selectedProductData == null) {
      _showMessage(
        'Silakan pilih produk terlebih dahulu.',
      );
      return;
    }

    if (_isProcessingTransaction) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Sesi login berakhir. Silakan login kembali.',
        danger: true,
      );
      return;
    }

    final harga = _parseDouble(
      _selectedProductData!['harga'],
    );

    if (harga <= 0) {
      _showMessage(
        'Harga produk tidak valid.',
        danger: true,
      );
      return;
    }

    setState(() {
      _isProcessingTransaction = true;
    });

    try {
      // --------------------------------------------------------
      // CEK MAINTENANCE APLIKASI
      // --------------------------------------------------------

      final maintenance =
          await FirestoreService.ambilMaintenance();

      if (maintenance) {
        _showMessage(
          'Sistem sedang dalam pemeliharaan. Silakan coba lagi nanti.',
          danger: true,
        );
        return;
      }

      // --------------------------------------------------------
      // BUAT REQUEST TRANSAKSI
      //
      // BACKEND YANG AKAN MEMPROSES REQUEST INI.
      // API KEY DIGIFLAZZ TIDAK PERNAH MASUK KE APK.
      // --------------------------------------------------------

      final pin = await _mintaPinTransaksi();
      if (pin == null || !mounted) return;

      // Client-side pricing is intentionally omitted. The backend validates
      // the authoritative product price and creates the request after PIN verification.
      final requestRef = FirebaseFirestore.instance
          .collection('transaction_requests')
          .doc();
      final requestId = requestRef.id;
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-southeast2',
      ).httpsCallable('createPpobTransaction');
      final created = await callable.call(<String, dynamic>{
        'request_id': requestId,
        'pin': pin,
        'sku': _selectedSku,
        'customer_no': nomor,
        'type': 'PPOB',
        'category': widget.kategori,
        'source': 'PPOB_GENERIC',
      });
      if (created.data is! Map ||
          (created.data as Map)['request_id']?.toString() != requestId) {
        throw StateError('Respons pembuatan transaksi tidak valid.');
      }

      if (!mounted) return;

      _showMessage(
        'Permintaan transaksi dikirim. Memproses...',
      );

      // --------------------------------------------------------
      // TUNGGU BACKEND MENGUBAH STATUS
      // --------------------------------------------------------

      final completer =
          Completer<Map<String, dynamic>>();

      await _transactionSubscription?.cancel();

      _transactionSubscription = requestRef
          .snapshots()
          .listen(
        (snapshot) {
          if (!snapshot.exists) return;

          final data = snapshot.data();

          if (data == null) return;

          final status =
              data['status']?.toString().toUpperCase() ?? '';

          // ----------------------------------------------------
          // BERHASIL
          // ----------------------------------------------------

          if (status == 'SUCCESS' ||
              status == 'SUKSES' ||
              status == 'BERHASIL') {
            if (!completer.isCompleted) {
              completer.complete(data);
            }
            return;
          }

          // ----------------------------------------------------
          // GAGAL
          // ----------------------------------------------------

          if (status == 'FAILED' ||
              status == 'FAIL' ||
              status == 'GAGAL' ||
              status == 'ERROR' ||
              status == 'CANCELLED' ||
              status == 'CANCELED' ||
              status == 'REFUND_PENDING' ||
              status == 'RECONCILIATION_REQUIRED') {
            if (!completer.isCompleted) {
              completer.complete(data);
            }
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );

      // --------------------------------------------------------
      // BATAS TUNGGU
      // --------------------------------------------------------

      final result = await completer.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          return {
            'status': 'TIMEOUT',
            'message':
                'Transaksi masih diproses. Silakan cek riwayat transaksi.',
          };
        },
      );

      if (!mounted) return;

      final status =
          result['status']?.toString().toUpperCase() ?? '';

      if (result['reconciliationRequired'] == true) {
        _showMessage(
          'Status transaksi perlu pemeriksaan admin. Jangan lakukan pembelian ulang.',
          danger: true,
        );
        return;
      }

      final message =
          result['message']?.toString() ??
              result['msg']?.toString() ??
              '';

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (status == 'SUCCESS' ||
          status == 'SUKSES' ||
          status == 'BERHASIL') {
        _showTransactionSuccess(
          productName:
              _selectedProductData!['nama']?.toString() ?? '-',
          nomor: nomor,
          harga: harga,
          message: message,
        );

        return;
      }

      // --------------------------------------------------------
      // FAILED
      // --------------------------------------------------------

      if (status == 'FAILED' ||
          status == 'FAIL' ||
          status == 'GAGAL' ||
          status == 'ERROR' ||
          status == 'CANCELLED' ||
          status == 'CANCELED') {
        _showMessage(
          message.isEmpty
              ? 'Transaksi gagal diproses.'
              : message,
          danger: true,
        );

        return;
      }

      if (status == 'REFUND_PENDING') {
        _showMessage(
          'Transaksi gagal, tetapi pengembalian saldo sedang diproses. Jangan lakukan pembelian ulang dulu.',
          danger: true,
        );
        return;
      }

      if (status == 'RECONCILIATION_REQUIRED') {
        _showMessage(
          'Status transaksi memerlukan pemeriksaan admin. Jangan ulangi pembelian.',
          danger: true,
        );
        return;
      }

      // --------------------------------------------------------
      // TIMEOUT / MASIH DIPROSES
      // --------------------------------------------------------

      _showMessage(
        'Transaksi masih diproses. Silakan cek riwayat transaksi.',
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      _showMessage(
        e.message ?? 'Transaksi tidak dapat diproses.',
        danger: true,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Gagal membuat transaksi. Periksa koneksi dan status transaksi sebelum mencoba kembali.',
        danger: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isProcessingTransaction = false;
      });
    }
  }

  // ==========================================================
  // SUCCESS DIALOG
  // ==========================================================

  void _showTransactionSuccess({
    required String productName,
    required String nomor,
    required double harga,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Transaksi Berhasil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _detailTransaksi(
                'Produk',
                productName,
              ),
              const SizedBox(height: 8),
              _detailTransaksi(
                'Tujuan',
                nomor,
              ),
              const SizedBox(height: 8),
              _detailTransaksi(
                'Total',
                _formatRupiah(harga),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11,
                    color: WarnaDesaPay.textSub,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  _selectedSku = null;
                  _selectedProductData = null;
                });

                _nomorController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: WarnaDesaPay.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailTransaksi(
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: WarnaDesaPay.textSub,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: WarnaDesaPay.textMain,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(
    String message, {
    bool danger = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: danger
              ? WarnaDesaPay.danger
              : WarnaDesaPay.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ==========================================================
  // CATEGORY ICON
  // ==========================================================

  IconData _categoryIcon() {
    final category = _resolveRequestedCategory();

    if (category == 'pulsa') {
      return Icons.phone_android_rounded;
    }

    if (category == 'paket data') {
      return Icons.wifi_rounded;
    }

    if (category == 'paket sms telepon') {
      return Icons.phone_in_talk_rounded;
    }

    if (category == 'pln' ||
        category == 'pln pascabayar') {
      return Icons.bolt_rounded;
    }

    if (category == 'telkom') {
      return Icons.router_rounded;
    }

    if (category == 'pdam') {
      return Icons.water_drop_rounded;
    }

    if (category == 'e money') {
      return Icons.account_balance_wallet_rounded;
    }

    if (category.contains('game')) {
      return Icons.sports_esports_rounded;
    }

    if (category == 'streaming') {
      return Icons.play_circle_fill_rounded;
    }

    if (category == 'bpjs kesehatan') {
      return Icons.health_and_safety_rounded;
    }

    if (category == 'angsuran kredit') {
      return Icons.receipt_long_rounded;
    }

    if (category == 'pbb') {
      return Icons.account_balance_rounded;
    }

    return Icons.grid_view_rounded;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          widget.kategori,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh produk',
            onPressed: _isLoadingData
                ? null
                : _fetchProdukDariFirestore,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: WarnaDesaPay.primary,
            backgroundColor: Colors.white,
            onRefresh: _fetchProdukDariFirestore,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                150,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildCategoryHeader(),
                  const SizedBox(height: 16),
                  _buildTargetField(),
                  const SizedBox(height: 18),
                  _buildPromoBanner(),
                  const SizedBox(height: 22),
                  _buildSearchField(),
                  const SizedBox(height: 14),
                  if (_brands.length > 1)
                    _buildBrandFilter(),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Produk',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: WarnaDesaPay.textMain,
                        ),
                      ),
                      if (!_isLoadingData)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: WarnaDesaPay.primary
                                .withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_filteredProducts.length} produk',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color:
                                  WarnaDesaPay.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingData)
                    _buildLoading()
                  else if (_filteredProducts.isEmpty)
                    _buildEmptyState()
                  else
                    _buildProductGrid(),
                ],
              ),
            ),
          ),
          _buildBottomPayment(),
        ],
      ),
    );
  }

  // ==========================================================
  // CATEGORY HEADER
  // ==========================================================

  Widget _buildCategoryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WarnaDesaPay.primary,
            const Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: WarnaDesaPay.primary
                .withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Icon(
              _categoryIcon(),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kategori,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih layanan favoritmu dengan harga terbaik.',
                  maxLines: 2,
                  style: TextStyle(
                    color:
                        Colors.white.withOpacity(0.82),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TARGET
  // ==========================================================

  Widget _buildTargetField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _nomorController,
        focusNode: _nomorFocus,
        keyboardType: TextInputType.phone,
        textInputAction:
            TextInputAction.done,
        decoration: InputDecoration(
          hintText:
              'Nomor HP / ID Pelanggan / Nomor Tujuan',
          hintStyle: const TextStyle(
            color: WarnaDesaPay.textSub,
            fontSize: 12,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: WarnaDesaPay.primary
                  .withOpacity(0.08),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: WarnaDesaPay.primary,
              size: 21,
            ),
          ),
          suffixIcon:
              _nomorController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _nomorController.clear();
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 19,
                      ),
                    )
                  : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 8,
          ),
        ),
        onChanged: (_) {
          setState(() {});
        },
      ),
    );
  }

  // ==========================================================
  // PROMO
  // ==========================================================

  Widget _buildPromoBanner() {
    return Container(
      height: 104,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: WarnaDesaPay.primary
                .withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -25,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -35,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Text(
                        'PROMO DESAPAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Harga bersahabat, transaksi cepat.',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pilih layanan • cek harga • lanjutkan',
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.72),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText:
            'Cari produk atau nominal...',
        hintStyle: const TextStyle(
          fontSize: 12,
          color: WarnaDesaPay.textSub,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: WarnaDesaPay.primary,
        ),
        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  )
                : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 15,
        ),
      ),
    );
  }

  // ==========================================================
  // BRAND
  // ==========================================================

  Widget _buildBrandFilter() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount: _brands.length,
        itemBuilder: (context, index) {
          final brand = _brands[index];
          final selected =
              brand == _selectedBrand;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedBrand = brand;
              });

              _filterProduk();
            },
            child: AnimatedContainer(
              duration:
                  const Duration(milliseconds: 180),
              margin:
                  const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? WarnaDesaPay.primary
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? WarnaDesaPay.primary
                      : WarnaDesaPay.lightField,
                ),
              ),
              child: Text(
                brand,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : WarnaDesaPay.textMain,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // LOADING
  // ==========================================================

  Widget _buildLoading() {
    return Column(
      children: List.generate(
        4,
        (index) {
          return Container(
            height: 88,
            margin:
                const EdgeInsets.only(
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color:
                      WarnaDesaPay.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // EMPTY
  // ==========================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: WarnaDesaPay.primary
                  .withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color:
                  WarnaDesaPay.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Produk belum tersedia',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
              color:
                  WarnaDesaPay.textMain,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Belum ada produk aktif untuk kategori ${widget.kategori}.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color:
                  WarnaDesaPay.textSub,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed:
                _fetchProdukDariFirestore,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label: const Text(
              'Muat Ulang',
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PRODUCT GRID
  // ==========================================================

  Widget _buildProductGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 11,
        mainAxisSpacing: 11,
        childAspectRatio: 1.42,
      ),
      itemCount:
          _filteredProducts.length,
      itemBuilder: (context, index) {
        final product =
            _filteredProducts[index];

        final sku =
            _productSku(product);
        final nama =
            _productName(product);
        final brand =
            _productBrand(product);
        final harga =
            _hargaJual(product);

        return _buildProductCard(
          product: product,
          sku: sku,
          nama: nama,
          brand: brand,
          harga: harga,
          isSelected:
              _selectedSku == sku,
        );
      },
    );
  }

  // ==========================================================
  // PRODUCT CARD
  // ==========================================================

  Widget _buildProductCard({
    required Map<String, dynamic> product,
    required String sku,
    required String nama,
    required String brand,
    required int harga,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () =>
            _pilihProduk(product),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isSelected
                ? WarnaDesaPay.primary
                    .withOpacity(0.07)
                : Colors.white,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? WarnaDesaPay.primary
                  : WarnaDesaPay.lightField,
              width:
                  isSelected ? 1.8 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color:
                          WarnaDesaPay.primary
                              .withOpacity(0.08),
                      blurRadius: 12,
                      offset:
                          const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration:
                        BoxDecoration(
                      color: isSelected
                          ? WarnaDesaPay
                              .primary
                              .withOpacity(
                                  0.12)
                          : WarnaDesaPay
                              .lightField,
                      borderRadius:
                          BorderRadius
                              .circular(9),
                    ),
                    child: Icon(
                      _categoryIcon(),
                      size: 17,
                      color: isSelected
                          ? WarnaDesaPay
                              .primary
                          : WarnaDesaPay
                              .textSub,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons
                          .check_circle_rounded,
                      color:
                          WarnaDesaPay.primary,
                      size: 19,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                nama,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w900,
                  color: isSelected
                      ? WarnaDesaPay
                          .primary
                      : WarnaDesaPay
                          .textMain,
                ),
              ),
              const Spacer(),
              if (brand.isNotEmpty)
                Text(
                  brand,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color:
                        WarnaDesaPay.textSub,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 3),
              Text(
                _formatRupiah(harga),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w900,
                  color: isSelected
                      ? WarnaDesaPay
                          .primary
                      : WarnaDesaPay
                          .textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BOTTOM PAYMENT
  // ==========================================================

  Widget _buildBottomPayment() {
    final selected =
        _selectedProductData;

    final harga = selected == null
        ? 0
        : _parseDouble(
            selected['harga'],
          );

    return Align(
      alignment:
          Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.08),
                blurRadius: 20,
                offset:
                    const Offset(0, -7),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            WarnaDesaPay
                                .textSub,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatRupiah(harga),
                      style:
                          const TextStyle(
                        fontSize: 17,
                        color:
                            WarnaDesaPay
                                .primary,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _selectedSku == null ||
                              _isProcessingTransaction
                          ? null
                          : _prosesTransaksi,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        WarnaDesaPay.primary,
                    disabledBackgroundColor:
                        Colors.grey.shade300,
                    foregroundColor:
                        Colors.white,
                    disabledForegroundColor:
                        Colors.grey.shade500,
                    elevation: 0,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 22,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(15),
                    ),
                  ),
                  child:
                      _isProcessingTransaction
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                const Text(
                                  'Lanjutkan',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(
                                  width: 7,
                                ),
                                const Icon(
                                  Icons
                                      .arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _transactionSubscription?.cancel();

    _nomorController.dispose();
    _searchController.dispose();
    _nomorFocus.dispose();

    super.dispose();
  }
}
