import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../services/firestore_service.dart';
import '../../services/digiflazz_service.dart';
import '../belanjaku/admin/admin_dashboard_screen.dart' as belanjaku_admin;
import 'courier_management_screen.dart';

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

  double saldoDigiflazz = 0.0;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> kyc = [];
  List<Map<String, dynamic>> devices = [];
  List<Map<String, dynamic>> mutations = [];
  List<Map<String, dynamic>> announcements = [];

  // =========================================================
  // CLOUD FUNCTIONS
  // =========================================================

  late final FirebaseFunctions functions =
      FirebaseFunctions.instanceFor(
    region: 'asia-southeast2',
  );

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  // =========================================================
  // LOAD DATA
  // =========================================================

  Future<void> loadAll() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

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

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> loadSettings() async {
    try {
      maintenance =
          await FirestoreService.ambilMaintenance();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadProducts() async {
    try {
      products =
          await FirestoreService.ambilSemuaProduk();

      // Produk TEST tidak ditampilkan di dashboard produksi.
      products = products
          .where((p) => p['isTest'] != true)
          .toList();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadTransactions() async {
    try {
      transactions =
          await FirestoreService.ambilSemuaTransaksi();

      // Transaksi TEST tidak ditampilkan di dashboard produksi.
      transactions = transactions
          .where((trx) => trx['isTest'] != true)
          .toList();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadUsers() async {
    try {
      users = await FirestoreService.ambilUsers();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadKyc() async {
    try {
      kyc =
          await FirestoreService.ambilKycPending();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadDevices() async {
    try {
      devices =
          await FirestoreService.ambilDevices();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadMutations() async {
    try {
      mutations =
          await FirestoreService.ambilMutasiBank();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadAnnouncements() async {
    try {
      announcements =
          await FirestoreService.ambilPengumuman();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadSaldo() async {
    try {
      final saldo =
          await DigiflazzService().cekSaldoModal();

      saldoDigiflazz =
          (saldo as num).toDouble();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  // =========================================================
  // FORMAT RUPIAH
  // =========================================================

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

    double profit = 0.0;

    for (final trx in transactions) {
      if (trx['status'] == 'SUCCESS') {
        final margin = trx['margin'] is num
            ? (trx['margin'] as num).toDouble()
            : 0.0;

        final fee = trx['fee'] is num
            ? (trx['fee'] as num).toDouble()
            : 0.0;

        profit += margin - fee;
      }
    }

    return RefreshIndicator(
      onRefresh: loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DesaPay Command Center',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
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
              try {
                await FirestoreService
                    .setMaintenance(value);

                if (!mounted) return;

                setState(() {
                  maintenance = value;
                });
              } catch (e) {
                _msg(
                  'Gagal mengubah maintenance: $e',
                );
              }
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
                'Pengguna',
                '${users.length}',
                Icons.people,
              ),
              _card(
                'KYC Pending',
                '${kyc.length}',
                Icons.verified_user,
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
              leading: const Icon(Icons.show_chart),
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
  // PRODUK PPOB
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
                  'Manajemen Produk PPOB',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: loadProducts,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Produk',
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: products.isEmpty
              ? const Center(
                  child: Text(
                    'Produk PPOB belum tersedia.',
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection:
                      Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(
                          label: Text('SKU'),
                        ),
                        DataColumn(
                          label: Text('Produk'),
                        ),
                        DataColumn(
                          label: Text('Kategori'),
                        ),
                        DataColumn(
                          label: Text('Modal'),
                        ),
                        DataColumn(
                          label: Text('Margin'),
                        ),
                        DataColumn(
                          label: Text('Harga Jual'),
                        ),
                        DataColumn(
                          label: Text('Aktif'),
                        ),
                      ],
                      rows: products.map((p) {
                        final cost = p['cost'] is num
                            ? p['cost'] as num
                            : 0;

                        final margin =
                            p['margin'] is num
                                ? p['margin'] as num
                                : 0;

                        final jual =
                            cost + margin;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '${p['sku'] ?? '-'}',
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  '${p['name'] ?? '-'}',
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${p['category'] ?? '-'}',
                              ),
                            ),
                            DataCell(
                              Text(rp(cost)),
                            ),
                            DataCell(
                              SizedBox(
                                width: 120,
                                child: TextFormField(
                                  initialValue:
                                      margin.toString(),
                                  keyboardType:
                                      const TextInputType
                                          .numberWithOptions(
                                    decimal: false,
                                  ),
                                  onFieldSubmitted:
                                      (value) async {
                                    final sku =
                                        p['sku']
                                                ?.toString() ??
                                            '';

                                    if (sku.isEmpty) {
                                      return;
                                    }

                                    final newMargin =
                                        num.tryParse(
                                              value,
                                            ) ??
                                            0;

                                    try {
                                      await FirestoreService
                                          .updateMargin(
                                        sku,
                                        newMargin,
                                      );

                                      await loadProducts();

                                      if (!mounted) {
                                        return;
                                      }

                                      _msg(
                                        'Margin produk berhasil diperbarui.',
                                      );
                                    } catch (e) {
                                      _msg(
                                        'Gagal update margin: $e',
                                      );
                                    }
                                  },
                                  decoration:
                                      const InputDecoration(
                                    prefixText: 'Rp ',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                rp(jual),
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Switch(
                                value:
                                    p['active'] == true,
                                onChanged:
                                    (value) async {
                                  final sku =
                                      p['sku']
                                              ?.toString() ??
                                          '';

                                  if (sku.isEmpty) {
                                    return;
                                  }

                                  try {
                                    await FirestoreService
                                        .updateProductActive(
                                      sku,
                                      value,
                                    );

                                    await loadProducts();
                                  } catch (e) {
                                    _msg(
                                      'Gagal mengubah status produk: $e',
                                    );
                                  }
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
          onPressed: _setLimitUnverified,
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
                'KYC: ${user['kycStatus'] ?? 'BELUM'}',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                    ),
                    tooltip: 'Tambah Saldo',
                    onPressed: () =>
                        _ubahSaldo(user, true),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.remove,
                    ),
                    tooltip: 'Kurangi Saldo',
                    onPressed: () =>
                        _ubahSaldo(user, false),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.tune,
                    ),
                    tooltip: 'Atur Limit',
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

  // =========================================================
  // ADMIN ADJUST BALANCE
  // =========================================================
  //
  // PENTING:
  // Fungsi ini TIDAK mengubah Firestore users secara langsung.
  //
  // Flutter -> Cloud Function:
  //
  // adminAdjustBalance
  //
  // Backend index.js yang melakukan:
  // - cek login
  // - cek role admin
  // - validasi UID
  // - validasi alasan
  // - validasi nominal
  // - transaksi atomik
  // - update saldo
  // - membuat balance_ledger
  //
  // Jadi index.js yang sudah kamu kirim TIDAK perlu diubah.
  //
  // =========================================================

  Future<void> _ubahSaldo(
    Map<String, dynamic> user,
    bool tambah,
  ) async {
    final uid =
        user['id']?.toString().trim() ?? '';

    if (uid.isEmpty) {
      _msg(
        'UID user tidak ditemukan.',
      );
      return;
    }

    final nominalController =
        TextEditingController();

    final alasanController =
        TextEditingController();

    bool submitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                tambah
                    ? 'Tambah Saldo'
                    : 'Kurangi Saldo',
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User: ${user['name'] ?? user['email'] ?? uid}',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'UID: $uid',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Saldo sekarang: ${rp(user['balance'] ?? 0)}',
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller:
                          nominalController,
                      enabled: !submitting,
                      keyboardType:
                          TextInputType.number,
                      autofocus: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Nominal',
                        hintText:
                            'Contoh: 10000',
                        prefixText:
                            'Rp ',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller:
                          alasanController,
                      enabled: !submitting,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Alasan perubahan',
                        hintText:
                            'Contoh: Koreksi saldo manual',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        10,
                      ),
                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                        color: tambah
                            ? Colors.green
                                .withValues(
                                alpha: 0.08,
                              )
                            : Colors.red
                                .withValues(
                                alpha: 0.08,
                              ),
                      ),
                      child: Text(
                        tambah
                            ? 'Saldo user akan BERTAMBAH.'
                            : 'Saldo user akan BERKURANG.',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color: tambah
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child:
                      const Text('Batal'),
                ),

                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final nominalText =
                              nominalController
                                  .text
                                  .trim();

                          final alasan =
                              alasanController
                                  .text
                                  .trim();

                          if (nominalText
                              .isEmpty) {
                            _msg(
                              'Nominal wajib diisi.',
                            );
                            return;
                          }

                          final nominal =
                              int.tryParse(
                            nominalText,
                          );

                          if (nominal == null ||
                              nominal <= 0) {
                            _msg(
                              'Nominal harus berupa angka lebih dari 0.',
                            );
                            return;
                          }

                          if (nominal >
                              100000000) {
                            _msg(
                              'Maksimal perubahan saldo adalah Rp 100.000.000.',
                            );
                            return;
                          }

                          if (alasan.isEmpty) {
                            _msg(
                              'Alasan perubahan saldo wajib diisi.',
                            );
                            return;
                          }

                          if (alasan.length >
                              500) {
                            _msg(
                              'Alasan terlalu panjang.',
                            );
                            return;
                          }

                          final amount =
                              tambah
                                  ? nominal
                                  : -nominal;

                          setDialogState(() {
                            submitting =
                                true;
                          });

                          try {
                            // =================================================
                            // PANGGIL CLOUD FUNCTION adminAdjustBalance
                            // =================================================

                            final callable =
                                functions
                                    .httpsCallable(
                              'adminAdjustBalance',
                            );

                            final result =
                                await callable.call(
                              {
                                'uid': uid,
                                'amount':
                                    amount,
                                'alasan':
                                    alasan,
                              },
                            );

                            final resultData =
                                result.data;

                            if (!mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                            );

                            await loadUsers();

                            if (!mounted) {
                              return;
                            }

                            int? before;
                            int? after;
                            String? ledgerId;

                            if (resultData
                                is Map) {
                              final rawBefore =
                                  resultData[
                                      'before'];

                              final rawAfter =
                                  resultData[
                                      'after'];

                              final rawLedger =
                                  resultData[
                                      'ledgerId'];

                              if (rawBefore
                                  is num) {
                                before =
                                    rawBefore
                                        .toInt();
                              }

                              if (rawAfter
                                  is num) {
                                after =
                                    rawAfter
                                        .toInt();
                              }

                              if (rawLedger !=
                                  null) {
                                ledgerId =
                                    rawLedger
                                        .toString();
                              }
                            }

                            final action =
                                tambah
                                    ? 'ditambahkan'
                                    : 'dikurangi';

                            String message =
                                'Saldo berhasil $action.';

                            if (before !=
                                    null &&
                                after !=
                                    null) {
                              message +=
                                  '\nSaldo: ${rp(before!)} → ${rp(after!)}';
                            }

                            if (ledgerId !=
                                null) {
                              message +=
                                  '\nLedger: $ledgerId';
                            }

                            _msg(message);
                          } on FirebaseFunctionsException catch (e) {
                            if (!mounted) {
                              return;
                            }

                            String message;

                            switch (e.code) {
                              case 'unauthenticated':
                                message =
                                    'Admin harus login.';
                                break;

                              case 'permission-denied':
                                message =
                                    'Akses ditolak. Akun bukan admin.';
                                break;

                              case 'invalid-argument':
                                message =
                                    e.message ??
                                        'Data perubahan saldo tidak valid.';
                                break;

                              case 'not-found':
                                message =
                                    e.message ??
                                        'User tidak ditemukan.';
                                break;

                              case 'failed-precondition':
                                message =
                                    e.message ??
                                        'Saldo user tidak memenuhi syarat.';
                                break;

                              case 'out-of-range':
                                message =
                                    e.message ??
                                        'Nominal saldo terlalu besar.';
                                break;

                              case 'internal':
                                message =
                                    e.message ??
                                        'Server gagal memproses perubahan saldo.';
                                break;

                              default:
                                message =
                                    e.message ??
                                        'Gagal mengubah saldo.';
                            }

                            setDialogState(() {
                              submitting =
                                  false;
                            });

                            _msg(
                              message,
                            );
                          } catch (e) {
                            if (!mounted) {
                              return;
                            }

                            setDialogState(() {
                              submitting =
                                  false;
                            });

                            _msg(
                              'Gagal mengubah saldo: $e',
                            );
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    nominalController.dispose();
    alasanController.dispose();
  }

  // =========================================================
  // LIMIT USER
  // =========================================================

  void _setLimitUser(
    Map<String, dynamic> user,
  ) {
    final c =
        TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Limit Saldo User',
        ),
        content: TextField(
          controller: c,
          keyboardType:
              TextInputType.number,
          decoration:
              const InputDecoration(
            labelText: 'Limit',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child:
                const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final limit =
                  num.tryParse(
                        c.text,
                      ) ??
                      0;

              if (limit < 0) {
                _msg(
                  'Limit tidak boleh negatif.',
                );
                return;
              }

              try {
                await FirestoreService
                    .setLimitSaldo(
                  uid: user['id'],
                  limitSaldo: limit,
                );

                if (!mounted) return;

                Navigator.pop(context);

                await loadUsers();

                _msg(
                  'Limit saldo berhasil disimpan.',
                );
              } catch (e) {
                if (!mounted) return;

                Navigator.pop(context);

                _msg(
                  'Gagal mengatur limit: $e',
                );
              }
            },
            child:
                const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _setLimitUnverified() {
    final c =
        TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Limit User Belum KYC',
        ),
        content: TextField(
          controller: c,
          keyboardType:
              TextInputType.number,
          decoration:
              const InputDecoration(
            labelText:
                'Limit Saldo',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child:
                const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final limit =
                  num.tryParse(
                        c.text,
                      ) ??
                      0;

              if (limit < 0) {
                _msg(
                  'Limit tidak boleh negatif.',
                );
                return;
              }

              try {
                await FirestoreService
                    .setLimitSaldoBelumKyc(
                  limit,
                );

                if (!mounted) return;

                Navigator.pop(context);

                _msg(
                  'Limit berhasil disimpan.',
                );
              } catch (e) {
                if (!mounted) return;

                Navigator.pop(context);

                _msg(
                  'Gagal menyimpan limit: $e',
                );
              }
            },
            child:
                const Text('Simpan'),
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
      padding:
          const EdgeInsets.all(16),
      children: [
        const Text(
          'Verifikasi KYC',
          style: TextStyle(
            fontSize: 27,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        if (kyc.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(25),
              child: Text(
                'Tidak ada KYC menunggu persetujuan.',
              ),
            ),
          ),

        ...kyc.map(
          (user) => Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    '${user['name'] ?? '-'}',
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  Text(
                    'UID: ${user['id']}',
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  if (user['ktpUrl'] !=
                          null &&
                      user['ktpUrl']
                          .toString()
                          .isNotEmpty)
                    Image.network(
                      user['ktpUrl']
                          .toString(),
                      height: 180,
                      errorBuilder:
                          (
                        _,
                        __,
                        ___,
                      ) =>
                              const Text(
                        'Foto KTP gagal dimuat',
                      ),
                    ),

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    children: [
                      ElevatedButton(
                        onPressed:
                            () async {
                          try {
                            await FirestoreService
                                .prosesKyc(
                              user['id'],
                              true,
                              'Disetujui Admin',
                            );

                            await loadKyc();

                            if (!mounted) {
                              return;
                            }

                            _msg(
                              'KYC berhasil disetujui.',
                            );
                          } catch (e) {
                            _msg(
                              'Gagal memproses KYC: $e',
                            );
                          }
                        },
                        child:
                            const Text(
                          'SETUJUI',
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      OutlinedButton(
                        onPressed:
                            () async {
                          try {
                            await FirestoreService
                                .prosesKyc(
                              user['id'],
                              false,
                              'Ditolak Admin',
                            );

                            await loadKyc();

                            if (!mounted) {
                              return;
                            }

                            _msg(
                              'KYC berhasil ditolak.',
                            );
                          } catch (e) {
                            _msg(
                              'Gagal memproses KYC: $e',
                            );
                          }
                        },
                        child:
                            const Text(
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
      padding:
          const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Device Management',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            IconButton(
              onPressed:
                  loadDevices,
              icon:
                  const Icon(Icons.refresh),
            ),
          ],
        ),

        const SizedBox(height: 15),

        ...devices.map(
          (device) => Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.phone_android,
              ),
              title: Text(
                '${device['deviceName'] ?? 'Device'}',
              ),
              subtitle: Text(
                'UID: ${device['uid'] ?? '-'}\n'
                'ID: ${device['id']}',
              ),
              trailing:
                  Switch(
                value:
                    device['blocked'] !=
                        true,
                onChanged:
                    (value) async {
                  try {
                    await FirestoreService
                        .blokirDevice(
                      device['id'],
                      !value,
                    );

                    await loadDevices();
                  } catch (e) {
                    _msg(
                      'Gagal mengubah status device: $e',
                    );
                  }
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
      padding:
          const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Mutasi Bank',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            IconButton(
              onPressed:
                  loadMutations,
              icon:
                  const Icon(Icons.refresh),
            ),
          ],
        ),

        const Text(
          'Data mutasi masuk dari sistem bank/webhook.',
        ),

        const SizedBox(height: 15),

        if (mutations.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(20),
              child: Text(
                'Belum ada mutasi bank.',
              ),
            ),
          ),

        ...mutations.map(
          (m) => Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.account_balance,
              ),
              title: Text(
                '${m['description'] ?? '-'}',
              ),
              subtitle: Text(
                'Nominal: ${rp(m['amount'] ?? 0)}\n'
                'Status: ${m['status'] ?? 'PENDING'}',
              ),
              trailing:
                  m['status'] ==
                          'PENDING'
                      ? ElevatedButton(
                          onPressed:
                              () async {
                            try {
                              await FirestoreService
                                  .tandaiMutasi(
                                m['id'],
                                'PROCESSED',
                              );

                              await loadMutations();

                              if (!mounted) {
                                return;
                              }

                              _msg(
                                'Mutasi berhasil diproses.',
                              );
                            } catch (e) {
                              _msg(
                                'Gagal memproses mutasi: $e',
                              );
                            }
                          },
                          child:
                              const Text(
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
      padding:
          const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pengumuman & Promosi',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed:
                  addAnnouncement,
              icon:
                  const Icon(Icons.add),
              label:
                  const Text('Tambah'),
            ),
          ],
        ),

        const SizedBox(height: 15),

        if (announcements.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(20),
              child: Text(
                'Belum ada pengumuman.',
              ),
            ),
          ),

        ...announcements.map(
          (a) => Card(
            child:
                SwitchListTile(
              title: Text(
                '${a['title'] ?? '-'}',
              ),
              subtitle: Text(
                '${a['message'] ?? '-'}',
              ),
              value:
                  a['active'] == true,
              onChanged:
                  (v) async {
                try {
                  await FirestoreService
                      .togglePengumuman(
                    a['id'],
                    v,
                  );

                  await loadAnnouncements();
                } catch (e) {
                  _msg(
                    'Gagal mengubah pengumuman: $e',
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void addAnnouncement() {
    final title =
        TextEditingController();

    final message =
        TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            const Text(
          'Pengumuman Baru',
        ),
        content:
            SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Judul',
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              TextField(
                controller: message,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Isi',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child:
                const Text('Batal'),
          ),

          ElevatedButton(
            onPressed: () async {
              if (title.text
                      .trim()
                      .isEmpty ||
                  message.text
                      .trim()
                      .isEmpty) {
                _msg(
                  'Judul dan isi wajib diisi.',
                );
                return;
              }

              try {
                await FirestoreService
                    .tambahPengumuman(
                  title:
                      title.text.trim(),
                  message:
                      message.text.trim(),
                  active: true,
                );

                if (!mounted) return;

                Navigator.pop(context);

                await loadAnnouncements();

                _msg(
                  'Pengumuman berhasil dipublikasikan.',
                );
              } catch (e) {
                if (!mounted) return;

                Navigator.pop(context);

                _msg(
                  'Gagal membuat pengumuman: $e',
                );
              }
            },
            child:
                const Text(
              'Publikasikan',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TRANSAKSI PPOB
  // =========================================================

  Widget transactionPage() {
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Monitor Transaksi PPOB',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            IconButton(
              onPressed:
                  loadTransactions,
              icon:
                  const Icon(Icons.refresh),
              tooltip:
                  'Refresh Transaksi',
            ),
          ],
        ),

        const SizedBox(height: 15),

        if (transactions.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(20),
              child: Text(
                'Belum ada transaksi PPOB.',
              ),
            ),
          ),

        ...transactions.map(
          (trx) {
            final status =
                '${trx['status'] ?? '-'}';

            final isSuccess =
                status == 'SUCCESS';

            final isPending =
                status == 'PENDING';

            return Card(
              child: ListTile(
                leading: Icon(
                  isSuccess
                      ? Icons.check_circle
                      : isPending
                          ? Icons.pending
                          : Icons.error,
                  color: isSuccess
                      ? Colors.green
                      : isPending
                          ? Colors.orange
                          : Colors.red,
                ),

                title: Text(
                  '${trx['productName'] ?? trx['product'] ?? '-'}',
                ),

                subtitle: Text(
                  'Ref: ${trx['ref_id'] ?? '-'}\n'
                  'Nominal: ${rp(trx['amount'] ?? 0)}\n'
                  'User: ${trx['uid'] ?? trx['userId'] ?? '-'}',
                ),

                trailing:
                    Text(
                  status,
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: isSuccess
                        ? Colors.green
                        : isPending
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // MENU
  // =========================================================

  Widget withdrawalsPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('withdrawal_requests').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Gagal memuat permintaan penarikan.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final av = a.data()['createdAt'];
            final bv = b.data()['createdAt'];
            final at = av is Timestamp ? av.millisecondsSinceEpoch : 0;
            final bt = bv is Timestamp ? bv.millisecondsSinceEpoch : 0;
            return bt.compareTo(at);
          });
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Permintaan Penarikan Saldo', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (docs.isEmpty) const Card(child: ListTile(title: Text('Belum ada permintaan penarikan.'))),
            ...docs.map((doc) {
              final data = doc.data();
              final status = (data['status'] ?? 'PENDING').toString();
              final amount = (data['amount'] as num?) ?? 0;
              final pending = status == 'PENDING';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(rp(amount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('User: ${data['uid'] ?? '-'}'),
                    Text('Tujuan: ${data['destinationType'] ?? '-'} • ${data['destinationName'] ?? '-'}'),
                    Text('Akun: ${data['destinationAccount'] ?? '-'}'),
                    Text('Pemilik: ${data['destinationAccountName'] ?? '-'}'),
                    Text('Status: $status${data['refunded'] == true ? ' • saldo dikembalikan' : ''}'),
                    if (pending) Wrap(spacing: 8, children: [
                      OutlinedButton.icon(
                        onPressed: () => _reviewWithdrawal(doc.id, 'REJECT'),
                        icon: const Icon(Icons.close),
                        label: const Text('Tolak & kembalikan saldo'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _reviewWithdrawal(doc.id, 'APPROVE'),
                        icon: const Icon(Icons.check),
                        label: const Text('Setujui'),
                      ),
                    ]),
                  ]),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _reviewWithdrawal(String requestId, String action) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(action == 'REJECT' ? 'Tolak penarikan?' : 'Setujui penarikan?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(action == 'REJECT'
              ? 'Saldo pengguna akan dikembalikan secara otomatis.'
              : 'Status menjadi disetujui. Pastikan transfer eksternal dilakukan terpisah.'),
          const SizedBox(height: 12),
          TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, reasonController.text.trim()), child: const Text('Lanjutkan')),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null) return;
    try {
      final result = await functions.httpsCallable('adminReviewWithdrawal').call({
        'request_id': requestId,
        'action': action,
        'reason': reason,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      _msg(action == 'REJECT'
          ? 'Penarikan ditolak. Saldo dikembalikan.'
          : 'Penarikan disetujui. Lakukan transfer secara terpisah.');
    } on FirebaseFunctionsException catch (e) {
      _msg(e.message ?? 'Gagal memproses penarikan.');
    } catch (_) {
      _msg('Gagal memproses penarikan.');
    }
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
        return kycPage();

      case 5:
        return devicesPage();

      case 6:
        return bankPage();

      case 7:
        return announcementPage();

      case 8:
        return withdrawalsPage();

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

        if (MediaQuery.of(context)
                .size
                .width <
            700) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget adminMenu() {
    return Material(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Center(
                child: Text(
                  'DESAPAY ADMIN',
                  style:
                      TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
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
              'Produk PPOB',
              1,
            ),

            menuItem(
              Icons.receipt_long,
              'Transaksi PPOB',
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

            menuItem(
              Icons.account_balance_wallet,
              'Penarikan Saldo',
              8,
            ),
          ],
        ),
      ),
    );
  }

  Widget drawer() {
    return Drawer(
      child:
          adminMenu(),
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _msg(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(text),
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
      builder: (
        _,
        constraints,
      ) {
        final mobile =
            constraints.maxWidth <
                700;

        if (mobile) {
          return Scaffold(
            appBar:
                AppBar(
              title: Text(
                [
                  'Dashboard',
                  'Produk PPOB',
                  'Transaksi PPOB',
                  'Pengguna & Saldo',
                  'KYC',
                  'Device Management',
                  'Mutasi Bank',
                  'Pengumuman / Promo',
                  'Penarikan Saldo',
                ][menu],
              ),
              actions: [
                IconButton(
                  tooltip: 'Kelola Kurir',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CourierManagementScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delivery_dining),
                ),
                IconButton(
                  tooltip: 'Admin Belanjaku',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const belanjaku_admin.BelanjakuAdminDashboardScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_basket_outlined),
                ),
                IconButton(
                  onPressed: loadAll,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            drawer:
                drawer(),
            body:
                content(),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 245,
                child:
                    adminMenu(),
              ),
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
