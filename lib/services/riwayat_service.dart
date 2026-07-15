import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RiwayatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===================================================
  // 1. FUNGSI SIMPAN RIWAYAT TRANSAKSI (AUTO-METADATA)
  // ===================================================
  /// Menyimpan data transaksi pengguna ke Firestore dengan metadata otomatis.
  Future<bool> simpan(Map<String, dynamic> trx) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (kDebugMode) print("RiwayatService Error: Sesi pengguna tidak ditemukan.");
        return false;
      }

      // Membuat salinan data transaksi untuk disisipi metadata tambahan
      final Map<String, dynamic> dataTransaksiLog = Map<String, dynamic>.from(trx);

      // Otomatisasi pengisian parameter metadata demi keamanan & konsistensi data
      dataTransaksiLog["uid"] = currentUser.uid;
      dataTransaksiLog["waktu"] = FieldValue.serverTimestamp(); // Menggunakan server-side timestamp
      
      // Jika field status belum ditentukan, default ke PENDING
      dataTransaksiLog["status"] = (dataTransaksiLog["status"] ?? "PENDING").toString().toUpperCase();

      // Menyimpan data ke koleksi 'transaksi' (Sinkron dengan Admin Dashboard & Riwayat)
      await _firestore.collection("transaksi").add(dataTransaksiLog);
      
      return true;
    } catch (e) {
      if (kDebugMode) print("RiwayatService Exception: Gagal menyimpan mutasi transaksi -> $e");
      return false;
    }
  }

  // ===================================================
  // 2. STREAM UNTUK BACA RIWAYAT USER SECARA REAL-TIME
  // ===================================================
  /// Mengambil aliran data transaksi real-time khusus milik pengguna yang sedang aktif login.
  Stream<QuerySnapshot<Map<String, dynamic>>> dapatkanRiwayatUser() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Mengembalikan Stream kosong yang aman jika belum terautentikasi
      return const Stream.empty();
    }

    return _firestore
        .collection("transaksi")
        .where("uid", isEqualTo: currentUser.uid)
        .orderBy("waktu", descending: true)
        .snapshots();
  }
}
