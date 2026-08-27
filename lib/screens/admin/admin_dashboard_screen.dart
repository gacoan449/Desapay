import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../../services/digiflazz_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
  });

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  // =========================================================
  // STATE
  // =========================================================

  int menu = 0;

  double saldo = 0;

  bool loadingSaldo = false;
  bool syncing = false;
  bool loadingProducts = false;
  bool loadingTransactions = false;

  DateTime? lastSync;

  final List<Map<String, dynamic>> products = [];

  final List<Map<String, dynamic>> transactions = [];

  final List<Map<String, dynamic>> users = [
    {
      'id': 'USR001',
      'name': 'User Demo',
      'email': 'user@email.com',
      'status': 'Aktif',
      'reason': '',
    },
  ];

  final List<Map<String, dynamic>> tickets = [];

  final List<Map<String, dynamic>> apiLogs = [];

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadSaldo();
    _muatProdukDariFirestore();
    _muatTransaksiDariFirestore();
  }

  // =========================================================
  // HELPER ANGKA
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
  // LOAD PRODUK FIRESTORE
  // =========================================================

  Future<void> _muatProdukDariFirestore() async {
    if (!mounted) return;

    setState(() {
      loadingProducts = true;
    });

    try {
      // Ambil SEMUA produk.
      //
      // Jangan gunakan query active == true di Admin,
      // karena produk nonaktif juga harus terlihat oleh admin.
      final data =
          await FirestoreService.ambilSemuaProduk();

      if (!mounted) return;

      final List<Map<String, dynamic>>
          hasil = [];

      for (final item in data) {
        final product =
            Map<String, dynamic>.from(item);

        product['sku'] =
            product['sku']?.toString() ?? '';

        product['name'] =
            product['name']?.toString() ?? '-';

        product['category'] =
            product['category']?.toString() ??
                '-';

        product['brand'] =
            product['brand']?.toString() ?? '-';

        product['cost'] =
            _parseDouble(product['cost']);

        // MARGIN SEPENUHNYA DARI ADMIN
        product['margin'] =
            _parseDouble(product['margin']);

        product['active'] =
            product['active'] == true;

        hasil.add(product);
      }

      setState(() {
        products.clear();
        products.addAll(hasil);
      });
    } catch (e) {
      addLog(
        'Firestore / ambil produk',
        e.toString(),
      );
    }

    if (!mounted) return;

    setState(() {
      loadingProducts = false;
    });
  }

  // =========================================================
  // LOAD TRANSAKSI
  // =========================================================

  Future<void>
      _muatTransaksiDariFirestore() async {
    if (!mounted) return;

    setState(() {
      loadingTransactions = true;
    });

    try {
      final data =
          await FirestoreService
              .ambilSemuaTransaksi();

      if (!mounted) return;

      setState(() {
        transactions.clear();
        transactions.addAll(data);
      });
    } catch (e) {
      addLog(
        'Firestore / ambil transaksi',
        e.toString(),
      );
    }

    if (!mounted) return;

    setState(() {
      loadingTransactions = false;
    });
  }

  // =========================================================
  // CEK SALDO DIGIFLAZZ
  // =========================================================

  Future<void> loadSaldo() async {
    if (!mounted) return;

    setState(() {
      loadingSaldo = true;
    });

    try {
      final result =
          await DigiflazzService()
              .cekSaldoModal();

      if (!mounted) return;

      setState(() {
        saldo =
            result.toDouble();
      });
    } catch (e) {
      addLog(
        '/cek-saldo',
        e.toString(),
      );
    }

    if (!mounted) return;

    setState(() {
      loadingSaldo = false;
    });
  }

  // =========================================================
  // SYNC PRODUK DIGIFLAZZ
  // =========================================================
  //
  // ATURAN:
  //
  // Digiflazz = sumber HARGA MODAL
  // Admin     = sumber MARGIN
  //
  // Produk lama:
  //   margin tetap
  //   active tetap
  //
  // Produk baru:
  //   margin = 0
  //   active = true
  //
  // =========================================================

  Future<void> syncProducts() async {
    if (lastSync != null) {
      final difference =
          DateTime.now().difference(
        lastSync!,
      );

      if (difference.inMinutes < 5) {
        final wait =
            5 - difference.inMinutes;

        message(
          'Tunggu $wait menit sebelum sync lagi.',
        );

        return;
      }
    }

    if (!mounted) return;

    setState(() {
      syncing = true;
    });

    try {
      // =====================================================
      // AMBIL DATA LAMA DARI FIRESTORE
      //
      // Ini lebih aman daripada hanya membaca products
      // yang sedang tampil di layar.
      // Produk nonaktif tetap mempunyai margin.
      // =====================================================

      final dataLama =
          await FirestoreService
              .ambilSemuaProduk();

      final Map<String, Map<String, dynamic>>
          produkLama = {};

      for (final item in dataLama) {
        final sku =
            item['sku']?.toString() ?? '';

        if (sku.isEmpty) {
          continue;
        }

        produkLama[sku] =
            Map<String, dynamic>.from(item);
      }

      // =====================================================
      // AMBIL PRICE LIST DIGIFLAZZ
      // =====================================================

      final List<dynamic> data =
          await DigiflazzService()
              .ambilSemuaProduk();

      if (data.isEmpty) {
        throw Exception(
          'Price list Digiflazz kosong.',
        );
      }

      final List<Map<String, dynamic>>
          hasilProduk = [];

      for (final item in data) {
        if (item is! Map) {
          continue;
        }

        final sku =
            item['buyer_sku_code']
                    ?.toString() ??
                '';

        if (sku.isEmpty) {
          continue;
        }

        final hargaModal =
            _parseDouble(
          item['price'],
        );

        // ===================================================
        // CARI DATA LAMA
        // ===================================================

        final dataLamaProduk =
            produkLama[sku];

        // ===================================================
        // MARGIN LAMA
        //
        // TIDAK DIUBAH OLEH DIGIFLAZZ
        // ===================================================

        final double margin =
            dataLamaProduk == null
                ? 0
                : _parseDouble(
                    dataLamaProduk[
                        'margin'],
                  );

        // ===================================================
        // STATUS LAMA
        //
        // Kalau admin sebelumnya menonaktifkan produk,
        // status tersebut tetap dipertahankan.
        //
        // Produk baru otomatis aktif.
        // ===================================================

        final bool active =
            dataLamaProduk == null
                ? true
                : dataLamaProduk[
                        'active'] ==
                    true;

        hasilProduk.add({
          'sku': sku,

          'name':
              item['product_name']
                      ?.toString() ??
                  '-',

          'category':
              item['category']
                      ?.toString() ??
                  '-',

          'brand':
              item['brand']
                      ?.toString() ??
                  '-',

          // HANYA HARGA MODAL DARI DIGIFLAZZ
          'cost': hargaModal,

          // MARGIN ADMIN
          'margin': margin,

          // STATUS ADMIN
          'active': active,
        });
      }

      if (hasilProduk.isEmpty) {
        throw Exception(
          'Tidak ada produk valid dari Digiflazz.',
        );
      }

      // =====================================================
      // SIMPAN FIRESTORE
      // =====================================================

      await FirestoreService.simpanProduk(
        hasilProduk,
      );

      if (!mounted) return;

      // =====================================================
      // UPDATE TAMPILAN
      // =====================================================

      setState(() {
        products.clear();
        products.addAll(
          hasilProduk,
        );

        lastSync =
            DateTime.now();
      });

      message(
        '${hasilProduk.length} produk berhasil sync. '
        'Modal diperbarui, margin admin tetap. ✅',
      );
    } catch (e) {
      addLog(
        '/price-list',
        e.toString(),
      );

      if (mounted) {
        message(
          'Sync gagal: $e',
        );
      }
    }

    if (!mounted) return;

    setState(() {
      syncing = false;
    });
  }

  // =========================================================
  // UPDATE MARGIN
  // =========================================================

  Future<void> updateMargin(
    Map<String, dynamic> product,
    String value,
  ) async {
    final sku =
        product['sku']?.toString() ?? '';

    if (sku.isEmpty) {
      message(
        'SKU produk tidak ditemukan.',
      );
      return;
    }

    final text =
        value.trim();

    if (text.isEmpty) {
      message(
        'Margin tidak boleh kosong.',
      );
      return;
    }

    final double newMargin =
        _parseDouble(text);

    if (newMargin < 0) {
      message(
        'Margin tidak boleh negatif.',
      );
      return;
    }

    final oldMargin =
        _parseDouble(
      product['margin'],
    );

    // Update UI dulu.
    setState(() {
      product['margin'] =
          newMargin;
    });

    try {
      await FirestoreService
          .updateMargin(
        sku,
        newMargin,
      );

      if (!mounted) return;

      message(
        'Margin ${rupiah(newMargin)} berhasil disimpan. ✅',
      );
    } catch (e) {
      // Kembalikan nilai lama kalau gagal.
      if (mounted) {
        setState(() {
          product['margin'] =
              oldMargin;
        });
      }

      addLog(
        'Firestore / update margin',
        e.toString(),
      );

      if (mounted) {
        message(
          'Gagal menyimpan margin: $e',
        );
      }
    }
  }

  // =========================================================
  // UPDATE STATUS PRODUK
  // =========================================================

  Future<void> updateProductStatus(
    Map<String, dynamic> product,
    bool value,
  ) async {
    final sku =
        product['sku']?.toString() ?? '';

    if (sku.isEmpty) {
      message(
        'SKU produk tidak ditemukan.',
      );
      return;
    }

    final oldValue =
        product['active'] == true;

    setState(() {
      product['active'] =
          value;
    });

    try {
      await FirestoreService
          .updateProductActive(
        sku,
        value,
      );

      if (!mounted) return;

      message(
        value
            ? 'Produk diaktifkan. ✅'
            : 'Produk dinonaktifkan. ⛔',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          product['active'] =
              oldValue;
        });
      }

      addLog(
        'Firestore / update product active',
        e.toString(),
      );

      if (mounted) {
        message(
          'Gagal menyimpan status produk: $e',
        );
      }
    }
  }

  // =========================================================
  // CEK STATUS TRANSAKSI
  // =========================================================
  //
  // Untuk sementara status transaksi dibaca dari Firestore.
  // Jangan panggil method transaction yang tidak ada di
  // DigiflazzService.
  //
  // =========================================================

  Future<void> checkTransaction(
    String refId,
  ) async {
    try {
      final data =
          await FirestoreService
              .ambilSemuaTransaksi();

      final found =
          data.where(
        (trx) =>
            trx['ref_id']
                ?.toString() ==
            refId,
      );

      if (found.isEmpty) {
        message(
          'Transaksi tidak ditemukan.',
        );
        return;
      }

      final trx =
          found.first;

      message(
        'Status: ${trx['status'] ?? 'Tidak diketahui'}',
      );
    } catch (e) {
      addLog(
        'Firestore / transaksi',
        e.toString(),
      );

      if (mounted) {
        message(
          'Gagal cek transaksi.',
        );
      }
    }
  }

  // =========================================================
  // API LOG
  // =========================================================

  void addLog(
    String endpoint,
    String error,
  ) {
    if (!mounted) return;

    setState(() {
      apiLogs.insert(
        0,
        {
          'time':
              DateTime.now()
                  .toString(),
          'endpoint':
              endpoint,
          'error':
              error,
        },
      );
    });
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void message(
    String text,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(text),
      ),
    );
  }

  // =========================================================
  // RUPIAH
  // =========================================================

  String rupiah(
    num value,
  ) {
    final text =
        value.toStringAsFixed(0);

    final result =
        text.replaceAllMapped(
      RegExp(
        r'(\d)(?=(\d{3})+(?!\d))',
      ),
      (match) =>
          '${match[1]}.',
    );

    return 'Rp $result';
  }

  // =========================================================
  // STAT CARD
  // =========================================================

  Widget stat(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child:
            Row(
          children: [
            CircleAvatar(
              child:
                  Icon(icon),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style:
                        TextStyle(
                      color:
                          Colors.grey[
                              600],
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    value,
                    style:
                        const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DASHBOARD
  // =========================================================

  Widget dashboard() {
    return RefreshIndicator(
      onRefresh: () async {
        await loadSaldo();
        await _muatProdukDariFirestore();
        await _muatTransaksiDariFirestore();
      },
      child:
          ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'Dashboard DesaPay',
            style:
                TextStyle(
              fontSize: 27,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Command Center Admin',
            style:
                TextStyle(
              color:
                  Colors.grey,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          LayoutBuilder(
            builder:
                (
              context,
              constraints,
            ) {
              final width =
                  constraints
                      .maxWidth;

              final columns =
                  width >= 900
                      ? 4
                      : width >= 600
                          ? 2
                          : 1;

              return GridView.count(
                crossAxisCount:
                    columns,
                shrinkWrap:
                    true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisSpacing:
                    12,
                mainAxisSpacing:
                    12,
                childAspectRatio:
                    width < 600
                        ? 3.5
                        : 2.8,
                children: [
                  stat(
                    'Saldo Digiflazz',
                    loadingSaldo
                        ? 'Memuat...'
                        : rupiah(
                            saldo,
                          ),
                    Icons
                        .account_balance_wallet,
                  ),

                  stat(
                    'Produk',
                    products
                        .length
                        .toString(),
                    Icons.inventory,
                  ),

                  stat(
                    'Transaksi',
                    transactions
                        .length
                        .toString(),
                    Icons.receipt_long,
                  ),

                  stat(
                    'Pengguna',
                    users
                        .length
                        .toString(),
                    Icons.people,
                  ),
                ],
              );
            },
          ),

          const SizedBox(
            height: 20,
          ),

          Card(
            child:
                Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'Sinkronisasi Produk',
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    lastSync == null
                        ? 'Belum sync dari sesi ini'
                        : 'Terakhir sync: $lastSync',
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'Harga modal diambil dari Digiflazz. '
                    'Margin dan status produk sepenuhnya '
                    'mengikuti pengaturan Admin.',
                    style:
                        TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          syncing
                              ? null
                              : syncProducts,
                      icon:
                          syncing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Icon(
                                  Icons.sync,
                                ),
                      label:
                          Text(
                        syncing
                            ? 'Syncing...'
                            : 'Manual Sync & Simpan',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Card(
            child:
                ListTile(
              leading:
                  const Icon(
                Icons.cloud_done,
              ),
              title:
                  const Text(
                'Database Produk',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle:
                  Text(
                loadingProducts
                    ? 'Memuat dari Firestore...'
                    : '${products.length} produk tersedia',
              ),
              trailing:
                  IconButton(
                icon:
                    const Icon(
                  Icons.refresh,
                ),
                onPressed:
                    _muatProdukDariFirestore,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PRODUK
  // =========================================================

  Widget productsPage() {
    return Padding(
      padding:
          const EdgeInsets.all(
        16,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Row(
            children: [
              const Expanded(
                child:
                    Text(
                  'Produk',
                  style:
                      TextStyle(
                    fontSize: 27,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed:
                    syncing
                        ? null
                        : syncProducts,
                icon:
                    const Icon(
                  Icons.sync,
                ),
                label:
                    const Text(
                  'Sync',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Harga jual = Harga Modal Digiflazz + Margin Admin',
            style:
                TextStyle(
              color:
                  Colors.grey,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Expanded(
            child:
                Card(
              child:
                  products.isEmpty
                      ? const Center(
                          child:
                              Text(
                            'Belum ada produk.\n'
                            'Silakan Manual Sync.',
                            textAlign:
                                TextAlign
                                    .center,
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection:
                              Axis.horizontal,
                          child:
                              SingleChildScrollView(
                            child:
                                DataTable(
                              columns:
                                  const [
                                DataColumn(
                                  label:
                                      Text(
                                    'SKU',
                                  ),
                                ),
                                DataColumn(
                                  label:
                                      Text(
                                    'Produk',
                                  ),
                                ),
                                DataColumn(
                                  label:
                                      Text(
                                    'Kategori',
                                  ),
                                ),
                                DataColumn(
                                  label:
                                      Text(
                                    'Modal',
                                  ),
                                ),
                                DataColumn(
                                  label:
                                      Text(
                                    'Margin Admin',
                                  ),
                                ),
                                DataColumn(
                                  label:
                                      Text(
                                    'Harga Jual',
                                  ),
                                ),
                                DataColumn(
                                  label:
                                      Text(
                                    'Aktif',
                                  ),
                                ),
                              ],
                              rows:
                                  products.map(
                                (
                                  product,
                                ) {
                                  final cost =
                                      _parseDouble(
                                    product[
                                        'cost'],
                                  );

                                  final margin =
                                      _parseDouble(
                                    product[
                                        'margin'],
                                  );

                                  final hargaJual =
                                      cost +
                                          margin;

                                  return DataRow(
                                    cells: [
                                      // SKU
                                      DataCell(
                                        Text(
                                          product[
                                                      'sku']
                                                  ?.toString() ??
                                              '-',
                                        ),
                                      ),

                                      // NAMA
                                      DataCell(
                                        SizedBox(
                                          width:
                                              220,
                                          child:
                                              Text(
                                            product[
                                                        'name']
                                                    ?.toString() ??
                                                '-',
                                          ),
                                        ),
                                      ),

                                      // KATEGORI
                                      DataCell(
                                        Text(
                                          product[
                                                      'category']
                                                  ?.toString() ??
                                              '-',
                                        ),
                                      ),

                                      // MODAL
                                      DataCell(
                                        Text(
                                          rupiah(
                                            cost,
                                          ),
                                        ),
                                      ),

                                      // =================================================
                                      // MARGIN ADMIN
                                      // =================================================
                                      DataCell(
                                        SizedBox(
                                          width:
                                              140,
                                          child:
                                              TextFormField(
                                            key:
                                                ValueKey(
                                              '${product['sku']}_${margin}',
                                            ),
                                            initialValue:
                                                margin.toStringAsFixed(
                                              0,
                                            ),
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                              decimal:
                                                  false,
                                            ),
                                            onFieldSubmitted:
                                                (
                                              value,
                                            ) async {
                                              await updateMargin(
                                                product,
                                                value,
                                              );
                                            },
                                            decoration:
                                                const InputDecoration(
                                              prefixText:
                                                  'Rp ',
                                              hintText:
                                                  'Margin',
                                              isDense:
                                                  true,
                                              border:
                                                  OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // HARGA JUAL
                                      DataCell(
                                        Text(
                                          rupiah(
                                            hargaJual,
                                          ),
                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      // STATUS
                                      DataCell(
                                        Switch(
                                          value:
                                              product[
                                                      'active'] ==
                                                  true,
                                          onChanged:
                                              (
                                            value,
                                          ) {
                                            updateProductStatus(
                                              product,
                                              value,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TRANSAKSI
  // =========================================================

  Widget transactionPage() {
    return RefreshIndicator(
      onRefresh:
          _muatTransaksiDariFirestore,
      child:
          ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(
          16,
        ),
        children: [
          Row(
            children: [
              const Expanded(
                child:
                    Text(
                  'Monitor Transaksi',
                  style:
                      TextStyle(
                    fontSize: 27,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              IconButton(
                onPressed:
                    loadingTransactions
                        ? null
                        : _muatTransaksiDariFirestore,
                icon:
                    const Icon(
                  Icons.refresh,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          if (loadingTransactions)
            const Center(
              child:
                  Padding(
                padding:
                    EdgeInsets.all(
                  30,
                ),
                child:
                    CircularProgressIndicator(),
              ),
            )
          else if (transactions.isEmpty)
            const Card(
              child:
                  Padding(
                padding:
                    EdgeInsets.all(
                  30,
                ),
                child:
                    Center(
                  child:
                      Text(
                    'Belum ada transaksi.',
                  ),
                ),
              ),
            )
          else
            Card(
              child:
                  SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal,
                child:
                    DataTable(
                  columns:
                      const [
                    DataColumn(
                      label:
                          Text(
                        'Ref ID',
                      ),
                    ),
                    DataColumn(
                      label:
                          Text(
                        'User',
                      ),
                    ),
                    DataColumn(
                      label:
                          Text(
                        'Produk',
                      ),
                    ),
                    DataColumn(
                      label:
                          Text(
                        'Nominal',
                      ),
                    ),
                    DataColumn(
                      label:
                          Text(
                        'Status',
                      ),
                    ),
                    DataColumn(
                      label:
                          Text(
                        'Action',
                      ),
                    ),
                  ],
                  rows:
                      transactions.map(
                    (
                      trx,
                    ) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              trx[
                                      'ref_id']
                                  ?.toString() ??
                                  '-',
                            ),
                          ),
                          DataCell(
                            Text(
                              trx[
                                      'user']
                                  ?.toString() ??
                                  '-',
                            ),
                          ),
                          DataCell(
                            Text(
                              trx[
                                      'product']
                                  ?.toString() ??
                                  '-',
                            ),
                          ),
                          DataCell(
                            Text(
                              rupiah(
                                _parseDouble(
                                  trx[
                                      'amount'],
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              trx[
                                      'status']
                                  ?.toString() ??
                                  '-',
                            ),
                          ),
                          DataCell(
                            ElevatedButton(
                              onPressed:
                                  () {
                                checkTransaction(
                                  trx[
                                          'ref_id']
                                      ?.toString() ??
                                      '',
                                );
                              },
                              child:
                                  const Text(
                                'Cek',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ).toList(),
                ),
              ),
            ),

          const SizedBox(
            height: 25,
          ),

          const Text(
            'API Error Log',
            style:
                TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          if (apiLogs.isEmpty)
            const Card(
              child:
                  Padding(
                padding:
                    EdgeInsets.all(
                  20,
                ),
                child:
                    Text(
                  'Belum ada error API.',
                ),
              ),
            )
          else
            ...apiLogs.map(
              (
                log,
              ) =>
                  Card(
                child:
                    ListTile(
                  leading:
                      const Icon(
                    Icons.error,
                    color:
                        Colors.red,
                  ),
                  title:
                      Text(
                    log[
                            'endpoint']
                        ?.toString() ??
                        '-',
                  ),
                  subtitle:
                      Text(
                    log[
                            'error']
                        ?.toString() ??
                        '-',
                  ),
                  trailing:
                      Text(
                    log[
                            'time']
                        ?.toString() ??
                        '',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // USERS
  // =========================================================

  Widget usersPage() {
    return ListView(
      padding:
          const EdgeInsets.all(
        16,
      ),
      children: [
        const Text(
          'Manajemen Pengguna',
          style:
              TextStyle(
            fontSize: 27,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        Card(
          child:
              SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,
            child:
                DataTable(
              columns:
                  const [
                DataColumn(
                  label:
                      Text('ID'),
                ),
                DataColumn(
                  label:
                      Text('Nama'),
                ),
                DataColumn(
                  label:
                      Text('Email'),
                ),
                DataColumn(
                  label:
                      Text('Status'),
                ),
                DataColumn(
                  label:
                      Text('Alasan'),
                ),
                DataColumn(
                  label:
                      Text('Action'),
                ),
              ],
              rows:
                  users.asMap().entries.map(
                (
                  entry,
                ) {
                  final index =
                      entry.key;

                  final user =
                      entry.value;

                  final blocked =
                      user[
                              'status'] ==
                          'Diblokir';

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          user[
                              'id'],
                        ),
                      ),
                      DataCell(
                        Text(
                          user[
                              'name'],
                        ),
                      ),
                      DataCell(
                        Text(
                          user[
                              'email'],
                        ),
                      ),
                      DataCell(
                        Text(
                          user[
                              'status'],
                        ),
                      ),
                      DataCell(
                        Text(
                          user[
                                      'reason']
                                  .toString()
                                  .isEmpty
                              ? '-'
                              : user[
                                  'reason'],
                        ),
                      ),
                      DataCell(
                        blocked
                            ? OutlinedButton(
                                onPressed:
                                    () {
                                  setState(
                                    () {
                                      user[
                                              'status'] =
                                          'Aktif';

                                      user[
                                              'reason'] =
                                          '';
                                    },
                                  );
                                },
                                child:
                                    const Text(
                                  'Buka',
                                ),
                              )
                            : ElevatedButton(
                                style:
                                    ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.red,
                                  foregroundColor:
                                      Colors.white,
                                ),
                                onPressed:
                                    () {
                                  blockUser(
                                    index,
                                  );
                                },
                                child:
                                    const Text(
                                  'Blokir',
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BLOKIR USER
  // =========================================================

  void blockUser(
    int index,
  ) {
    final controller =
        TextEditingController();

    showDialog(
      context:
          context,
      builder:
          (
        _,
      ) {
        return AlertDialog(
          title:
              const Text(
            'Blokir Pengguna',
          ),
          content:
              TextField(
            controller:
                controller,
            maxLines:
                3,
            decoration:
                const InputDecoration(
              labelText:
                  'Alasan',
              border:
                  OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  () =>
                      Navigator.pop(
                context,
              ),
              child:
                  const Text(
                'Batal',
              ),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed:
                  () {
                if (controller
                    .text
                    .trim()
                    .isEmpty) {
                  message(
                    'Alasan wajib diisi.',
                  );
                  return;
                }

                setState(
                  () {
                    users[
                            index]
                        [
                            'status'] =
                        'Diblokir';

                    users[
                            index]
                        [
                            'reason'] =
                        controller
                            .text
                            .trim();
                  },
                );

                Navigator.pop(
                  context,
                );

                message(
                  'Pengguna diblokir.',
                );
              },
              child:
                  const Text(
                'Blokir',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // TICKETS
  // =========================================================

  Widget ticketsPage() {
    return ListView(
      padding:
          const EdgeInsets.all(
        16,
      ),
      children: [
        const Text(
          'CS / Keluhan',
          style:
              TextStyle(
            fontSize: 27,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        if (tickets.isEmpty)
          const Card(
            child:
                Padding(
              padding:
                  EdgeInsets.all(
                30,
              ),
              child:
                  Center(
                child:
                    Text(
                  'Belum ada tiket keluhan.',
                ),
              ),
            ),
          ),

        ...tickets.map(
          (
            ticket,
          ) {
            return Card(
              child:
                  ListTile(
                leading:
                    const CircleAvatar(
                  child:
                      Icon(
                    Icons.support_agent,
                  ),
                ),
                title:
                    Text(
                  '${ticket['id']} • ${ticket['user']}',
                ),
                subtitle:
                    Text(
                  ticket[
                          'message']
                      ?.toString() ??
                      '-',
                ),
                trailing:
                    DropdownButton<String>(
                  value:
                      ticket[
                          'status'],
                  items:
                      const [
                    DropdownMenuItem(
                      value:
                          'Open',
                      child:
                          Text(
                        'Open',
                      ),
                    ),
                    DropdownMenuItem(
                      value:
                          'Diproses',
                      child:
                          Text(
                        'Diproses',
                      ),
                    ),
                    DropdownMenuItem(
                      value:
                          'Selesai',
                      child:
                          Text(
                        'Selesai',
                      ),
                    ),
                  ],
                  onChanged:
                      (
                    value,
                  ) {
                    if (value ==
                        null) {
                      return;
                    }

                    setState(
                      () {
                        ticket[
                                'status'] =
                            value;
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // LOGS
  // =========================================================

  Widget logsPage() {
    return ListView(
      padding:
          const EdgeInsets.all(
        16,
      ),
      children: [
        const Text(
          'API Error Log',
          style:
              TextStyle(
            fontSize: 27,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        if (apiLogs.isEmpty)
          const Card(
            child:
                Padding(
              padding:
                  EdgeInsets.all(
                30,
              ),
              child:
                  Center(
                child:
                    Text(
                  'Belum ada error API.',
                ),
              ),
            ),
          ),

        ...apiLogs.map(
          (
            log,
          ) =>
              Card(
            child:
                ListTile(
              leading:
                  const Icon(
                Icons.error,
                color:
                    Colors.red,
              ),
              title:
                  Text(
                log[
                        'endpoint']
                    ?.toString() ??
                    '-',
              ),
              subtitle:
                  Text(
                log[
                        'error']
                    ?.toString() ??
                    '-',
              ),
              trailing:
                  Text(
                log[
                        'time']
                    ?.toString() ??
                    '',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CONTENT
  // =========================================================

  Widget content() {
    switch (menu) {
      case 0:
        return dashboard();

      case 1:
        return productsPage();

      case 2:
        return transactionPage();

      case 3:
        return usersPage();

      case 4:
        return ticketsPage();

      case 5:
        return logsPage();

      default:
        return dashboard();
    }
  }

  // =========================================================
  // MENU
  // =========================================================

  Widget menuList({
    bool closeDrawer = false,
  }) {
    Widget item(
      IconData icon,
      String title,
      int index,
    ) {
      return ListTile(
        selected:
            menu == index,
        leading:
            Icon(icon),
        title:
            Text(title),
        onTap:
            () {
          setState(
            () {
              menu = index;
            },
          );

          if (closeDrawer) {
            Navigator.pop(
              context,
            );
          }
        },
      );
    }

    return Column(
      children: [
        item(
          Icons.dashboard,
          'Dashboard',
          0,
        ),
        item(
          Icons.inventory,
          'Produk',
          1,
        ),
        item(
          Icons.receipt_long,
          'Transaksi',
          2,
        ),
        item(
          Icons.people,
          'Pengguna',
          3,
        ),
        item(
          Icons.support_agent,
          'CS / Keluhan',
          4,
        ),
        item(
          Icons.error_outline,
          'API Logs',
          5,
        ),
      ],
    );
  }

  // =========================================================
  // DESKTOP SIDEBAR
  // =========================================================

  Widget desktopSidebar() {
    return Container(
      width:
          240,
      color:
          Colors.grey.shade100,
      child:
          Column(
        children: [
          const SizedBox(
            height: 30,
          ),

          const Icon(
            Icons.admin_panel_settings,
            size: 50,
          ),

          const SizedBox(
            height: 10,
          ),

          const Text(
            'DESAPAY ADMIN',
            style:
                TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          menuList(),

          const Spacer(),

          const Padding(
            padding:
                EdgeInsets.all(
              15,
            ),
            child:
                Text(
              'DesaPay Admin v1.0',
              style:
                  TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MOBILE DRAWER
  // =========================================================

  Widget mobileDrawer() {
    return Drawer(
      child:
          SafeArea(
        child:
            Column(
          children: [
            const SizedBox(
              height: 25,
            ),

            const Icon(
              Icons.admin_panel_settings,
              size: 55,
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'DESAPAY ADMIN',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            menuList(
              closeDrawer:
                  true,
            ),

            const Spacer(),

            const Padding(
              padding:
                  EdgeInsets.all(
                15,
              ),
              child:
                  Text(
                'DesaPay Admin v1.0',
                style:
                    TextStyle(
                  color:
                      Colors.grey,
                ),
              ),
            ),
          ],
        ),
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
    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {
        final isMobile =
            constraints.maxWidth <
                700;

        if (isMobile) {
          return Scaffold(
            appBar:
                AppBar(
              title:
                  Text(
                [
                  'Dashboard',
                  'Produk',
                  'Transaksi',
                  'Pengguna',
                  'CS / Keluhan',
                  'API Logs',
                ][menu],
              ),
              backgroundColor:
                  Theme.of(
                context,
              )
                      .colorScheme
                      .primary,
              foregroundColor:
                  Colors.white,
            ),
            drawer:
                mobileDrawer(),
            body:
                SafeArea(
              child:
                  content(),
            ),
          );
        }

        return Scaffold(
          body:
              Row(
            children: [
              desktopSidebar(),

              Expanded(
                child:
                    SafeArea(
                  child:
                      content(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
