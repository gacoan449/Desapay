import 'package:flutter/material.dart';

import 'digiflazz_service.dart';

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

  int menu = 0;

  double saldo = 0;

  bool loadingSaldo = false;
  bool syncing = false;

  DateTime? lastSync;

  String search = '';

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
  }

  Future<void> loadSaldo() async {
    setState(() {
      loadingSaldo = true;
    });

    try {
      final result =
          await DigiflazzService.saldo();

      final data = result['data'];

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

    setState(() {
      loadingSaldo = false;
    });
  }

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

    setState(() {
      syncing = true;
    });

    try {

      final result =
          await DigiflazzService.priceList();

      final data = result['data'];

      if (data is List) {

        products.clear();

        for (final item in data) {

          final price =
              double.tryParse(
                    item['price']
                            ?.toString() ??
                        '0',
                  ) ??
                  0;

          products.add({
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

        lastSync =
            DateTime.now();

        message(
          '${products.length} produk berhasil disinkronkan.',
        );

        setState(() {});
      }

    } catch (e) {

      addLog(
        '/price-list',
        e.toString(),
      );

      message(
        'Sync gagal: $e',
      );
    }

    setState(() {
      syncing = false;
    });
  }

  Future<void> checkTransaction(
    String refId,
  ) async {

    try {

      final result =
          await DigiflazzService.transaction(
        refId: refId,
      );

      message(
        'Status: ${result['data']?['status'] ?? 'Tidak diketahui'}',
      );

    } catch (e) {

      addLog(
        '/transaction',
        e.toString(),
      );

      message(
        'Gagal cek transaksi.',
      );
    }
  }

  void addLog(
    String endpoint,
    String error,
  ) {

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

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  String rupiah(num value) {

    final text =
        value.toStringAsFixed(0);

    final result =
        text.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) =>
          '${match[1]}.',
    );

    return 'Rp $result';
  }

  Widget stat(
    String title,
    String value,
    IconData icon,
  ) {

    return Expanded(
      child: Card(
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Row(
            children: [

              CircleAvatar(
                child: Icon(icon),
              ),

              const SizedBox(width: 15),

              Column(
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
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dashboard() {

    return ListView(
      padding:
          const EdgeInsets.all(20),
      children: [

        const Text(
          'Dashboard DesaPay',
          style: TextStyle(
            fontSize: 28,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [

            stat(
              'Saldo Digiflazz',
              rupiah(saldo),
              Icons.account_balance_wallet,
            ),

            const SizedBox(width: 15),

            stat(
              'Produk',
              products.length.toString(),
              Icons.inventory,
            ),

            const SizedBox(width: 15),

            stat(
              'Transaksi',
              transactions.length.toString(),
              Icons.receipt_long,
            ),

            const SizedBox(width: 15),

            stat(
              'Pengguna',
              users.length.toString(),
              Icons.people,
            ),
          ],
        ),

        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
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

                const SizedBox(height: 10),

                Text(
                  lastSync == null
                      ? 'Belum pernah sync'
                      : 'Terakhir sync: $lastSync',
                ),

                const SizedBox(height: 15),

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
                        : 'Manual Sync',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget productsPage() {

    return Padding(
      padding:
          const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              const Text(
                'Produk',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const Spacer(),

              ElevatedButton.icon(
                onPressed:
                    syncing
                        ? null
                        : syncProducts,
                icon:
                    const Icon(Icons.sync),
                label:
                    const Text('Sync'),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Expanded(
            child: Card(
              child:
                  SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal,
                child: DataTable(
                  columns: const [

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
                          product['cost']
                              as num;

                      final margin =
                          product['margin']
                              as num;

                      return DataRow(
                        cells: [

                          DataCell(
                            Text(
                              product['sku'],
                            ),
                          ),

                          DataCell(
                            Text(
                              product['name'],
                            ),
                          ),

                          DataCell(
                            Text(
                              product[
                                  'category'],
                            ),
                          ),

                          DataCell(
                            Text(
                              rupiah(cost),
                            ),
                          ),

                          DataCell(
                            SizedBox(
                              width: 100,
                              child:
                                  TextField(
                                controller:
                                    TextEditingController(
                                  text:
                                      margin.toStringAsFixed(0),
                                ),
                                keyboardType:
                                    TextInputType.number,
                                onSubmitted:
                                    (value) {

                                  setState(() {

                                    product[
                                            'margin'] =
                                        double.tryParse(
                                              value,
                                            ) ??
                                            0;

                                  });
                                },
                                decoration:
                                    const InputDecoration(
                                  prefixText:
                                      'Rp ',
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
                                  product[
                                      'active'],
                              onChanged:
                                  (value) {

                                setState(() {

                                  product[
                                          'active'] =
                                      value;

                                });

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
        ],
      ),
    );
  }

  Widget transactionPage() {

    return ListView(
      padding:
          const EdgeInsets.all(20),
      children: [

        const Text(
          'Monitor Transaksi',
          style: TextStyle(
            fontSize: 28,
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
                          trx['ref_id'],
                        ),
                      ),

                      DataCell(
                        Text(
                          trx['user'],
                        ),
                      ),

                      DataCell(
                        Text(
                          trx['product'],
                        ),
                      ),

                      DataCell(
                        Text(
                          rupiah(
                            trx['amount'],
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          trx['status'],
                        ),
                      ),

                      DataCell(
                        ElevatedButton(
                          onPressed: () {

                            checkTransaction(
                              trx['ref_id'],
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
                  Text(log['time']),
            ),
          ),
        ),
      ],
    );
  }

  Widget usersPage() {

    return ListView(
      padding:
          const EdgeInsets.all(20),
      children: [

        const Text(
          'Manajemen Pengguna',
          style: TextStyle(
            fontSize: 28,
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

                                  setState(() {

                                    user[
                                            'status'] =
                                        'Aktif';

                                    user[
                                            'reason'] =
                                        '';

                                  });

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

  Widget ticketsPage() {

    return ListView(
      padding:
          const EdgeInsets.all(20),
      children: [

        const Text(
          'CS / Keluhan',
          style: TextStyle(
            fontSize: 28,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

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

  Widget logsPage() {

    return ListView(
      padding:
          const EdgeInsets.all(20),
      children: [

        const Text(
          'API Error Log',
          style: TextStyle(
            fontSize: 28,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

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

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      body: Row(
        children: [

          Container(
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

                navItem(
                  Icons.dashboard,
                  'Dashboard',
                  0,
                ),

                navItem(
                  Icons.inventory,
                  'Produk',
                  1,
                ),

                navItem(
                  Icons.receipt_long,
                  'Transaksi',
                  2,
                ),

                navItem(
                  Icons.people,
                  'Pengguna',
                  3,
                ),

                navItem(
                  Icons.support_agent,
                  'CS / Keluhan',
                  4,
                ),

                navItem(
                  Icons.error_outline,
                  'API Logs',
                  5,
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

          Expanded(
            child:
                content(),
          ),
        ],
      ),
    );
  }
}
