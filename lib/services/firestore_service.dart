import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore db =
      FirebaseFirestore.instance;

  // =========================================================
  // KONFIGURASI FIRESTORE
  // =========================================================
  //
  // Collection:
  //
  // settings
  //   └── app_config
  //
  // Field:
  //   testMode
  //   autoTestTransaction
  //
  // =========================================================

  static DocumentReference<Map<String, dynamic>>
      get _configRef =>
          db.collection('settings').doc('app_config');

  // =========================================================
  // INISIALISASI MODE TEST
  // =========================================================
  //
  // Jalankan sekali dari Admin Dashboard.
  //
  // Setelah itu Admin dapat mengubah ON/OFF langsung
  // melalui Firestore.
  //
  static Future<void> buatKonfigurasiAwal() async {
    await _configRef.set(
      {
        'testMode': true,
        'autoTestTransaction': true,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    print(
      '✅ Konfigurasi mode test berhasil dibuat.',
    );
  }

  // =========================================================
  // AMBIL KONFIGURASI MODE TEST
  // =========================================================

  static Future<Map<String, dynamic>>
      ambilKonfigurasi() async {
    final snapshot =
        await _configRef.get();

    if (!snapshot.exists) {
      await buatKonfigurasiAwal();

      return {
        'testMode': true,
        'autoTestTransaction': true,
      };
    }

    final data =
        Map<String, dynamic>.from(
      snapshot.data() ?? {},
    );

    return {
      'testMode':
          data['testMode'] == true,
      'autoTestTransaction':
          data['autoTestTransaction'] == true,
    };
  }

  // =========================================================
  // CEK MODE TEST
  // =========================================================

  static Future<bool> isTestModeAktif() async {
    final config =
        await ambilKonfigurasi();

    return config['testMode'] == true;
  }

  // =========================================================
  // CEK AUTO TRANSAKSI TEST
  // =========================================================

  static Future<bool>
      isAutoTestTransactionAktif() async {
    final config =
        await ambilKonfigurasi();

    return config['autoTestTransaction'] == true;
  }

  // =========================================================
  // AKTIF / NONAKTIF MODE TEST
  // =========================================================

  static Future<void> updateTestMode(
    bool aktif,
  ) async {
    await _configRef.set(
      {
        'testMode': aktif,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    print(
      '🧪 Test Mode = $aktif',
    );
  }

  // =========================================================
  // AKTIF / NONAKTIF AUTO TRANSAKSI TEST
  // =========================================================

  static Future<void>
      updateAutoTestTransaction(
    bool aktif,
  ) async {
    await _configRef.set(
      {
        'autoTestTransaction': aktif,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    print(
      '🤖 Auto Test Transaction = $aktif',
    );
  }

  // =========================================================
  // PRODUK NORMAL + PRODUK TEST
  // =========================================================

  static Future<void> simpanProduk(
    List<Map<String, dynamic>> produkList,
  ) async {
    const int batchLimit = 450;

    for (int start = 0;
        start < produkList.length;
        start += batchLimit) {
      final batch = db.batch();

      final int end =
          (start + batchLimit >
                  produkList.length)
              ? produkList.length
              : start + batchLimit;

      final chunk =
          produkList.sublist(start, end);

      for (final produk in chunk) {
        final sku =
            produk['sku']?.toString() ?? '';

        if (sku.isEmpty || sku == '-') {
          continue;
        }

        final docRef =
            db.collection('products').doc(sku);

        batch.set(
          docRef,
          {
            'sku': sku,

            'name':
                produk['name']?.toString() ??
                    '-',

            'category':
                produk['category']?.toString() ??
                    '-',

            'brand':
                produk['brand']?.toString() ??
                    '-',

            'cost':
                produk['cost'] ?? 0,

            'margin':
                produk['margin'] ?? 0,

            'price':
                produk['price'] ?? 0,

            'active':
                produk['active'] == true,

            // Produk Digiflazz normal
            'isTest':
                produk['isTest'] == true,

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    }

    print(
      '✅ ${produkList.length} produk tersimpan di Firestore',
    );
  }

  // =========================================================
  // BUAT PRODUK TEST
  // =========================================================
  //
  // Produk ini muncul di menu produk Admin.
  //
  // Harga = Rp0
  // Modal = Rp0
  //
  // Bisa diaktif/nonaktifkan.
  //
  static Future<void>
      buatProdukTest() async {
    final docRef =
        db.collection('products').doc(
              'TEST-000',
            );

    await docRef.set(
      {
        'sku': 'TEST-000',

        'name':
            'Produk Uji Coba',

        'category':
            'PULSA',

        'brand':
            'TEST',

        // TEST selalu Rp0
        'cost': 0,
        'margin': 0,
        'price': 0,

        // Default aktif
        'active': true,

        // Penanda produk TEST
        'isTest': true,

        'description':
            'Produk khusus untuk pengujian aplikasi DesaPay.',

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    print(
      '🧪 Produk TEST-000 berhasil dibuat.',
    );
  }

  // =========================================================
  // BUAT BEBERAPA PRODUK TEST
  // =========================================================
  //
  // Berguna supaya menu produk Admin langsung memiliki
  // beberapa produk untuk pengujian.
  //
  static Future<void>
      buatSemuaProdukTest() async {
    final produkTest = [
      {
        'sku': 'TEST-000',
        'name': 'Produk Uji Coba',
        'category': 'PULSA',
        'brand': 'TEST',
      },
      {
        'sku': 'TEST-001',
        'name': 'Test Pulsa 1',
        'category': 'PULSA',
        'brand': 'TEST',
      },
      {
        'sku': 'TEST-002',
        'name': 'Test Pulsa 2',
        'category': 'PULSA',
        'brand': 'TEST',
      },
      {
        'sku': 'TEST-PLN',
        'name': 'Test Token PLN',
        'category': 'PLN',
        'brand': 'TEST',
      },
      {
        'sku': 'TEST-DATA',
        'name': 'Test Paket Data',
        'category': 'DATA',
        'brand': 'TEST',
      },
    ];

    const int batchLimit = 450;

    for (int start = 0;
        start < produkTest.length;
        start += batchLimit) {
      final batch = db.batch();

      final int end =
          (start + batchLimit >
                  produkTest.length)
              ? produkTest.length
              : start + batchLimit;

      final chunk =
          produkTest.sublist(start, end);

      for (final produk in chunk) {
        final sku =
            produk['sku']!.toString();

        final ref =
            db.collection('products').doc(sku);

        batch.set(
          ref,
          {
            'sku': sku,
            'name': produk['name'],
            'category':
                produk['category'],
            'brand': produk['brand'],

            // Semua TEST Rp0
            'cost': 0,
            'margin': 0,
            'price': 0,

            'active': true,

            'isTest': true,

            'description':
                'Produk TEST DesaPay',

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    }

    print(
      '🧪 ${produkTest.length} produk TEST berhasil dibuat.',
    );
  }

  // =========================================================
  // AMBIL SEMUA PRODUK
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilSemuaProduk() async {
    final snapshot =
        await db
            .collection('products')
            .get();

    final products =
        snapshot.docs.map((doc) {
      final data =
          Map<String, dynamic>.from(
        doc.data(),
      );

      data['sku'] ??= doc.id;

      data['name'] ??= '-';
      data['category'] ??= '-';
      data['brand'] ??= '-';

      data['cost'] ??= 0;
      data['margin'] ??= 0;
      data['price'] ??= 0;

      data['active'] =
          data['active'] == true;

      data['isTest'] =
          data['isTest'] == true;

      return data;
    }).toList();

    // TEST ditaruh paling atas
    products.sort((a, b) {
      final testA =
          a['isTest'] == true;
      final testB =
          b['isTest'] == true;

      if (testA && !testB) {
        return -1;
      }

      if (!testA && testB) {
        return 1;
      }

      final categoryA =
          a['category']
                  ?.toString() ??
              '';

      final categoryB =
          b['category']
                  ?.toString() ??
              '';

      final categoryCompare =
          categoryA.compareTo(
        categoryB,
      );

      if (categoryCompare != 0) {
        return categoryCompare;
      }

      final nameA =
          a['name']?.toString() ??
              '';

      final nameB =
          b['name']?.toString() ??
              '';

      return nameA.compareTo(
        nameB,
      );
    });

    return products;
  }

  // =========================================================
  // AMBIL PRODUK TEST SAJA
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilProdukTest() async {
    final snapshot =
        await db
            .collection('products')
            .where(
              'isTest',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs.map((doc) {
      final data =
          Map<String, dynamic>.from(
        doc.data(),
      );

      data['sku'] ??= doc.id;
      data['name'] ??= '-';
      data['category'] ??= '-';
      data['brand'] ??= '-';
      data['cost'] ??= 0;
      data['margin'] ??= 0;
      data['price'] ??= 0;
      data['active'] =
          data['active'] == true;
      data['isTest'] = true;

      return data;
    }).toList();
  }

  // =========================================================
  // AMBIL PRODUK AKTIF
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilProdukAktif() async {
    final snapshot =
        await db
            .collection('products')
            .where(
              'active',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs.map((doc) {
      final data =
          Map<String, dynamic>.from(
        doc.data(),
      );

      data['sku'] ??= doc.id;
      data['name'] ??= '-';
      data['category'] ??= '-';
      data['brand'] ??= '-';
      data['cost'] ??= 0;
      data['margin'] ??= 0;
      data['price'] ??= 0;

      data['active'] = true;

      data['isTest'] =
          data['isTest'] == true;

      return data;
    }).toList();
  }

  // =========================================================
  // UPDATE MARGIN
  // =========================================================

  static Future<void> updateMargin(
    String sku,
    num margin,
  ) async {
    if (sku.trim().isEmpty) {
      throw Exception(
        'SKU produk tidak boleh kosong.',
      );
    }

    if (margin < 0) {
      throw Exception(
        'Margin tidak boleh negatif.',
      );
    }

    await db
        .collection('products')
        .doc(sku)
        .update({
      'margin': margin,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    print(
      '✅ Margin diperbarui: '
      '$sku = $margin',
    );
  }

  // =========================================================
  // UPDATE STATUS PRODUK
  // =========================================================
  //
  // Bisa dipakai untuk produk normal maupun TEST.
  //
  static Future<void> updateProductActive(
    String sku,
    bool active,
  ) async {
    if (sku.trim().isEmpty) {
      throw Exception(
        'SKU produk tidak boleh kosong.',
      );
    }

    await db
        .collection('products')
        .doc(sku)
        .update({
      'active': active,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    print(
      '✅ Status produk diperbarui: '
      '$sku = $active',
    );
  }

  // =========================================================
  // UPDATE PRODUK TEST
  // =========================================================
  //
  // Khusus memastikan dokumen tersebut memang TEST.
  //
  static Future<void>
      updateProdukTestActive(
    String sku,
    bool active,
  ) async {
    if (sku.trim().isEmpty) {
      throw Exception(
        'SKU produk tidak boleh kosong.',
      );
    }

    final ref =
        db.collection('products').doc(sku);

    final snapshot =
        await ref.get();

    if (!snapshot.exists) {
      throw Exception(
        'Produk TEST tidak ditemukan.',
      );
    }

    final data =
        snapshot.data() ?? {};

    if (data['isTest'] != true) {
      throw Exception(
        'Produk ini bukan produk TEST.',
      );
    }

    await ref.update({
      'active': active,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    print(
      '🧪 Status produk TEST $sku = $active',
    );
  }

  // =========================================================
  // HAPUS SEMUA PRODUK TEST
  // =========================================================

  static Future<void>
      hapusSemuaProdukTest() async {
    final snapshot =
        await db
            .collection('products')
            .where(
              'isTest',
              isEqualTo: true,
            )
            .get();

    if (snapshot.docs.isEmpty) {
      print(
        '🧪 Tidak ada produk TEST.',
      );
      return;
    }

    const batchLimit = 450;

    for (int start = 0;
        start < snapshot.docs.length;
        start += batchLimit) {
      final batch = db.batch();

      final int end =
          (start + batchLimit >
                  snapshot.docs.length)
              ? snapshot.docs.length
              : start + batchLimit;

      for (final doc
          in snapshot.docs.sublist(
        start,
        end,
      )) {
        batch.delete(
          doc.reference,
        );
      }

      await batch.commit();
    }

    print(
      '🧹 ${snapshot.docs.length} produk TEST dihapus.',
    );
  }

  // =========================================================
  // TRANSAKSI NORMAL
  // =========================================================

  static Future<void> simpanTransaksi(
    Map<String, dynamic> trx,
  ) async {
    final refId =
        trx['ref_id']?.toString() ?? '';

    if (refId.isEmpty) {
      throw Exception(
        'ref_id transaksi tidak boleh kosong.',
      );
    }

    await db
        .collection('transactions')
        .doc(refId)
        .set(
      {
        ...trx,
        'createdAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // UJI COBA TRANSAKSI
  // =========================================================
  //
  // TEST:
  // - tidak memotong saldo
  // - tidak mengurangi saldo admin
  // - tidak menghubungi Digiflazz
  // - amount = 0
  //
  // Status langsung SUCCESS.
  //
  static Future<String>
      ujiCobaTransaksi({
    String customerNo =
        '080000000000',

    String sku =
        'TEST-000',

    String productName =
        'Produk Uji Coba',

    String brand =
        'TEST',
  }) async {
    final config =
        await ambilKonfigurasi();

    if (config['testMode'] != true) {
      throw Exception(
        'Mode uji coba sedang dinonaktifkan dari Admin.',
      );
    }

    if (config['autoTestTransaction'] !=
        true) {
      throw Exception(
        'Auto transaksi uji coba sedang dinonaktifkan.',
      );
    }

    final ref =
        db.collection('transactions').doc();

    final transactionId =
        ref.id;

    await ref.set({
      'transactionId':
          transactionId,

      'ref_id':
          transactionId,

      // Penanda TEST
      'isTest': true,
      'testMode': true,

      'type': 'PULSA',
      'category': 'PULSA',

      'sku': sku,

      'productName':
          productName,

      'brand': brand,

      'customerNo':
          customerNo,

      // TEST selalu Rp0
      'amount': 0,
      'cost': 0,
      'margin': 0,
      'price': 0,

      'status': 'SUCCESS',

      'paymentMethod':
          'SALDO_UTAMA',

      // Tidak ada pemotongan saldo
      'balanceBefore': 0,
      'balanceAfter': 0,

      'message':
          'TRANSAKSI UJI COBA BERHASIL. TIDAK DIKIRIM KE DIGIFLAZZ.',

      'sn':
          'TEST-SN-000',

      'digiflazzSent':
          false,

      'createdAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    print(
      '🧪 UJI COBA BERHASIL: '
      '$transactionId',
    );

    return transactionId;
  }

  // =========================================================
  // UJI COBA GAGAL
  // =========================================================

  static Future<String>
      ujiCobaTransaksiGagal({
    String customerNo =
        '080000000000',

    String sku =
        'TEST-FAILED',
  }) async {
    final config =
        await ambilKonfigurasi();

    if (config['testMode'] != true) {
      throw Exception(
        'Mode uji coba sedang dinonaktifkan dari Admin.',
      );
    }

    if (config['autoTestTransaction'] !=
        true) {
      throw Exception(
        'Auto transaksi uji coba sedang dinonaktifkan.',
      );
    }

    final ref =
        db.collection('transactions').doc();

    final transactionId =
        ref.id;

    await ref.set({
      'transactionId':
          transactionId,

      'ref_id':
          transactionId,

      'isTest': true,
      'testMode': true,

      'type': 'PULSA',
      'category': 'PULSA',

      'sku': sku,

      'productName':
          'Produk Uji Gagal',

      'brand': 'TEST',

      'customerNo':
          customerNo,

      'amount': 0,
      'cost': 0,
      'margin': 0,
      'price': 0,

      'status': 'FAILED',

      'paymentMethod':
          'SALDO_UTAMA',

      'balanceBefore': 0,
      'balanceAfter': 0,

      'message':
          'TRANSAKSI UJI COBA GAGAL. SALDO TIDAK DIPOTONG.',

      'sn': '',

      'digiflazzSent':
          false,

      'createdAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    print(
      '🧪 UJI COBA GAGAL: '
      '$transactionId',
    );

    return transactionId;
  }

  // =========================================================
  // AMBIL SEMUA TRANSAKSI
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilSemuaTransaksi() async {
    final snapshot =
        await db
            .collection('transactions')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .limit(100)
            .get();

    return snapshot.docs.map((doc) {
      final data =
          Map<String, dynamic>.from(
        doc.data(),
      );

      data['isTest'] =
          data['isTest'] == true;

      return data;
    }).toList();
  }

  // =========================================================
  // AMBIL TRANSAKSI TEST SAJA
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilTransaksiTest() async {
    final snapshot =
        await db
            .collection('transactions')
            .where(
              'isTest',
              isEqualTo: true,
            )
            .get();

    final result =
        snapshot.docs.map((doc) {
      return Map<String, dynamic>.from(
        doc.data(),
      );
    }).toList();

    result.sort((a, b) {
      final aTime =
          a['createdAt'];

      final bTime =
          b['createdAt'];

      if (aTime is Timestamp &&
          bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }

      return 0;
    });

    return result;
  }

  // =========================================================
  // HAPUS SEMUA TRANSAKSI TEST
  // =========================================================

  static Future<void>
      hapusSemuaTransaksiTest() async {
    final snapshot =
        await db
            .collection('transactions')
            .where(
              'isTest',
              isEqualTo: true,
            )
            .get();

    if (snapshot.docs.isEmpty) {
      print(
        '🧪 Tidak ada transaksi test.',
      );
      return;
    }

    const batchLimit = 450;

    for (int start = 0;
        start < snapshot.docs.length;
        start += batchLimit) {
      final batch = db.batch();

      final int end =
          (start + batchLimit >
                  snapshot.docs.length)
              ? snapshot.docs.length
              : start + batchLimit;

      for (final doc
          in snapshot.docs.sublist(
        start,
        end,
      )) {
        batch.delete(
          doc.reference,
        );
      }

      await batch.commit();
    }

    print(
      '🧹 ${snapshot.docs.length} transaksi test dihapus.',
    );
  }
}
