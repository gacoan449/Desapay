import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
      },
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
  final TextEditingController nomorController =
      TextEditingController();

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  List<Map<String, dynamic>> _daftarPulsaReguler = [];

  bool _sedangMemuat = false;
  bool _sedangTransaksi = false;

  String _operatorTerdeteksi = "";

  Map<String, dynamic>? _produkTerpilih;

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
  // AMBIL PRODUK DARI FIRESTORE
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
          .where(
            'active',
            isEqualTo: true,
          )
          .get();

      final List<Map<String, dynamic>> hasil = [];

      for (final doc in snapshot.docs) {
        final data =
            Map<String, dynamic>.from(doc.data());

        final category =
            (data['category'] ?? '')
                .toString()
                .toUpperCase();

        final brand =
            (data['brand'] ?? '')
                .toString()
                .toUpperCase();

        // Hanya pulsa reguler
        if (category != 'PULSA') {
          continue;
        }

        // Operator
        if (!brand.contains(operator)) {
          continue;
        }

        // SKU
        data['sku'] ??= doc.id;

        // Modal dari admin
        final num cost =
            _toNum(data['cost']);

        // Margin dari admin
        final num margin =
            _toNum(data['margin']);

        // Harga jual
        final num hargaJual =
            cost + margin;

        data['sellingPrice'] =
            hargaJual;

        hasil.add(data);
      }

      hasil.sort((a, b) {
        final hargaA =
            _toNum(a['sellingPrice']);

        final hargaB =
            _toNum(b['sellingPrice']);

        return hargaA.compareTo(hargaB);
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Gagal mengambil produk: $e",
          ),
          backgroundColor:
              WarnaDesaPay.danger,
        ),
      );
    }
  }

  // =========================================================
  // KONVERSI ANGKA
  // =========================================================

  num _toNum(dynamic value) {
    if (value is num) {
      return value;
    }

    return num.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String rupiah(dynamic angka) {
    final int value =
        _toNum(angka).toInt();

    return value
        .toString()
        .replaceAllMapped(
          RegExp(
            r'(\d{1,3})(?=(\d{3})+(?!\d))',
          ),
          (Match m) =>
              '${m[1]}.',
        );
  }

  // =========================================================
  // BOTTOM SHEET INVOICE
  // =========================================================

  void _prosesBottomSheetInvoice(
    Map<String, dynamic> produk,
  ) {
    _produkTerpilih = produk;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
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
                MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                    24,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Konfirmasi Pembayaran",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              const Divider(),

              const SizedBox(height: 8),

              _buildInvoiceRow(
                "Jenis Layanan",
                "Isi Ulang Pulsa Reguler",
              ),

              _buildInvoiceRow(
                "Produk",
                produk['name']
                        ?.toString() ??
                    "-",
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
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  const Text(
                    "Total Pembayaran",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                  Text(
                    "Rp ${rupiah(produk['sellingPrice'])}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          WarnaDesaPay.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        WarnaDesaPay.primary,
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    elevation: 0,
                  ),
                  onPressed:
                      _sedangTransaksi
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                              );

                              _buatPermintaanTransaksi(
                                produk,
                              );
                            },
                  child: const Text(
                    "Konfirmasi & Bayar",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
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

  // =========================================================
  // BUAT TRANSAKSI KE FIRESTORE
  // =========================================================

  Future<void> _buatPermintaanTransaksi(
    Map<String, dynamic> produk,
  ) async {
    if (_sedangTransaksi) {
      return;
    }

    final nomor =
        nomorController.text.trim();

    final sku =
        produk['sku']?.toString() ?? '';

    if (nomor.isEmpty) {
      _tampilkanPesan(
        "Nomor tujuan belum diisi.",
      );
      return;
    }

    if (sku.isEmpty) {
      _tampilkanPesan(
        "SKU produk tidak valid.",
      );
      return;
    }

    setState(() {
      _sedangTransaksi = true;
    });

    // ID transaksi unik
    final transaksiRef =
        _db.collection('transaction_requests').doc();

    final harga =
        _toNum(
      produk['sellingPrice'],
    ).toInt();

    try {
      await transaksiRef.set({
        'transactionId':
            transaksiRef.id,

        'type': 'PULSA',

        'category': 'PULSA',

        'sku': sku,

        'productName':
            produk['name']?.toString() ??
                '-',

        'brand':
            produk['brand']?.toString() ??
                _operatorTerdeteksi,

        'customerNo': nomor,

        'operator':
            _operatorTerdeteksi,

        'amount': harga,

        'status': 'WAITING',

        'paymentMethod':
            'SALDO_UTAMA',

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

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
  // MONITOR STATUS TRANSAKSI
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
              .collection(
                'transaction_requests',
              )
              .doc(transactionId)
              .snapshots(),

          builder:
              (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                title:
                    Text("Memproses Transaksi"),
                content: Column(
                  mainAxisSize:
                      MainAxisSize.min,
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
                snapshot.data!.data() ??
                    {};

            final status =
                (data['status'] ??
                        'WAITING')
                    .toString()
                    .toUpperCase();

            final sn =
                data['sn']
                        ?.toString() ??
                    '';

            final message =
                data['message']
                        ?.toString() ??
                    '';

            // =============================================
            // MENUNGGU
            // =============================================

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

            // =============================================
            // SUKSES
            // =============================================

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

                    const SizedBox(
                      height: 16,
                    ),

                    Text(
                      produk['name']
                              ?.toString() ??
                          '-',
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      "Nomor: ${nomorController.text}",
                    ),

                    if (sn.isNotEmpty) ...[
                      const SizedBox(
                        height: 8,
                      ),
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
                        _operatorTerdeteksi =
                            "";
                        _daftarPulsaReguler =
                            [];
                        _produkTerpilih =
                            null;
                      });
                    },
                    child:
                        const Text("Selesai"),
                  ),
                ],
              );
            }

            // =============================================
            // GAGAL
            // =============================================

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

                  const SizedBox(
                    height: 16,
                  ),

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
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  Colors.grey.shade500,
              fontSize: 13,
            ),
          ),

          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
                fontSize: 13,
                color:
                    Colors.black87,
              ),
              textAlign:
                  TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PESAN
  // =========================================================

  void _tampilkanPesan(
    String pesan,
  ) {
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
  Widget build(
    BuildContext context,
  ) {
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
            fontWeight:
                FontWeight.bold,
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
          // ===================================================
          // INPUT NOMOR
          // ===================================================

          Container(
            width: double.infinity,
            color: Colors.white,

            padding:
                const EdgeInsets.all(
              20,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nomor Handphone Tujuan",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.black87,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                TextField(
                  controller:
                      nomorController,

                  keyboardType:
                      TextInputType.phone,

                  style:
                      const TextStyle(
                    color:
                        Colors.black87,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),

                  onChanged: (value) {
                    _deteksiOperatorOtomatis(
                      value,
                    );
                  },

                  decoration:
                      InputDecoration(
                    filled: true,

                    fillColor:
                        const Color(
                      0xFFF1F5F9,
                    ),

                    hintText:
                        "Contoh: 08xxxxxxxxxx",

                    prefixIcon:
                        Icon(
                      Icons
                          .phone_android_rounded,
                      color:
                          WarnaDesaPay
                              .primary,
                    ),

                    suffixIcon:
                        _operatorTerdeteksi
                                .isEmpty
                            ? null
                            : Padding(
                                padding:
                                    const EdgeInsets.only(
                                  right: 12,
                                ),
                                child:
                                    Center(
                                  child:
                                      Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal:
                                          10,
                                      vertical:
                                          6,
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

          const SizedBox(
            height: 12,
          ),

          if (_operatorTerdeteksi
              .isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 6,
              ),
              child: Text(
                "Pilih Nominal Pulsa Reguler",
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 15,
                  color:
                      Colors.grey.shade800,
                ),
              ),
            ),

          // ===================================================
          // GRID PRODUK
          // ===================================================

          Expanded(
            child: _sedangMemuat
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : nomorController
                            .text
                            .length <
                        4
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
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                                fontSize:
                                    13,
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
                              horizontal:
                                  20,
                              vertical:
                                  6,
                            ),

                            itemCount:
                                _daftarPulsaReguler
                                    .length,

                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  2,
                              crossAxisSpacing:
                                  12,
                              mainAxisSpacing:
                                  12,
                              childAspectRatio:
                                  1.3,
                            ),

                            itemBuilder:
                                (context,
                                    index) {
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
                                        color: Colors.black
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
                                        maxLines:
                                            2,
                                        overflow:
                                            TextOverflow.ellipsis,
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
                                              WarnaDesaPay.primary,
                                          fontWeight:
                                              FontWeight.w900,
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
