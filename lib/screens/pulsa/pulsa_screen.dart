import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';

import '../../config/warna.dart';

class CustomBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const CustomBounce({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<CustomBounce> createState() => _CustomBounceState();
}

class _CustomBounceState extends State<CustomBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
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

class PulsaScreen extends StatefulWidget {
  const PulsaScreen({super.key});

  @override
  State<PulsaScreen> createState() => _PulsaScreenState();
}

class _PulsaScreenState extends State<PulsaScreen> {
  final TextEditingController nomorController = TextEditingController();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _daftarPulsaReguler = [];

  bool _sedangMemuat = false;
  bool _sedangTransaksi = false;

  String _operatorTerdeteksi = "";

  Map<String, dynamic>? _produkTerpilih;

  // =========================================================
  // USER
  // =========================================================

  String? get _uid => _auth.currentUser?.uid;

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    nomorController.dispose();
    super.dispose();
  }

  // =========================================================
  // DETEKSI OPERATOR
  // =========================================================

  void _deteksiOperatorOtomatis(String nomor) {
    if (nomor.length < 4) {
      setState(() {
        _operatorTerdeteksi = "";
        _daftarPulsaReguler = [];
        _produkTerpilih = null;
      });
      return;
    }

    final prefix = nomor.substring(0, 4);

    String operator = "";

    if ([
      "0811",
      "0812",
      "0813",
      "0821",
      "0822",
      "0823",
      "0851",
      "0852",
      "0853",
    ].contains(prefix)) {
      operator = "TELKOMSEL";
    } else if ([
      "0814",
      "0815",
      "0816",
      "0855",
      "0856",
      "0857",
      "0858",
    ].contains(prefix)) {
      operator = "INDOSAT";
    } else if ([
      "0817",
      "0818",
      "0819",
      "0877",
      "0878",
      "0859",
    ].contains(prefix)) {
      operator = "XL";
    } else if ([
      "0831",
      "0832",
      "0833",
      "0838",
    ].contains(prefix)) {
      operator = "AXIS";
    } else if ([
      "0895",
      "0896",
      "0897",
      "0898",
      "0899",
    ].contains(prefix)) {
      operator = "THREE";
    } else if ([
      "0881",
      "0882",
      "0883",
      "0884",
      "0885",
      "0886",
      "0887",
      "0888",
      "0889",
    ].contains(prefix)) {
      operator = "SMARTFREN";
    }

    if (operator != _operatorTerdeteksi) {
      setState(() {
        _operatorTerdeteksi = operator;
        _produkTerpilih = null;
        _daftarPulsaReguler = [];
      });

      if (operator.isNotEmpty) {
        _ambilProdukPulsaDariFirestore(operator);
      }
    }
  }

  // =========================================================
  // WARNA OPERATOR
  // =========================================================

  Color _getOperatorColor() {
    switch (_operatorTerdeteksi) {
      case "TELKOMSEL":
        return const Color(0xFFE52229);

      case "INDOSAT":
        return const Color(0xFFFFD200);

      case "XL":
        return const Color(0xFF0054A6);

      case "AXIS":
        return const Color(0xFF8338EC);

      case "THREE":
        return const Color(0xFF9B5DE5);

      case "SMARTFREN":
        return const Color(0xFFFF1493);

      default:
        return Colors.grey;
    }
  }

  // =========================================================
  // PRODUK
  // =========================================================

  Future<void> _ambilProdukPulsaDariFirestore(
    String operator,
  ) async {
    setState(() {
      _sedangMemuat = true;
    });

    try {
      final snapshot = await _db
          .collection('products')
          .where('active', isEqualTo: true)
          .get();

      final List<Map<String, dynamic>> hasil = [];

      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());

        final category =
            (data['category'] ?? '').toString().toUpperCase();

        final brand =
            (data['brand'] ?? '').toString().toUpperCase();

        if (category != 'PULSA') {
          continue;
        }

        if (!brand.contains(operator)) {
          continue;
        }

        data['sku'] ??= doc.id;

        final num cost = _toNum(data['cost']);
        final num margin = _toNum(data['margin']);

        data['sellingPrice'] = cost + margin;

        hasil.add(data);
      }

      hasil.sort((a, b) {
        return _toNum(a['sellingPrice'])
            .compareTo(_toNum(b['sellingPrice']));
      });

      if (!mounted) return;

      setState(() {
        _daftarPulsaReguler = hasil;
        _sedangMemuat = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _daftarPulsaReguler = [];
        _sedangMemuat = false;
      });

      _tampilkanPesan("Gagal mengambil produk: $e");
    }
  }

  // =========================================================
  // ANGKA
  // =========================================================

  num _toNum(dynamic value) {
    if (value is num) return value;

    return num.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String rupiah(dynamic angka) {
    final int value = _toNum(angka).toInt();

    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  // =========================================================
  // CEK SALDO USER
  // =========================================================

  Future<num?> _ambilSaldoUser() async {
    if (_uid == null) {
      _tampilkanPesan("Anda belum login.");
      return null;
    }

    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .get();

      if (!doc.exists) {
        _tampilkanPesan("Data akun pengguna tidak ditemukan.");
        return null;
      }

      final data = doc.data() ?? {};

      // Mendukung beberapa kemungkinan nama field saldo.
      final saldo = data['saldo'] ??
          data['balance'] ??
          data['saldoUtama'] ??
          data['wallet'] ??
          0;

      return _toNum(saldo);
    } catch (e) {
      _tampilkanPesan("Gagal membaca saldo: $e");
      return null;
    }
  }

  // =========================================================
  // INVOICE
  // =========================================================

  void _prosesBottomSheetInvoice(
    Map<String, dynamic> produk,
  ) {
    _produkTerpilih = produk;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Konfirmasi Pembayaran",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              const Divider(),

              _buildInvoiceRow(
                "Jenis Layanan",
                "Isi Ulang Pulsa Reguler",
              ),

              _buildInvoiceRow(
                "Produk",
                produk['name']?.toString() ?? "-",
              ),

              _buildInvoiceRow(
                "Nomor Tujuan",
                nomorController.text,
              ),

              _buildInvoiceRow(
                "Operator",
                _operatorTerdeteksi,
              ),

              _buildInvoiceRow(
                "Sumber Pembayaran",
                "Saldo Utama DesaPay",
              ),

              const SizedBox(height: 8),

              const Divider(),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Pembayaran",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "Rp ${rupiah(produk['sellingPrice'])}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: WarnaDesaPay.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        WarnaDesaPay.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _sedangTransaksi
                      ? null
                      : () async {
                          Navigator.pop(context);

                          await _buatPermintaanTransaksi(
                            produk,
                          );
                        },
                  child: const Text(
                    "Konfirmasi & Bayar",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
              if (RegExp(r'^\\d{6}$').hasMatch(value)) Navigator.of(dialogContext).pop(value);
            },
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (RegExp(r'^\\d{6}$').hasMatch(value)) Navigator.of(dialogContext).pop(value);
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

  // =========================================================
  // BUAT TRANSAKSI
  // =========================================================

  Future<void> _buatPermintaanTransaksi(
    Map<String, dynamic> produk,
  ) async {
    if (_sedangTransaksi) return;

    if (_uid == null) {
      _tampilkanPesan("Anda belum login.");
      return;
    }

    final nomor = nomorController.text.trim();

    final sku = produk['sku']?.toString() ?? '';

    final harga =
        _toNum(produk['sellingPrice']).toInt();

    if (nomor.length < 10) {
      _tampilkanPesan(
        "Nomor HP tidak valid.",
      );
      return;
    }

    if (sku.isEmpty) {
      _tampilkanPesan(
        "SKU produk tidak valid.",
      );
      return;
    }

    if (harga <= 0) {
      _tampilkanPesan(
        "Harga produk tidak valid.",
      );
      return;
    }

    final pin = await _mintaPinTransaksi();
    if (pin == null || !mounted) return;

    setState(() {
      _sedangTransaksi = true;
    });

    try {
      // =====================================================
      // CEK SALDO USER SEBELUM MEMBUAT REQUEST
      // =====================================================

      final userRef =
          _db.collection('users').doc(_uid);

      final userSnapshot =
          await userRef.get();

      if (!userSnapshot.exists) {
        throw Exception(
          "Data pengguna tidak ditemukan.",
        );
      }

      final userData =
          userSnapshot.data() ?? {};

      final saldo = _toNum(
        userData['saldo'] ??
            userData['balance'] ??
            userData['saldoUtama'] ??
            userData['wallet'] ??
            0,
      );

      if (saldo < harga) {
        if (mounted) {
          _tampilkanPesan(
            "Saldo tidak cukup. Saldo: Rp ${rupiah(saldo)}",
          );
        }

        setState(() {
          _sedangTransaksi = false;
        });

        return;
      }

      // =====================================================
      // TRANSAKSI
      // =====================================================

      final transaksiRef = _db
          .collection('transaction_requests')
          .doc();

      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-southeast2',
      ).httpsCallable('createPpobTransaction');
      final created = await callable.call(<String, dynamic>{
        'request_id': transaksiRef.id,
        'pin': pin,
        'sku': sku,
        'customer_no': nomor,
        'type': 'PULSA',
        'category': 'PULSA',
        'operator': _operatorTerdeteksi,
        'source': 'PULSA',
      });
      if (created.data is! Map ||
          (created.data as Map)['request_id']?.toString() != transaksiRef.id) {
        throw StateError('Respons pembuatan transaksi tidak valid.');
      }

      if (!mounted) return;

      setState(() {
        _sedangTransaksi = false;
      });

      _tampilkanDialogMenunggu(
        transaksiRef.id,
        produk,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sedangTransaksi = false;
      });

      _tampilkanPesan(
        "Gagal membuat transaksi: $e",
      );
    }
  }

  // =========================================================
  // MONITOR TRANSAKSI
  // =========================================================

  void _tampilkanDialogMenunggu(
    String transactionId,
    Map<String, dynamic> produk,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StreamBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          stream: _db
              .collection('transaction_requests')
              .doc(transactionId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                title: Text(
                  "Memproses Transaksi",
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Menghubungkan ke sistem...",
                    ),
                  ],
                ),
              );
            }

            final data =
                snapshot.data?.data() ?? {};

            final status =
                (data['status'] ?? 'WAITING')
                    .toString()
                    .toUpperCase();

            final sn =
                data['sn']?.toString() ?? '';

            final message =
                (data['providerMessage'] ?? data['message'])?.toString() ?? '';

            if (status == 'WAITING' ||
                status == 'PROCESSING' ||
                status == 'PENDING') {
              return const AlertDialog(
                title:
                    Text("Transaksi Diproses"),
                content: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Transaksi sedang diproses. Mohon tunggu...",
                      textAlign:
                          TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (data['reconciliationRequired'] == true ||
                status == 'RECONCILIATION_REQUIRED') {
              return AlertDialog(
                title: const Text("Transaksi Perlu Pemeriksaan"),
                content: const Text(
                  "Status dari provider berbeda dengan status saldo. Admin perlu memeriksa transaksi ini. Jangan lakukan pembelian ulang.",
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Tutup"),
                  ),
                ],
              );
            }

            if (status == 'REFUND_PENDING') {
              return AlertDialog(
                title: const Text("Pengembalian Saldo Diproses"),
                content: Text(
                  message.isNotEmpty
                      ? message
                      : "Transaksi gagal. Pengembalian saldo sedang dicoba kembali. Jangan lakukan pembelian ulang dulu.",
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Tutup"),
                  ),
                ],
              );
            }

            if (status == 'SUCCESS' ||
                status == 'SUKSES') {
              return AlertDialog(
                title: const Text(
                  "Transaksi Berhasil",
                ),
                content: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      produk['name']
                              ?.toString() ??
                          '-',
                      textAlign:
                          TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Nomor: ${nomorController.text}",
                    ),
                    if (sn.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        "SN: $sn",
                        textAlign:
                            TextAlign.center,
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );

                      nomorController.clear();

                      setState(() {
                        _operatorTerdeteksi = "";
                        _daftarPulsaReguler = [];
                        _produkTerpilih = null;
                      });
                    },
                    child:
                        const Text("Selesai"),
                  ),
                ],
              );
            }

            return AlertDialog(
              title:
                  const Text("Transaksi Gagal"),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message.isNotEmpty
                        ? message
                        : "Transaksi tidak dapat diproses.",
                    textAlign:
                        TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text("Tutup"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // INVOICE ROW
  // =========================================================

  Widget _buildInvoiceRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PESAN
  // =========================================================

  void _tampilkanPesan(String pesan) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor:
            WarnaDesaPay.danger,
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            WarnaDesaPay.primary,
        foregroundColor:
            Colors.white,
        title: const Text(
          "Isi Ulang Pulsa",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: () =>
              Navigator.pop(context),
        ),
      ),

      body: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding:
                const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nomor Handphone Tujuan",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller:
                      nomorController,
                  keyboardType:
                      TextInputType.phone,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged:
                      _deteksiOperatorOtomatis,
                  decoration:
                      InputDecoration(
                    filled: true,
                    fillColor:
                        const Color(0xFFF1F5F9),
                    hintText:
                        "Contoh: 08xxxxxxxxxx",
                    prefixIcon:
                        Icon(
                      Icons
                          .phone_android_rounded,
                      color:
                          WarnaDesaPay.primary,
                    ),
                    suffixIcon:
                        _operatorTerdeteksi.isEmpty
                            ? null
                            : Padding(
                                padding:
                                    const EdgeInsets.only(
                                  right: 12,
                                ),
                                child: Center(
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          _getOperatorColor(),
                                      borderRadius:
                                          BorderRadius.circular(
                                        10,
                                      ),
                                    ),
                                    child:
                                        Text(
                                      _operatorTerdeteksi,
                                      style:
                                          TextStyle(
                                        color:
                                            _operatorTerdeteksi ==
                                                    "INDOSAT"
                                                ? Colors.black87
                                                : Colors.white,
                                        fontWeight:
                                            FontWeight.w900,
                                        fontSize:
                                            10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                    contentPadding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (_operatorTerdeteksi.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 6,
              ),
              child: Text(
                "Pilih Nominal Pulsa Reguler",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

          Expanded(
            child: _sedangMemuat
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : nomorController.text.length < 4
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            Icon(
                              Icons
                                  .contact_phone_rounded,
                              size: 64,
                              color: Colors
                                  .grey
                                  .shade300,
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            const Text(
                              "Masukkan nomor HP untuk memuat katalog pulsa.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _daftarPulsaReguler
                            .isEmpty
                        ? const Center(
                            child: Text(
                              "Produk pulsa tidak tersedia untuk operator ini.",
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                              ),
                            ),
                          )
                        : GridView.builder(
                            physics:
                                const BouncingScrollPhysics(),
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            itemCount:
                                _daftarPulsaReguler
                                    .length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.3,
                            ),
                            itemBuilder:
                                (context, index) {
                              final produk =
                                  _daftarPulsaReguler[
                                      index];

                              return CustomBounce(
                                onTap: () {
                                  _prosesBottomSheetInvoice(
                                    produk,
                                  );
                                },
                                child:
                                    Container(
                                  padding:
                                      const EdgeInsets.all(
                                    16,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(
                                      20,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors
                                            .black
                                            .withOpacity(
                                          0.02,
                                        ),
                                        blurRadius:
                                            8,
                                        offset:
                                            const Offset(
                                          0,
                                          2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  child:
                                      Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        produk['name']
                                                ?.toString() ??
                                            "-",
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow
                                                .ellipsis,
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.black87,
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize:
                                              13,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "Rp ${rupiah(produk['sellingPrice'])}",
                                        style:
                                            TextStyle(
                                          color:
                                              WarnaDesaPay
                                                  .primary,
                                          fontWeight:
                                              FontWeight
                                                  .w900,
                                          fontSize:
                                              16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
