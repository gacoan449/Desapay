import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  // === PRODUK ===
  static Future<void> simpanProduk(List<Map<String, dynamic>> produkList) async {
    final batch = db.batch(); // Simpan banyak sekaligus!
    
    for (final produk in produkList) {
      final docRef = db.collection('products').doc(produk['sku']);
      batch.set(docRef, {
        'sku': produk['sku'],
        'name': produk['name'],
        'category': produk['category'],
        'brand': produk['brand'],
        'cost': produk['cost'],
        'margin': produk['margin'],
        'active': produk['active'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
    print('✅ ${produkList.length} produk tersimpan di Firestore!');
  }

  static Future<List<Map<String, dynamic>>> ambilSemuaProduk() async {
    final snapshot = await db
        .collection('products')
        .where('active', isEqualTo: true)
        .orderBy('category')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<void> updateMargin(String sku, num margin) async {
    await db.collection('products').doc(sku).update({
      'margin': margin,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('✅ Margin diperbarui: $sku = $margin');
  }

  // === TRANSAKSI ===
  static Future<void> simpanTransaksi(Map<String, dynamic> trx) async {
    await db.collection('transactions').doc(trx['ref_id']).set({
      ...trx,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> ambilSemuaTransaksi() async {
    final snapshot = await db
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
