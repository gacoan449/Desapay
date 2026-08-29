import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirestoreService {
  static final FirebaseFirestore db =
      FirebaseFirestore.instance;

  static final FirebaseFunctions functions =
      FirebaseFunctions.instanceFor(
    region: 'asia-southeast2',
  );

  // =========================================================
  // SETTINGS
  // =========================================================

  static Future<bool> ambilMaintenance() async {
    final doc =
        await db.collection('settings').doc('app').get();

    return doc.data()?['maintenance'] == true;
  }

  static Future<void> setMaintenance(bool value) async {
    await db.collection('settings').doc('app').set(
      {
        'maintenance': value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // PRODUCTS
  // =========================================================

  static Future<void> simpanProduk(
    List<Map<String, dynamic>> produkList,
  ) async {
    const limit = 450;

    for (
      int start = 0;
      start < produkList.length;
      start += limit
    ) {
      final batch = db.batch();

      final end =
          (start + limit > produkList.length)
              ? produkList.length
              : start + limit;

      for (final produk
          in produkList.sublist(start, end)) {
        final sku =
            produk['sku']?.toString() ?? '';

        if (sku.isEmpty || sku == '-') {
          continue;
        }

        final data = <String, dynamic>{
          'sku': sku,
          'name':
              produk['name']?.toString() ?? '-',
          'category':
              produk['category']?.toString() ?? '-',
          'brand':
              produk['brand']?.toString() ?? '-',
          'cost': produk['cost'] ?? 0,
          'updatedAt':
              FieldValue.serverTimestamp(),
        };

        if (produk.containsKey('margin')) {
          data['margin'] =
              produk['margin'] ?? 0;
        }

        if (produk.containsKey('active')) {
          data['active'] =
              produk['active'] == true;
        }

        if (produk.containsKey('isTest')) {
          data['isTest'] =
              produk['isTest'] == true;
        }

        batch.set(
          db.collection('products').doc(sku),
          data,
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    }
  }

  static Future<List<Map<String, dynamic>>>
      ambilSemuaProduk() async {
    final snap =
        await db.collection('products').get();

    final result = snap.docs.map((doc) {
      final d =
          Map<String, dynamic>.from(
        doc.data(),
      );

      d['sku'] ??= doc.id;
      d['name'] ??= '-';
      d['category'] ??= '-';
      d['brand'] ??= '-';
      d['cost'] ??= 0;
      d['margin'] ??= 0;
      d['active'] = d['active'] == true;
      d['isTest'] = d['isTest'] == true;

      return d;
    }).toList();

    result.sort(
      (a, b) => (a['category'] ?? '')
          .toString()
          .compareTo(
            (b['category'] ?? '')
                .toString(),
          ),
    );

    return result;
  }

  static Future<List<Map<String, dynamic>>>
      ambilProdukAktif() async {
    final snap = await db
        .collection('products')
        .where(
          'active',
          isEqualTo: true,
        )
        .get();

    final result = snap.docs.map((doc) {
      final d =
          Map<String, dynamic>.from(
        doc.data(),
      );

      d['sku'] ??= doc.id;
      d['name'] ??= '-';
      d['category'] ??= '-';
      d['brand'] ??= '-';
      d['cost'] ??= 0;
      d['margin'] ??= 0;
      d['active'] = true;
      d['isTest'] =
          d['isTest'] == true;

      return d;
    })
        .where(
          (produk) =>
              produk['isTest'] == false,
        )
        .toList();

    result.sort((a, b) {
      final categoryCompare =
          (a['category'] ?? '')
              .toString()
              .compareTo(
                (b['category'] ?? '')
                    .toString(),
              );

      if (categoryCompare != 0) {
        return categoryCompare;
      }

      return (a['name'] ?? '')
          .toString()
          .compareTo(
            (b['name'] ?? '')
                .toString(),
          );
    });

    return result;
  }

  static Future<void> updateMargin(
    String sku,
    num margin,
  ) async {
    await db
        .collection('products')
        .doc(sku)
        .update({
      'margin': margin,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateProductActive(
    String sku,
    bool active,
  ) async {
    await db
        .collection('products')
        .doc(sku)
        .update({
      'active': active,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // TRANSACTIONS
  // =========================================================

  static Future<void> simpanTransaksi(
    Map<String, dynamic> trx,
  ) async {
    final ref =
        trx['ref_id']?.toString() ?? '';

    if (ref.isEmpty) {
      throw Exception('ref_id kosong');
    }

    await db
        .collection('transactions')
        .doc(ref)
        .set(
      {
        ...trx,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<List<Map<String, dynamic>>>
      ambilSemuaTransaksi() async {
    final snap = await db
        .collection('transactions')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(300)
        .get();

    return snap.docs.map((d) {
      final x =
          Map<String, dynamic>.from(
        d.data(),
      );

      x['docId'] = d.id;

      return x;
    }).toList();
  }

  // =========================================================
  // USERS
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilUsers() async {
    final snap =
        await db.collection('users')
            .limit(500)
            .get();

    return snap.docs.map((d) {
      final x =
          Map<String, dynamic>.from(
        d.data(),
      );

      x['id'] = d.id;
      x['balance'] ??= 0;
      x['kycStatus'] ??= 'BELUM';
      x['status'] ??= 'Aktif';

      return x;
    }).toList();
  }

  // =========================================================
  // UBAH SALDO USER
  // =========================================================
  //
  // PENTING:
  //
  // Flutter TIDAK BOLEH lagi melakukan:
  //
  // users/{uid}.balance = ...
  //
  // Semua perubahan saldo dilakukan Cloud Function.
  //
  // =========================================================

  static Future<void> ubahSaldoUser(
    String uid,
    num amount,
    String alasan,
  ) async {
    final cleanUid = uid.trim();
    final cleanReason = alasan.trim();
    final nominal = amount.toInt();

    if (cleanUid.isEmpty) {
      throw Exception(
        'UID user tidak valid.',
      );
    }

    if (cleanReason.isEmpty) {
      throw Exception(
        'Alasan perubahan saldo wajib diisi.',
      );
    }

    if (nominal == 0) {
      throw Exception(
        'Nominal perubahan saldo tidak boleh 0.',
      );
    }

    try {
      final callable =
          functions.httpsCallable(
        'adminAdjustBalance',
      );

      await callable.call({
        'uid': cleanUid,
        'amount': nominal,
        'reason': cleanReason,
      });
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'unauthenticated':
          throw Exception(
            'Sesi login tidak valid. Silakan login kembali.',
          );

        case 'permission-denied':
          throw Exception(
            'Anda tidak memiliki hak akses admin.',
          );

        case 'not-found':
          throw Exception(
            'User tidak ditemukan.',
          );

        case 'invalid-argument':
          throw Exception(
            e.message ??
                'Data perubahan saldo tidak valid.',
          );

        case 'failed-precondition':
          throw Exception(
            e.message ??
                'Saldo tidak dapat diproses.',
          );

        default:
          throw Exception(
            e.message ??
                'Gagal memperbarui saldo.',
          );
      }
    }
  }

  // =========================================================
  // SALDO LIMIT
  // =========================================================

  static Future<void> setLimitSaldo({
    required String uid,
    required num limitSaldo,
  }) async {
    if (uid.trim().isEmpty) {
      throw Exception(
        'UID tidak valid.',
      );
    }

    if (limitSaldo < 0) {
      throw Exception(
        'Limit saldo tidak boleh negatif.',
      );
    }

    await db.collection('users').doc(uid).update({
      'saldoLimit': limitSaldo,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setLimitSaldoBelumKyc(
    num limit,
  ) async {
    if (limit < 0) {
      throw Exception(
        'Limit tidak boleh negatif.',
      );
    }

    await db
        .collection('settings')
        .doc('balance')
        .set(
      {
        'limitUnverifiedKyc': limit,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // KYC
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilKycPending() async {
    final snap = await db
        .collection('users')
        .where(
          'kycStatus',
          isEqualTo: 'PENDING',
        )
        .get();

    return snap.docs.map((d) {
      final x =
          Map<String, dynamic>.from(
        d.data(),
      );

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
      'kycStatus':
          approve ? 'APPROVED' : 'REJECTED',
      'kycReason': alasan,
      'kycReviewedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // DEVICE MANAGEMENT
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilDevices() async {
    final snap =
        await db.collection('devices')
            .limit(500)
            .get();

    return snap.docs.map((d) {
      final x =
          Map<String, dynamic>.from(
        d.data(),
      );

      x['id'] = d.id;

      return x;
    }).toList();
  }

  static Future<void> blokirDevice(
    String id,
    bool blocked,
  ) async {
    await db
        .collection('devices')
        .doc(id)
        .update({
      'blocked': blocked,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // MUTASI BANK
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilMutasiBank() async {
    final snap = await db
        .collection('bank_mutations')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(100)
        .get();

    return snap.docs.map((d) {
      final x =
          Map<String, dynamic>.from(
        d.data(),
      );

      x['id'] = d.id;

      return x;
    }).toList();
  }

  static Future<void> tandaiMutasi(
    String id,
    String status,
  ) async {
    await db
        .collection('bank_mutations')
        .doc(id)
        .update({
      'status': status,
      'processedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // PENGUMUMAN
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
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>>
      ambilPengumuman() async {
    final snap = await db
        .collection('announcements')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(100)
        .get();

    return snap.docs.map((d) {
      final x =
          Map<String, dynamic>.from(
        d.data(),
      );

      x['id'] = d.id;

      return x;
    }).toList();
  }

  static Future<void> togglePengumuman(
    String id,
    bool active,
  ) async {
    await db
        .collection('announcements')
        .doc(id)
        .update({
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
      DateTime(
        now.year,
        now.month,
        now.day,
      ),
    );

    final end = Timestamp.fromDate(
      DateTime(
        now.year,
        now.month,
        now.day + 1,
      ),
    );

    final snap = await db
        .collection('transactions')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: start,
        )
        .where(
          'createdAt',
          isLessThan: end,
        )
        .where(
          'status',
          isEqualTo: 'SUCCESS',
        )
        .get();

    double total = 0;

    for (final d in snap.docs) {
      final data = d.data();

      final margin =
          data['margin'] is num
              ? (data['margin'] as num)
                  .toDouble()
              : 0.0;

      final biaya =
          data['fee'] is num
              ? (data['fee'] as num)
                  .toDouble()
              : 0.0;

      total += margin - biaya;
    }

    return [
      {
        'date': now,
        'profit': total,
        'transactionCount':
            snap.docs.length,
      }
    ];
  }

  // =========================================================
  // DATA TEST
  // =========================================================

  static Future<void>
      hapusSemuaProdukTest() async {
    final snap = await db
        .collection('products')
        .where(
          'isTest',
          isEqualTo: true,
        )
        .get();

    const limit = 450;

    for (
      int start = 0;
      start < snap.docs.length;
      start += limit
    ) {
      final batch = db.batch();

      final end =
          start + limit > snap.docs.length
              ? snap.docs.length
              : start + limit;

      for (
        final doc
            in snap.docs.sublist(
              start,
              end,
            )
      ) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }

  static Future<void>
      hapusSemuaTransaksiTest() async {
    final snap = await db
        .collection('transactions')
        .where(
          'isTest',
          isEqualTo: true,
        )
        .get();

    const limit = 450;

    for (
      int start = 0;
      start < snap.docs.length;
      start += limit
    ) {
      final batch = db.batch();

      final end =
          start + limit > snap.docs.length
              ? snap.docs.length
              : start + limit;

      for (
        final doc
            in snap.docs.sublist(
              start,
              end,
            )
      ) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }
}
