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

  bool maintenance = false;
  bool loading = false;

  double saldoDigiflazz = 0;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> kyc = [];
  List<Map<String, dynamic>> devices = [];
  List<Map<String, dynamic>> mutations = [];
  List<Map<String, dynamic>> announcements = [];

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadSettings(),
      loadProducts(),
      loadTransactions(),
      loadUsers(),
      loadKyc(),
      loadDevices(),
      loadMutations(),
      loadAnnouncements(),
      loadSaldo(),
    ]);
  }

  Future<void> loadSettings() async {
    maintenance =
        await FirestoreService.ambilMaintenance();

    if (mounted) setState(() {});
  }

  Future<void> loadProducts() async {
    products =
        await FirestoreService.ambilSemuaProduk();

    if (mounted) setState(() {});
  }

  Future<void> loadTransactions() async {
    try {
      transactions =
          await FirestoreService.ambilSemuaTransaksi();
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> loadUsers() async {
    users = await FirestoreService.ambilUsers();
    if (mounted) setState(() {});
  }

  Future<void> loadKyc() async {
    kyc = await FirestoreService.ambilKycPending();
    if (mounted) setState(() {});
  }

  Future<void> loadDevices() async {
    devices = await FirestoreService.ambilDevices();
    if (mounted) setState(() {});
  }

  Future<void> loadMutations() async {
    try {
      mutations =
          await FirestoreService.ambilMutasiBank();
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> loadAnnouncements() async {
    announcements =
        await FirestoreService.ambilPengumuman();

    if (mounted) setState(() {});
  }

  Future<void> loadSaldo() async {
    try {
      saldoDigiflazz =
          await DigiflazzService().cekSaldoModal();
    } catch (_) {}

    if (mounted) setState(() {});
  }

  String rp(num value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  // =========================================================
  // DASHBOARD
  // =========================================================

  Widget dashboard() {
    final sukses = transactions
        .where((x) => x['status'] == 'SUCCESS')
        .length;

    final gagal = transactions
        .where((x) => x['status'] == 'FAILED')
        .length;

    final test = transactions
        .where((x) => x['isTest'] == true)
        .length;

    double profit = 0;

    for (final trx in transactions) {
      if (trx['status'] == 'SUCCESS') {
        final margin = trx['margin'] is num
            ? (trx['margin'] as num).toDouble()
            : 0;

        final fee = trx['fee'] is num
            ? (trx['fee'] as num).toDouble()
            : 0;

        profit += margin - fee;
      }
    }

    return RefreshIndicator(
      onRefresh: loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'DesaPay Command Center',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          SwitchListTile(
            title: const Text(
              'Mode Pemeliharaan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              maintenance
                  ? 'APK user sedang maintenance'
                  : 'Sistem normal',
            ),
            value: maintenance,
            onChanged: (value) async {
              await FirestoreService
                  .setMaintenance(value);

              setState(() {
                maintenance = value;
              });
            },
          ),

          const SizedBox(height: 15),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _card(
                'Saldo Digiflazz',
                rp(saldoDigiflazz),
                Icons.account_balance_wallet,
              ),
              _card(
                'Produk',
                '${products.length}',
                Icons.inventory,
              ),
              _card(
                'Transaksi',
                '${transactions.length}',
                Icons.receipt_long,
              ),
              _card(
                'Berhasil',
                '$sukses',
                Icons.check_circle,
              ),
              _card(
                'Gagal',
                '$gagal',
                Icons.error,
              ),
              _card(
                'TEST Rp0',
                '$test',
                Icons.science,
              ),
              _card(
                'Pengguna',
                '${users.length}',
                Icons.people,
              ),
              _card(
                'Profit Netto',
                rp(profit),
                Icons.trending_up,
              ),
            ],
          ),

          const SizedBox(height: 25),

          _failedWarning(),

          const SizedBox(height: 20),

          const Text(
            'Keuntungan Netto Hari Ini',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.show_chart,
              ),
              title: Text(
                rp(profit),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Dihitung dari margin - biaya transaksi\n'
                'Update: ${DateTime.now()}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    String title,
    String value,
    IconData icon,
  ) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 35),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _failedWarning() {
    int count = 0;

    for (final trx in transactions.take(10)) {
      if (trx['status'] == 'FAILED') {
        count++;
      } else {
        break;
      }
    }

    if (count < 3) {
      return const SizedBox();
    }

    return Card(
      color: Colors.red.shade50,
      child: ListTile(
        leading: const Icon(
          Icons.warning,
          color: Colors.red,
        ),
        title: const Text(
          'PERINGATAN TRANSAKSI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$count transaksi gagal beruntun terdeteksi.',
        ),
      ),
    );
  }

  // =========================================================
  // PRODUK
  // =========================================================

  Widget productsPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Manajemen Produk',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: () async {
                  await FirestoreService
                      .buatProdukTest();

                  await loadProducts();

                  _msg(
                    'Produk TEST Rp0 berhasil dibuat.',
                  );
                },
                icon: const Icon(Icons.science),
                label: const Text(
                  'Tambah Produk TEST',
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: products.isEmpty
              ? const Center(
                  child: Text(
                    'Produk belum ada.',
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('SKU')),
                        DataColumn(label: Text('Produk')),
                        DataColumn(label: Text('Kategori')),
                        DataColumn(label: Text('Modal')),
                        DataColumn(label: Text('Margin')),
                        DataColumn(label: Text('Jual')),
                        DataColumn(label: Text('TEST')),
                        DataColumn(label: Text('Aktif')),
                      ],
                      rows: products.map((p) {
                        final cost =
                            (p['cost'] ?? 0) as num;
                        final margin =
                            (p['margin'] ?? 0) as num;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '${p['sku']}',
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 200,
                                child: Text(
                                  '${p['name']}',
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${p['category']}',
                              ),
                            ),
                            DataCell(
                              Text(rp(cost)),
                            ),
                            DataCell(
                              SizedBox(
                                width: 110,
                                child: TextFormField(
                                  initialValue:
                                      margin.toString(),
                                  keyboardType:
                                      TextInputType.number,
                                  onFieldSubmitted:
                                      (v) async {
                                    await FirestoreService
                                        .updateMargin(
                                      p['sku'],
                                      num.tryParse(v) ?? 0,
                                    );

                                    await loadProducts();
                                  },
                                  decoration:
                                      const InputDecoration(
                                    prefixText: 'Rp ',
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                rp(cost + margin),
                              ),
                            ),
                            DataCell(
                              p['isTest'] == true
                                  ? const Chip(
                                      label:
                                          Text('TEST'),
                                    )
                                  : const SizedBox(),
                            ),
                            DataCell(
                              Switch(
                                value:
                                    p['active'] == true,
                                onChanged:
                                    (value) async {
                                  await FirestoreService
                                      .updateProductActive(
                                    p['sku'],
                                    value,
                                  );

                                  await loadProducts();
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // =========================================================
  // USER + SALDO
  // =========================================================

  Widget usersPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Manajemen Pengguna & Saldo',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        ElevatedButton.icon(
          onPressed: () {
            _setLimitUnverified();
          },
          icon: const Icon(Icons.lock),
          label: const Text(
            'Atur Limit Saldo User Belum KYC',
          ),
        ),

        const SizedBox(height: 15),

        ...users.map(
          (user) => Card(
            child: ListTile(
              title: Text(
                '${user['name'] ?? user['email'] ?? user['id']}',
              ),
              subtitle: Text(
                'Saldo: ${rp(user['balance'] ?? 0)}\n'
                'KYC: ${user['kycStatus']}',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () =>
                        _ubahSaldo(user, true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () =>
                        _ubahSaldo(user, false),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () =>
                        _setLimitUser(user),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _ubahSaldo(
    Map<String, dynamic> user,
    bool tambah,
  ) {
    final c = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          tambah
              ? 'Tambah Saldo'
              : 'Kurangi Saldo',
        ),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nominal',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final nominal =
                  num.tryParse(c.text) ?? 0;

              if (nominal <= 0) return;

              await FirestoreService.ubahSaldoUser(
                user['id'],
                tambah ? nominal : -nominal,
                'Perubahan saldo manual Admin',
              );

              Navigator.pop(context);
              await loadUsers();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _setLimitUser(
    Map<String, dynamic> user,
  ) {
    final c = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limit Saldo User'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Limit',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FirestoreService.setLimitSaldo(
                uid: user['id'],
                limitSaldo:
                    num.tryParse(c.text) ?? 0,
              );

              Navigator.pop(context);
              await loadUsers();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _setLimitUnverified() {
    final c = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Limit User Belum KYC',
        ),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FirestoreService
                  .setLimitSaldoBelumKyc(
                num.tryParse(c.text) ?? 0,
              );

              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // KYC
  // =========================================================

  Widget kycPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Verifikasi KYC',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        if (kyc.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Text(
                'Tidak ada KYC menunggu persetujuan.',
              ),
            ),
          ),

        ...kyc.map(
          (user) => Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user['name'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    'UID: ${user['id']}',
                  ),

                  const SizedBox(height: 10),

                  if (user['ktpUrl'] != null)
                    Image.network(
                      user['ktpUrl'],
                      height: 180,
                      errorBuilder:
                          (_, __, ___) =>
                              const Text(
                        'Foto KTP gagal dimuat',
                      ),
                    ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await FirestoreService.prosesKyc(
                            user['id'],
                            true,
                            'Disetujui Admin',
                          );

                          await loadKyc();
                        },
                        child: const Text(
                          'SETUJUI',
                        ),
                      ),

                      const SizedBox(width: 10),

                      OutlinedButton(
                        onPressed: () async {
                          await FirestoreService.prosesKyc(
                            user['id'],
                            false,
                            'Ditolak Admin',
                          );

                          await loadKyc();
                        },
                        child: const Text(
                          'TOLAK',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // DEVICE
  // =========================================================

  Widget devicesPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Device Management',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        ...devices.map(
          (device) => Card(
            child: ListTile(
              leading:
                  const Icon(Icons.phone_android),
              title: Text(
                '${device['deviceName'] ?? 'Device'}',
              ),
              subtitle: Text(
                'UID: ${device['uid'] ?? '-'}\n'
                'ID: ${device['id']}',
              ),
              trailing: Switch(
                value:
                    device['blocked'] != true,
                onChanged: (value) async {
                  await FirestoreService
                      .blokirDevice(
                    device['id'],
                    !value,
                  );

                  await loadDevices();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BANK
  // =========================================================

  Widget bankPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Mutasi Bank',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: loadMutations,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),

        const Text(
          'Data mutasi masuk dari sistem bank/webhook.',
        ),

        const SizedBox(height: 15),

        ...mutations.map(
          (m) => Card(
            child: ListTile(
              leading:
                  const Icon(Icons.account_balance),
              title: Text(
                '${m['description'] ?? '-'}',
              ),
              subtitle: Text(
                'Nominal: ${rp(m['amount'] ?? 0)}\n'
                'Status: ${m['status'] ?? 'PENDING'}',
              ),
              trailing: m['status'] == 'PENDING'
                  ? ElevatedButton(
                      onPressed: () async {
                        await FirestoreService
                            .tandaiMutasi(
                          m['id'],
                          'PROCESSED',
                        );
                        await loadMutations();
                      },
                      child: const Text(
                        'Proses',
                      ),
                    )
                  : const Icon(
                      Icons.check_circle,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PENGUMUMAN
  // =========================================================

  Widget announcementPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pengumuman & Promosi',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: addAnnouncement,
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
          ],
        ),

        const SizedBox(height: 15),

        ...announcements.map(
          (a) => Card(
            child: SwitchListTile(
              title: Text(
                '${a['title']}',
              ),
              subtitle: Text(
                '${a['message']}',
              ),
              value: a['active'] == true,
              onChanged: (v) async {
                await FirestoreService
                    .togglePengumuman(
                  a['id'],
                  v,
                );

                await loadAnnouncements();
              },
            ),
          ),
        ),
      ],
    );
  }

  void addAnnouncement() {
    final title = TextEditingController();
    final message = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Pengumuman Baru',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Judul',
              ),
            ),
            TextField(
              controller: message,
              decoration: const InputDecoration(
                labelText: 'Isi',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FirestoreService
                  .tambahPengumuman(
                title: title.text,
                message: message.text,
                active: true,
              );

              Navigator.pop(context);
              await loadAnnouncements();
            },
            child: const Text('Publikasikan'),
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
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Monitor Transaksi',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await FirestoreService
                    .ujiCobaTransaksi();

                await loadTransactions();

                _msg(
                  'Transaksi TEST Rp0 masuk.',
                );
              },
              icon: const Icon(Icons.science),
              label: const Text('TEST Rp0'),
            ),
          ],
        ),

        const SizedBox(height: 15),

        ...transactions.map(
          (trx) => Card(
            child: ListTile(
              leading: Icon(
                trx['status'] == 'SUCCESS'
                    ? Icons.check_circle
                    : Icons.error,
              ),
              title: Text(
                '${trx['productName'] ?? trx['product'] ?? '-'}',
              ),
              subtitle: Text(
                'Ref: ${trx['ref_id'] ?? '-'}\n'
                'Nominal: ${rp(trx['amount'] ?? 0)}',
              ),
              trailing: Text(
                '${trx['status'] ?? '-'}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MENU
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
        return kycPage();
      case 5:
        return devicesPage();
      case 6:
        return bankPage();
      case 7:
        return announcementPage();
      default:
        return dashboard();
    }
  }

  Widget menuItem(
    IconData icon,
    String title,
    int index,
  ) {
    return ListTile(
      selected: menu == index,
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        setState(() => menu = index);
        if (MediaQuery.of(context).size.width < 700) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget drawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Center(
                child: Text(
                  'DESAPAY ADMIN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            menuItem(
              Icons.dashboard,
              'Dashboard',
              0,
            ),
            menuItem(
              Icons.inventory,
              'Produk',
              1,
            ),
            menuItem(
              Icons.receipt_long,
              'Transaksi',
              2,
            ),
            menuItem(
              Icons.people,
              'Pengguna & Saldo',
              3,
            ),
            menuItem(
              Icons.verified_user,
              'KYC',
              4,
            ),
            menuItem(
              Icons.devices,
              'Device Management',
              5,
            ),
            menuItem(
              Icons.account_balance,
              'Mutasi Bank',
              6,
            ),
            menuItem(
              Icons.campaign,
              'Pengumuman / Promo',
              7,
            ),
          ],
        ),
      ),
    );
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final mobile = constraints.maxWidth < 700;

        if (mobile) {
          return Scaffold(
            appBar: AppBar(
              title: Text([
                'Dashboard',
                'Produk',
                'Transaksi',
                'Pengguna & Saldo',
                'KYC',
                'Device Management',
                'Mutasi Bank',
                'Pengumuman / Promo',
              ][menu]),
            ),
            drawer: drawer(),
            body: content(),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 245,
                child: Material(
                  child: drawer().child!,
                ),
              ),
              Expanded(
                child: SafeArea(
                  child: content(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
