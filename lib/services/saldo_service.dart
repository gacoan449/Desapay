import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SaldoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===================================================
  // 1. UPDATE SALDO DENGAN ATOMIC TRANSACTION & SAFETY
  // ===================================================
  /// Melakukan penambahan atau pengurangan saldo pengguna secara aman (Atomic).
  /// [isTambah] = true untuk top-up, false untuk potong saldo transaksi.
  Future<bool> updateSaldo({
    required String uid,
    required int nominal,
    required bool isTambah,
    String keterangan = "Transaksi",
  }) async {
    if (nominal <= 0) return false;

    final DocumentReference<Map<String, dynamic>> userDoc =
        _firestore.collection("users").doc(uid);

    try {
      final bool transaksiSukses = await _firestore.runTransaction<bool>((transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snap = await transaction.get(userDoc);

        if (!snap.exists) {
          if (kDebugMode) print("SaldoService: Dokumen user tidak ditemukan.");
          return false;
        }

        final Map<String, dynamic> data = snap.data() ?? {};
        final int saldoSekarang = int.tryParse(data["saldo"].toString()) ?? 0;

        int saldoBaru = 0;

        if (isTambah) {
          saldoBaru = saldoSekarang + nominal;
        } else {
          // PROTEKSI FINANCIAL: Cegah saldo menjadi minus saat bertransaksi
          if (saldoSekarang < nominal) {
            if (kDebugMode) print("SaldoService: Saldo tidak mencukupi.");
            return false;
          }
          saldoBaru = saldoSekarang - nominal;
        }

        // Jalankan pembaruan saldo di dalam transaksi atomic
        transaction.update(userDoc, {"saldo": saldoBaru});

        // ===================================================
        // 2. AUDIT TRAIL: BIKIN LOG MUTASI REAL-TIME
        // ===================================================
        final DocumentReference logMutasiDoc = _firestore.collection("mutasi_saldo").doc();
        transaction.set(logMutasiDoc, {
          "uid": uid,
          "tipe": isTambah ? "MASUK" : "KELUAR",
          "nominal": nominal,
          "saldoAwal": saldoSekarang,
          "saldoAkhir": saldoBaru,
          "keterangan": keterangan,
          "waktu": FieldValue.serverTimestamp(),
        });

        return true;
      });

      return transaksiSukses;
    } catch (e) {
      if (kDebugMode) print("SaldoService Exception: Gagal memproses transaksi saldo -> $e");
      return false;
    }
  }

  // ===================================================
  // 3. STREAM CEK SALDO USER SECARA REAL-TIME
  // ===================================================
  /// Memantau perubahan saldo pengguna secara real-time untuk memperbarui UI dashboard.
  Stream<int> streamSaldo(String uid) {
    return _firestore
        .collection("users")
        .doc(uid)
        .snapshots()
        .map((snap) {
          if (snap.exists && snap.data() != null) {
            return int.tryParse(snap.data()!["saldo"].toString()) ?? 0;
          }
          return 0;
        });
  }
}
