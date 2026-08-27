import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore db =
      FirebaseFirestore.instance;

  // =========================================================
  // PRODUK
  // =========================================================

  /// Simpan / update produk dari hasil Sync Digiflazz.
  ///
  /// PENTING:
  /// - cost = harga modal dari Digiflazz
  /// - margin = setting ADMIN, bukan dari Digiflazz
  /// - margin lama TIDAK ditimpa saat sync
  /// - active lama TIDAK ditimpa saat sync
  static Future<void> simpanProduk(
    List<Map<String, dynamic>> produkList,
  ) async {
    if (produkList.isEmpty) return;

    // Firestore batch maksimal 500 operasi.
    // Kita pecah agar aman jika produk Digiflazz >500.
    const int batchLimit = 450;

    // Ambil semua SKU yang akan disinkronkan.
    final List<String> skuList = produkList
        .map(
          (produk) =>
              produk['sku']?.toString() ?? '',
        )
        .where(
          (sku) => sku.isNotEmpty,
        )
        .toList();

    // =======================================================
    // AMBIL DATA PRODUK LAMA
    // =======================================================

    final Map<String, Map<String, dynamic>> produkLama = {};

    // Firestore whereIn memiliki batas jumlah item.
    // Kita pecah menjadi kelompok kecil.
    const int whereInLimit = 30;

    for (int i = 0; i < skuList.length; i += whereInLimit) {
      final int end =
          (i + whereInLimit < skuList.length)
              ? i + whereInLimit
              : skuList.length;

      final List<String> kelompok =
          skuList.sublist(i, end);

      final snapshot = await db
          .collection('products')
          .where(
            'sku',
            whereIn: kelompok,
          )
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final sku =
            data['sku']?.toString() ?? doc.id;

        produkLama[sku] = data;
      }
    }

    // =======================================================
    // SIMPAN PRODUK
    // =======================================================

    for (
      int start = 0;
      start < produkList.length;
      start += batchLimit
    ) {
      final int end =
          (start + batchLimit < produkList.length)
              ? start + batchLimit
              : produkList.length;

      final batch = db.batch();

      final kelompokProduk =
          produkList.sublist(start, end);

      for (final produk in kelompokProduk) {
        final String sku =
            produk['sku']?.toString() ?? '';

        if (sku.isEmpty) continue;

        final docRef =
            db.collection('products').doc(sku);

        final oldData =
            produkLama[sku];

        // ===================================================
        // MARGIN
        // ===================================================
        //
        // Jika produk sudah ada:
        // gunakan margin lama dari Admin Dashboard.
        //
        // Jika produk baru:
        // margin = 0.
        //
        final num marginLama =
            oldData?['margin'] is num
                ? oldData!['margin'] as num
                : num.tryParse(
                      oldData?['margin']
                              ?.toString() ??
                          '',
                    ) ??
                    0;

        // ===================================================
        // ACTIVE
        // ===================================================
        //
        // Jika produk sudah ada:
        // pertahankan status aktif/nonaktif dari admin.
        //
        // Jika produk baru:
        // aktif otomatis.
        //
        final bool activeLama =
            oldData?['active'] is bool
                ? oldData!['active'] as bool
                : true;

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

            // HARGA MODAL ASLI DIGIFLAZZ
            'cost':
                produk['cost'] ?? 0,

            // MARGIN HANYA DARI ADMIN
            'margin':
                marginLama,

            // STATUS ADMIN
            'active':
                activeLama,

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    }

    print(
      '✅ ${produkList.length} produk berhasil disimpan.',
    );
  }

  // =========================================================
  // AMBIL SEMUA PRODUK
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilSemuaProduk() async {
    final snapshot = await db
        .collection('products')
        .where(
          'active',
          isEqualTo: true,
        )
        .orderBy('category')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        ...data,

        // Pastikan SKU selalu tersedia
        'sku':
            data['sku']?.toString() ??
                doc.id,
      };
    }).toList();
  }

  // =========================================================
  // AMBIL SEMUA PRODUK TERMASUK NONAKTIF
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilSemuaProdukAdmin() async {
    final snapshot = await db
        .collection('products')
        .orderBy('category')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        ...data,
        'sku':
            data['sku']?.toString() ??
                doc.id,
      };
    }).toList();
  }

  // =========================================================
  // UPDATE MARGIN DARI ADMIN DASHBOARD
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
  // UPDATE PRODUK ADMIN
  // =========================================================

  static Future<void> updateProduk({
    required String sku,
    String? name,
    String? category,
    String? brand,
    num? cost,
    num? margin,
    bool? active,
  }) async {
    if (sku.trim().isEmpty) {
      throw Exception(
        'SKU produk tidak boleh kosong.',
      );
    }

    final Map<String, dynamic> data = {
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (name != null) {
      data['name'] = name;
    }

    if (category != null) {
      data['category'] = category;
    }

    if (brand != null) {
      data['brand'] = brand;
    }

    if (cost != null) {
      data['cost'] = cost;
    }

    if (margin != null) {
      if (margin < 0) {
        throw Exception(
          'Margin tidak boleh negatif.',
        );
      }

      data['margin'] = margin;
    }

    if (active != null) {
      data['active'] = active;
    }

    await db
        .collection('products')
        .doc(sku)
        .update(data);

    print(
      '✅ Produk diperbarui: $sku',
    );
  }

  // =========================================================
  // HAPUS PRODUK
  // =========================================================

  static Future<void> hapusProduk(
    String sku,
  ) async {
    if (sku.trim().isEmpty) {
      throw Exception(
        'SKU produk tidak boleh kosong.',
      );
    }

    await db
        .collection('products')
        .doc(sku)
        .delete();

    print(
      '🗑️ Produk dihapus: $sku',
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
        'ref_id transaksi wajib diisi.',
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
  // AMBIL SEMUA TRANSAKSI
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      ambilSemuaTransaksi() async {
    final snapshot = await db
        .collection('transactions')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(100)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        ...data,
        'ref_id':
            data['ref_id']?.toString() ??
                doc.id,
      };
    }).toList();
  }

  // =========================================================
  // AMBIL TRANSAKSI BERDASARKAN REF ID
  // =========================================================

  static Future<Map<String, dynamic>?>
      ambilTransaksi(
    String refId,
  ) async {
    final doc = await db
        .collection('transactions')
        .doc(refId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return {
      ...doc.data()!,
      'ref_id': refId,
    };
  }

  // =========================================================
  // UPDATE STATUS TRANSAKSI
  // =========================================================

  static Future<void> updateStatusTransaksi(
    String refId,
    String status,
  ) async {
    if (refId.trim().isEmpty) {
      throw Exception(
        'ref_id tidak boleh kosong.',
      );
    }

    await db
        .collection('transactions')
        .doc(refId)
        .update({
      'status': status,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    print(
      '✅ Status transaksi $refId = $status',
    );
  }
}
