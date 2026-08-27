import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../../services/digiflazz_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  int menu = 0;

  double saldo = 0;

  bool loadingSaldo = false;
  bool syncing = false;
  bool loadingProducts = false;

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

  @override
  void initState() {
    super.initState();

    loadSaldo();
    _muatProdukDariFirestore();
  }

  // =========================================================
  // LOAD PRODUK DARI FIRESTORE
  // =========================================================

  Future<void> _muatProdukDariFirestore() async {
    if (!mounted) return;

    setState(() {
      loadingProducts = true;
    });

    try {
      final data =
          await FirestoreService.ambilSemuaProduk();

      if (!mounted) return;

      if (data.isNotEmpty) {
        setState(() {
          products.clear();
          products.addAll(data);
        });
      }
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
  // CEK SALDO DIGIFLAZZ
  // =========================================================

  Future<void> loadSaldo() async {
    if (!mounted) return;

    setState(() {
      loadingSaldo = true;
    });

    try {
      final result =
          await DigiflazzService.saldo();

      final data = result['data'];

      if (!mounted) return;

      if (data != null) {
        setState(() {
          saldo = double.tryParse(
                data['deposit'].toString(),
              ) ??
              0;
        });
      }
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

  Future<void> syncProducts() async {
    if (lastSync != null) {
      final difference =
          DateTime.now().difference(lastSync!);

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
      final result =
          await DigiflazzService.priceList();

      final data = result['data'];

      if (data is List) {
        final List<Map<String, dynamic>>
            hasilProduk = [];

        for (final item in data) {
          final price =
              double.tryParse(
                    item['price']
                            ?.toString() ??
                        '0',
                  ) ??
                  0;

          hasilProduk.add({
            'sku':
                item['buyer_sku_code']
                    ?.toString() ??
                    '-',

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

            'cost': price,

            'margin': 1000,

            'active': true,
          });
        }

        // Update tampilan lokal
        if (!mounted) return;

        setState(() {
          products.clear();
          products.addAll(hasilProduk);
        });

        // =====================================================
        // SIMPAN KE FIRESTORE
        // =====================================================

        await FirestoreService.simpanProduk(
          hasilProduk,
        );

        lastSync = DateTime.now();

        if (!mounted) return;

        message(
          '${hasilProduk.length} produk berhasil disinkronkan & tersimpan! ✅',
        );
      }
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
  // CEK STATUS TRANSAKSI
  // =========================================================

  Future<void> checkTransaction(
    String refId,
  ) async {
    try {
      final result =
          await DigiflazzService.transaction(
        refId: refId,
      );

      if (!mounted) return;

      message(
        'Status: ${result['data']?['status'] ?? 'Tidak diketahui'}',
      );
    } catch (e) {
      addLog(
        '/transaction',
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
              DateTime.now().toString(),
          'endpoint':
              endpoint,
          'error':
              error,
        },
      );
    });
  }

  void message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  // =========================================================
  // FORMAT RUPIAH
  // =========================================================

  String rupiah(num value) {
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
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              child: Icon(icon),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 5),

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
      },
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'Dashboard DesaPay',
            style: TextStyle(
              fontSize: 27,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Command Center Admin',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder:
                (context, constraints) {
              final width =
                  constraints.maxWidth;

              final columns =
                  width >= 900
                      ? 4
                      : width >= 600
                          ? 2
                          : 1;

              return GridView.count(
                crossAxisCount:
                    columns,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio:
                    width < 600
                        ? 3.5
                        : 2.8,
                children: [
                  stat(
                    'Saldo Digiflazz',
                    rupiah(saldo),
                    Icons
                        .account_balance_wallet,
                  ),

                  stat(
                    'Produk',
                    products.length
                        .toString(),
                    Icons.inventory,
                  ),

                  stat(
                    'Transaksi',
                    transactions.length
                        .toString(),
                    Icons.receipt_long,
                  ),

                  stat(
                    'Pengguna',
                    users.length
                        .toString(),
                    Icons.people,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sinkronisasi Produk',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    lastSync == null
                        ? 'Belum sync dari sesi ini'
                        : 'Terakhir sync: $lastSync',
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          syncing
                              ? null
                              : syncProducts,
                      icon: syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.sync,
                            ),
                      label: Text(
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

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.cloud_done,
              ),
              title: const Text(
                'Database Produk',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle: Text(
                loadingProducts
                    ? 'Memuat dari Firestore...'
                    : '${products.length} produk tersedia dari Firestore',
              ),
              trailing:
                  IconButton(
                icon: const Icon(
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
          const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Produk',
                  style: TextStyle(
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
                icon: const Icon(
                  Icons.sync,
                ),
                label:
                    const Text('Sync'),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Expanded(
            child: Card(
              child:
                  products.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada produk.\nSilakan Manual Sync.',
                            textAlign:
                                TextAlign.center,
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection:
                              Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns:
                                  const [
                                DataColumn(
                                  label:
                                      Text('SKU'),
                                ),
                                DataColumn(
                                  label:
                                      Text('Produk'),
                                ),
                                DataColumn(
                                  label:
                                      Text('Kategori'),
                                ),
                                DataColumn(
                                  label:
                                      Text('Modal'),
                                ),
                                DataColumn(
                                  label:
                                      Text('Margin'),
                                ),
                                DataColumn(
                                  label:
                                      Text('Harga Jual'),
                                ),
                                DataColumn(
                                  label:
                                      Text('Aktif'),
                                ),
                              ],
                              rows:
                                  products.map(
                                (product) {
                                  final cost =
                                      double.tryParse(
                                            product['cost']
                                                    ?.toString() ??
                                                '0',
                                          ) ??
                                          0;

                                  final margin =
                                      double.tryParse(
                                            product['margin']
                                                    ?.toString() ??
                                                '0',
                                          ) ??
                                          0;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          product['sku']
                                                  ?.toString() ??
                                              '-',
                                        ),
                                      ),

                                      DataCell(
                                        SizedBox(
                                          width: 200,
                                          child:
                                              Text(
                                            product['name']
                                                    ?.toString() ??
                                                '-',
                                          ),
                                        ),
                                      ),

                                      DataCell(
                                        Text(
                                          product['category']
                                                  ?.toString() ??
                                              '-',
                                        ),
                                      ),

                                      DataCell(
                                        Text(
                                          rupiah(
                                            cost,
                                          ),
                                        ),
                                      ),

                                      // ===================================
                                      // EDIT MARGIN + FIRESTORE
                                      // ===================================

                                      DataCell(
                                        SizedBox(
                                          width: 110,
                                          child:
                                              TextFormField(
                                            initialValue:
                                                margin.toStringAsFixed(
                                              0,
                                            ),
                                            keyboardType:
                                                TextInputType.number,
                                            onFieldSubmitted:
                                                (value) async {
                                              final newMargin =
                                                  double.tryParse(
                                                        value,
                                                      ) ??
                                                      0;

                                              setState(
                                                () {
                                                  product[
                                                          'margin'] =
                                                      newMargin;
                                                },
                                              );

                                              try {
                                                await FirestoreService
                                                    .updateMargin(
                                                  product[
                                                      'sku'],
                                                  newMargin,
                                                );

                                                if (mounted) {
                                                  ScaffoldMessenger
                                                      .of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content:
                                                          Text(
                                                        'Harga diperbarui & tersimpan! ✅',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
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
                                            },
                                            decoration:
                                                const InputDecoration(
                                              prefixText:
                                                  'Rp ',
                                              isDense:
                                                  true,
                                            ),
                                          ),
                                        ),
                                      ),

                                      DataCell(
                                        Text(
                                          rupiah(
                                            cost +
                                                margin,
                                          ),
                                        ),
                                      ),

                                      DataCell(
                                        Switch(
                                          value:
                                              product['active'] ==
                                                  true,
                                          onChanged:
                                              (value) {
                                            setState(
                                              () {
                                                product[
                                                        'active'] =
                                                    value;
                                              },
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
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        const Text(
          'Monitor Transaksi',
          style: TextStyle(
            fontSize: 27,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        if (transactions.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'Belum ada transaksi.',
                ),
              ),
            ),
          )
        else
          Card(
            child: SingleChildScrollView(
              scrollDirection:
                  Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                    label:
                        Text('Ref ID'),
                  ),
                  DataColumn(
                    label:
                        Text('User'),
                  ),
                  DataColumn(
                    label:
                        Text('Produk'),
                  ),
                  DataColumn(
                    label:
                        Text('Nominal'),
                  ),
                  DataColumn(
                    label:
                        Text('Status'),
                  ),
                  DataColumn(
                    label:
                        Text('Action'),
                  ),
                ],
                rows:
                    transactions.map(
                  (trx) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            trx['ref_id']
                                .toString(),
                          ),
                        ),
                        DataCell(
                          Text(
                            trx['user']
                                .toString(),
                          ),
                        ),
                        DataCell(
                          Text(
                            trx['product']
                                .toString(),
                          ),
                        ),
                        DataCell(
                          Text(
                            rupiah(
                              trx['amount']
                                  as num,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            trx['status']
                                .toString(),
                          ),
                        ),
                        DataCell(
                          ElevatedButton(
                            onPressed: () {
                              checkTransaction(
                                trx['ref_id']
                                    .toString(),
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

        const SizedBox(height: 25),

        const Text(
          'API Error Log',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        ...apiLogs.map(
          (log) => Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.error,
                color: Colors.red,
              ),
              title:
                  Text(log['endpoint']),
              subtitle:
                  Text(log['error']),
              trailing:
                  Text(
                log['time'],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // USERS
  // =========================================================

  Widget usersPage() {
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        const Text(
          'Manajemen Pengguna',
          style: TextStyle(
            fontSize: 27,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        Card(
          child: SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,
            child: DataTable(
              columns: const [
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
                (entry) {
                  final index =
                      entry.key;

                  final user =
                      entry.value;

                  final blocked =
                      user['status'] ==
                          'Diblokir';

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          user['id'],
                        ),
                      ),
                      DataCell(
                        Text(
                          user['name'],
                        ),
                      ),
                      DataCell(
                        Text(
                          user['email'],
                        ),
                      ),
                      DataCell(
                        Text(
                          user['status'],
                        ),
                      ),
                      DataCell(
                        Text(
                          user['reason']
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
                                onPressed: () {
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
                                onPressed: () {
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

  void blockUser(int index) {
    final controller =
        TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title:
              const Text(
            'Blokir Pengguna',
          ),
          content:
              TextField(
            controller:
                controller,
            maxLines: 3,
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
              onPressed: () =>
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
              onPressed: () {
                if (controller
                    .text
                    .trim()
                    .isEmpty) {
                  message(
                    'Alasan wajib diisi.',
                  );
                  return;
                }

                setState(() {
                  users[index][
                          'status'] =
                      'Diblokir';

                  users[index][
                          'reason'] =
                      controller.text
                          .trim();
                });

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
          const EdgeInsets.all(16),
      children: [
        const Text(
          'CS / Keluhan',
          style: TextStyle(
            fontSize: 27,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        if (tickets.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'Belum ada tiket keluhan.',
                ),
              ),
            ),
          ),

        ...tickets.map(
          (ticket) {
            return Card(
              child: ListTile(
                leading:
                    const CircleAvatar(
                  child:
                      Icon(Icons.support_agent),
                ),
                title: Text(
                  '${ticket['id']} • ${ticket['user']}',
                ),
                subtitle:
                    Text(
                  ticket['message'],
                ),
                trailing:
                    DropdownButton<String>(
                  value:
                      ticket['status'],
                  items: const [
                    DropdownMenuItem(
                      value: 'Open',
                      child:
                          Text('Open'),
                    ),
                    DropdownMenuItem(
                      value: 'Diproses',
                      child:
                          Text('Diproses'),
                    ),
                    DropdownMenuItem(
                      value: 'Selesai',
                      child:
                          Text('Selesai'),
                    ),
                  ],
                  onChanged:
                      (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      ticket[
                              'status'] =
                          value;
                    });
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
          const EdgeInsets.all(16),
      children: [
        const Text(
          'API Error Log',
          style: TextStyle(
            fontSize: 27,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        if (apiLogs.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'Belum ada error API.',
                ),
              ),
            ),
          ),

        ...apiLogs.map(
          (log) => Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.error,
                color: Colors.red,
              ),
              title:
                  Text(log['endpoint']),
              subtitle:
                  Text(log['error']),
              trailing:
                  Text(log['time']),
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
  // NAV ITEM
  // =========================================================

  Widget navItem(
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
      onTap: () {
        setState(() {
          menu = index;
        });
      },
    );
  }

  // =========================================================
  // MENU ADMIN
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
        onTap: () {
          setState(() {
            menu = index;
          });

          if (closeDrawer) {
            Navigator.pop(context);
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
      width: 240,
      color:
          Colors.grey.shade100,
      child: Column(
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
                EdgeInsets.all(15),
            child: Text(
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
      child: SafeArea(
        child: Column(
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
              closeDrawer: true,
            ),

            const Spacer(),

            const Padding(
              padding:
                  EdgeInsets.all(15),
              child: Text(
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
  // BUILD RESPONSIVE
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        final isMobile =
            constraints.maxWidth < 700;

        // ===================================================
        // HP
        // ===================================================

        if (isMobile) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
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
                  Theme.of(context)
                      .colorScheme
                      .primary,
              foregroundColor:
                  Colors.white,
            ),

            drawer:
                mobileDrawer(),

            body:
                SafeArea(
              child: content(),
            ),
          );
        }

        // ===================================================
        // PC / LAPTOP
        // ===================================================

        return Scaffold(
          body: Row(
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
