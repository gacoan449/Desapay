import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  // =========================================================
  // SETTINGS
  // =========================================================

  static Future<bool> ambilMaintenance() async {
    final doc = await db.collection('settings').doc('app').get();
    return doc.data()?['maintenance'] == true;
  }

  static Future<void> setMaintenance(bool value) async {
    await db.collection('settings').doc('app').set({
      'maintenance': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // =========================================================
  // PRODUCTS
  // =========================================================

  static Future<void> simpanProduk(
    List<Map<String, dynamic>> produkList,
  ) async {
    const limit = 450;

    for (int start = 0; start < produkList.length; start += limit) {
      final batch = db.batch();

      final end = (start + limit > produkList.length)
          ? produkList.length
          : start + limit;

      for (final produk in produkList.sublist(start, end)) {
        final sku = produk['sku']?.toString() ?? '';
        if (sku.isEmpty || sku == '-') continue;

        batch.set(
          db.collection('products').doc(sku),
          {
            'sku': sku,
            'name': produk['name']?.toString() ?? '-',
            'category': produk['category']?.toString() ?? '-',
            'brand': produk['brand']?.toString() ?? '-',
            'cost': produk['cost'] ?? 0,
            'margin': produk['margin'] ?? 0,
            'active': produk['active'] == true,
            'isTest': produk['isTest'] == true,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    }
  }

  static Future<void> buatProdukTest() async {
    final data = [
      {
        'sku': 'TEST-PULSA-0',
        'name': 'Pulsa TEST Rp0',
        'category': 'PULSA',
        'brand': 'TEST',
        'cost': 0,
        'margin': 0,
        'active': true,
        'isTest': true,
      },
      {
        'sku': 'TEST-DATA-0',
        'name': 'Paket Data TEST Rp0',
        'category': 'DATA',
        'brand': 'TEST',
        'cost': 0,
        'margin': 0,
        'active': true,
        'isTest': true,
      },
      {
        'sku': 'TEST-PLN-0',
        'name': 'PLN TEST Rp0',
        'category': 'PLN',
        'brand': 'TEST',
        'cost': 0,
        'margin': 0,
        'active': true,
        'isTest': true,
      },
    ];

    await simpanProduk(data);
  }

  static Future<List<Map<String, dynamic>>>
      ambilSemuaProduk() async {
    final snap = await db.collection('products').get();

    final result = snap.docs.map((doc) {
      final d = Map<String, dynamic>.from(doc.data());
      d['sku'] ??= doc.id;
      d['margin'] ??= 0;
      d['cost'] ??= 0;
      d['active'] = d['active'] == true;
      d['isTest'] = d['isTest'] == true;
      return d;
    }).toList();

    result.sort((a, b) =>
        (a['category'] ?? '').toString().compareTo(
              (b['category'] ?? '').toString(),
            ));

    return result;
  }

  static Future<void> updateMargin(
    String sku,
    num margin,
  ) async {
    await db.collection('products').doc(sku).update({
      'margin': margin,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateProductActive(
    String sku,
    bool active,
  ) async {
    await db.collection('products').doc(sku).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // TRANSACTIONS
  // =========================================================

  static Future<void> simpanTransaksi(
    Map<String, dynamic> trx,
  ) async {
    final ref = trx['ref_id']?.toString() ?? '';
    if (ref.isEmpty) throw Exception('ref_id kosong');

    await db.collection('transactions').doc(ref).set({
      ...trx,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<List<Map<String, dynamic>>>
      ambilSemuaTransaksi() async {
    final snap = await db
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(300)
        .get();

    return snap.docs.map((d) {
      final x = Map<String, dynamic>.from(d.data());
      x['docId'] = d.id;
      return x;
    }).toList();
  }

  static Future<String> ujiCobaTransaksi({
    String sku = 'TEST-PULSA-0',
    String productName = 'Pulsa TEST Rp0',
    String customerNo = '080000000000',
  }) async {
    final ref = db.collection('transactions').doc();

    await ref.set({
      'transactionId': ref.id,
      'ref_id': ref.id,
      'isTest': true,
      'testMode': true,
      'sku': sku,
      'productName': productName,
      'category': 'PULSA',
      'brand': 'TEST',
      'customerNo': customerNo,
      'amount': 0,
      'cost': 0,
      'margin': 0,
      'status': 'SUCCESS',
      'digiflazzSent': false,
      'balanceBefore': 0,
      'balanceAfter': 0,
      'message': 'TRANSAKSI TEST Rp0',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  static Future<String> ujiCobaTransaksiGagal() async {
    final ref = db.collection('transactions').doc();

    await ref.set({
      'transactionId': ref.id,
      'ref_id': ref.id,
      'isTest': true,
      'testMode': true,
      'sku': 'TEST-FAILED',
      'productName': 'TEST GAGAL',
      'amount': 0,
      'cost': 0,
      'margin': 0,
      'status': 'FAILED',
      'digiflazzSent': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  // =========================================================
  // USERS
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilUsers() async {
    final snap = await db.collection('users').limit(500).get();

    return snap.docs.map((d) {
      final x = Map<String, dynamic>.from(d.data());
      x['id'] = d.id;
      x['balance'] ??= 0;
      x['kycStatus'] ??= 'BELUM';
      x['status'] ??= 'Aktif';
      return x;
    }).toList();
  }

  static Future<void> ubahSaldoUser(
    String uid,
    num amount,
    String alasan,
  ) async {
    final ref = db.collection('users').doc(uid);

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      if (!snap.exists) {
        throw Exception('User tidak ditemukan');
      }

      final data = snap.data() ?? {};
      final before = (data['balance'] ?? 0) as num;
      final after = before + amount;

      if (after < 0) {
        throw Exception('Saldo tidak boleh negatif');
      }

      tx.update(ref, {
        'balance': after,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(
        db.collection('balance_ledger').doc(),
        {
          'uid': uid,
          'type': amount >= 0 ? 'CREDIT' : 'DEBIT',
          'amount': amount.abs(),
          'before': before,
          'after': after,
          'reason': alasan,
          'source': 'ADMIN',
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  // =========================================================
  // SALDO LIMIT
  // =========================================================

  static Future<void> setLimitSaldo({
    required String uid,
    required num limitSaldo,
  }) async {
    await db.collection('users').doc(uid).update({
      'saldoLimit': limitSaldo,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setLimitSaldoBelumKyc(
    num limit,
  ) async {
    await db.collection('settings').doc('balance').set({
      'limitUnverifiedKyc': limit,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // =========================================================
  // KYC
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilKycPending() async {
    final snap = await db
        .collection('users')
        .where('kycStatus', isEqualTo: 'PENDING')
        .get();

    return snap.docs.map((d) {
      final x = Map<String, dynamic>.from(d.data());
      x['id'] = d.id;
      return x;
    }).toList();
  }

  static Future<void> prosesKyc(
    String uid,
    bool approve,
    String alasan,
  ) async {
    await db.collection('users').doc(uid).update({
      'kycStatus': approve ? 'APPROVED' : 'REJECTED',
      'kycReason': alasan,
      'kycReviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // DEVICE MANAGEMENT
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilDevices() async {
    final snap = await db.collection('devices').limit(500).get();

    return snap.docs.map((d) {
      final x = Map<String, dynamic>.from(d.data());
      x['id'] = d.id;
      return x;
    }).toList();
  }

  static Future<void> blokirDevice(
    String id,
    bool blocked,
  ) async {
    await db.collection('devices').doc(id).update({
      'blocked': blocked,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // MUTASI BANK
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilMutasiBank() async {
    final snap = await db
        .collection('bank_mutations')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    return snap.docs.map((d) {
      final x = Map<String, dynamic>.from(d.data());
      x['id'] = d.id;
      return x;
    }).toList();
  }

  static Future<void> tandaiMutasi(
    String id,
    String status,
  ) async {
    await db.collection('bank_mutations').doc(id).update({
      'status': status,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // PENGUMUMAN / PROMO
  // =========================================================

  static Future<void> tambahPengumuman({
    required String title,
    required String message,
    required bool active,
  }) async {
    await db.collection('announcements').add({
      'title': title,
      'message': message,
      'active': active,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>>
      ambilPengumuman() async {
    final snap = await db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    return snap.docs.map((d) {
      final x = Map<String, dynamic>.from(d.data());
      x['id'] = d.id;
      return x;
    }).toList();
  }

  static Future<void> togglePengumuman(
    String id,
    bool active,
  ) async {
    await db.collection('announcements').doc(id).update({
      'active': active,
    });
  }

  // =========================================================
  // KEUNTUNGAN NETTO
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      hitungProfitHariIni() async {
    final now = DateTime.now();

    final start = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day),
    );

    final end = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day + 1),
    );

    final snap = await db
        .collection('transactions')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThan: end)
        .where('status', isEqualTo: 'SUCCESS')
        .get();

    double total = 0;

    for (final d in snap.docs) {
      final data = d.data();

      final margin = data['margin'] is num
          ? (data['margin'] as num).toDouble()
          : 0;

      final biaya = data['fee'] is num
          ? (data['fee'] as num).toDouble()
          : 0;

      total += margin - biaya;
    }

    return [
      {
        'date': now,
        'profit': total,
        'transactionCount': snap.docs.length,
      }
    ];
  }

  // =========================================================
  // HAPUS TRANSAKSI TEST
  // =========================================================

  static Future<void> hapusSemuaTransaksiTest() async {
    final snap = await db
        .collection('transactions')
        .where('isTest', isEqualTo: true)
        .get();

    const limit = 450;

    for (int start = 0; start < snap.docs.length; start += limit) {
      final batch = db.batch();

      final end = start + limit > snap.docs.length
          ? snap.docs.length
          : start + limit;

      for (final doc in snap.docs.sublist(start, end)) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }
}
