import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaksi.dart';

/// Kontrak Abstraksi Layanan Riwayat Transaksi DesaPay (Domain Layer)
abstract class IRiwayatService {
  Future<bool> simpan(Transaksi transaksi);
  Stream<List<Transaksi>> streamRiwayatTransaksi({required String uid, required String filter});
}

/// Implementasi Layanan Manajemen Riwayat & Log Mutasi (Data Layer)
class RiwayatService implements IRiwayatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===================================================
  // 1. FUNGSI SIMPAN RIWAYAT TRANSAKSI REAL (NO DUMMY)
  // ===================================================
  @override
  Future<bool> simpan(Transaksi transaksi) async {
    // Riwayat resmi dibuat oleh backend/Admin SDK setelah transaksi diproses.
    // Client tidak diberi izin menulis ke koleksi transaksi.
    return false;
  }

  // ===================================================
  // 2. STREAM BACA RIWAYAT REAL-TIME & TYPE-SAFE (ENUM COMPATIBLE)
  // ===================================================
  @override
  Stream<List<Transaksi>> streamRiwayatTransaksi({
    required String uid,
    required String filter,
  }) {
    return _firestore
        .collection("transactions")
        .where("uid", isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final semuaTransaksi = snapshot.docs
              .map(Transaksi.fromFirestore)
              .toList()
            ..sort((a, b) {
              final aTime = a.waktu;
              final bTime = b.waktu;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

          if (filter == 'berhasil') {
            return semuaTransaksi.where((tx) => tx.status == StatusTransaksi.sukses).toList();
          }
          if (filter == 'pending_gagal') {
            return semuaTransaksi.where((tx) => tx.status != StatusTransaksi.sukses).toList();
          }
          return semuaTransaksi;
        });
  }
}
