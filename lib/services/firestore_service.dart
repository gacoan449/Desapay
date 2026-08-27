import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore db =
      FirebaseFirestore.instance;

  // =========================================================
  // MODE UJI COBA
  // =========================================================
  //
  // TRUE  = transaksi uji coba, nominal Rp 0,
  //         tidak dikirim ke Digiflazz.
  //
  // FALSE = mode normal.
  //
  static const bool modeUjiCoba = true;

  // =========================================================
  // PRODUK
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
          (start + batchLimit > produkList.length)
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
                produk['name']?.toString() ?? '-',
            'category':
                produk['category']?.toString() ?? '-',
            'brand':
                produk['brand']?.toString() ?? '-',

            'cost': produk['cost'] ?? 0,

            'margin': produk['margin'] ?? 0,

            'active':
                produk['active'] == true,

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

  static Future<List<Map<String, dynamic>>>
      ambilSemuaProduk() async {
    final snapshot =
        await db.collection('products').get();

    final products =
        snapshot.docs.map((doc) {
      final data =
          Map<String, dynamic>.from(doc.data());

      data['sku'] ??= doc.id;
      data['margin'] ??= 0;
      data['active'] =
          data['active'] == true;

      return data;
    }).toList();

    products.sort((a, b) {
      final categoryA =
          a['category']?.toString() ?? '';

      final categoryB =
          b['category']?.toString() ?? '';

      final categoryCompare =
          categoryA.compareTo(categoryB);

      if (categoryCompare != 0) {
        return categoryCompare;
      }

      final nameA =
          a['name']?.toString() ?? '';

      final nameB =
          b['name']?.toString() ?? '';

      return nameA.compareTo(nameB);
    });

    return products;
  }

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
      data['margin'] ??= 0;
      data['active'] =
          data['active'] == true;

      return data;
    }).toList();
  }

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
      '✅ Margin diperbarui: $sku = $margin',
    );
  }

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
  // Fungsi ini HANYA membuat transaksi palsu di Firestore.
  //
  // TIDAK:
  // - memotong saldo user
  // - mengurangi saldo admin
  // - menghubungi Digiflazz
  // - mengirim SKU ke Digiflazz
  //
  // Nominal selalu Rp 0.
  //
  static Future<String> ujiCobaTransaksi({
    String customerNo = '080000000000',
    String sku = 'TEST-000',
    String productName = 'Produk Uji Coba',
    String brand = 'TEST',
  }) async {
    if (!modeUjiCoba) {
      throw Exception(
        'Mode uji coba sedang dinonaktifkan.',
      );
    }

    final ref =
        db.collection('transactions').doc();

    final transactionId = ref.id;

    await ref.set({
      'transactionId': transactionId,
      'ref_id': transactionId,

      // Penanda sangat jelas bahwa ini TEST
      'isTest': true,
      'testMode': true,

      'type': 'PULSA',
      'category': 'PULSA',

      'sku': sku,
      'productName': productName,
      'brand': brand,

      'customerNo': customerNo,

      // SEMUA NOMINAL TEST = 0
      'amount': 0,
      'cost': 0,
      'margin': 0,

      // Langsung sukses karena hanya simulasi
      'status': 'SUCCESS',

      'paymentMethod': 'SALDO_UTAMA',

      // Tidak ada pemotongan saldo
      'balanceBefore': 0,
      'balanceAfter': 0,

      'message':
          'TRANSAKSI UJI COBA BERHASIL. TIDAK DIKIRIM KE DIGIFLAZZ.',

      'sn': 'TEST-SN-000',

      'digiflazzSent': false,

      'createdAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    print(
      '🧪 UJI COBA BERHASIL: $transactionId',
    );

    return transactionId;
  }

  // =========================================================
  // UJI COBA GAGAL
  // =========================================================
  //
  // Untuk mengetes tampilan/error transaksi gagal.
  //
  static Future<String> ujiCobaTransaksiGagal({
    String customerNo = '080000000000',
    String sku = 'TEST-FAILED',
  }) async {
    if (!modeUjiCoba) {
      throw Exception(
        'Mode uji coba sedang dinonaktifkan.',
      );
    }

    final ref =
        db.collection('transactions').doc();

    final transactionId = ref.id;

    await ref.set({
      'transactionId': transactionId,
      'ref_id': transactionId,

      'isTest': true,
      'testMode': true,

      'type': 'PULSA',
      'category': 'PULSA',

      'sku': sku,
      'productName': 'Produk Uji Gagal',
      'brand': 'TEST',

      'customerNo': customerNo,

      'amount': 0,
      'cost': 0,
      'margin': 0,

      'status': 'FAILED',

      'paymentMethod': 'SALDO_UTAMA',

      'balanceBefore': 0,
      'balanceAfter': 0,

      'message':
          'TRANSAKSI UJI COBA GAGAL. SALDO TIDAK DIPOTONG.',

      'sn': '',

      'digiflazzSent': false,

      'createdAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    print(
      '🧪 UJI COBA GAGAL: $transactionId',
    );

    return transactionId;
  }

  // =========================================================
  // AMBIL TRANSAKSI
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
      return Map<String, dynamic>.from(
        doc.data(),
      );
    }).toList();
  }

  // =========================================================
  // HAPUS TRANSAKSI TEST
  // =========================================================
  //
  // Hanya menghapus transaksi yang benar-benar
  // memiliki isTest == true.
  //
  static Future<void> hapusSemuaTransaksiTest() async {
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
          in snapshot.docs.sublist(start, end)) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }

    print(
      '🧹 ${snapshot.docs.length} transaksi test dihapus.',
    );
  }
}
