import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore db =
      FirebaseFirestore.instance;

  // =========================================================
  // PRODUK
  // =========================================================

  /// Simpan / update banyak produk sekaligus.
  ///
  /// PENTING:
  /// Margin yang dikirim dari Admin tetap disimpan.
  /// Tidak ada kalkulasi margin otomatis di sini.
  static Future<void> simpanProduk(
    List<Map<String, dynamic>> produkList,
  ) async {
    // Firestore batch maksimal 500 operasi.
    // Kita pecah menjadi beberapa batch agar aman.
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

            // Harga modal dari Digiflazz
            'cost': produk['cost'] ?? 0,

            // Margin ADMIN.
            // Tidak pernah dihitung otomatis.
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

  /// Ambil SEMUA produk, termasuk produk nonaktif.
  ///
  /// Ini penting untuk Admin Dashboard agar margin produk
  /// nonaktif tidak hilang ketika melakukan sync.
  static Future<List<Map<String, dynamic>>>
      ambilSemuaProduk() async {
    final snapshot =
        await db.collection('products').get();

    final products =
        snapshot.docs.map((doc) {
      final data =
          Map<String, dynamic>.from(doc.data());

      // Pastikan SKU selalu tersedia.
      data['sku'] ??= doc.id;

      // Pastikan field margin ada.
      data['margin'] ??= 0;

      // Pastikan active boolean.
      data['active'] =
          data['active'] == true;

      return data;
    }).toList();

    // Urutkan berdasarkan kategori lalu nama.
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

  /// Ambil produk aktif saja.
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

  /// Update margin produk.
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

  /// Update status aktif/nonaktif produk.
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
  // TRANSAKSI
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
}
