import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaksi.dart';

/// Kontrak Abstraksi Layanan Riwayat Transaksi DesaPay (Domain Layer)
abstract class IRiwayatService {
  Future<bool> simpan(Transaksi transaksi);
  Stream<List<Transaksi>> dapatkanRiwayatUser();
}

/// Implementasi Layanan Manajemen Riwayat & Log Mutasi (Data Layer)
class RiwayatService implements IRiwayatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===================================================
  // 1. FUNGSI SIMPAN RIWAYAT TRANSAKSI REAL (NO DUMMY)
  // ===================================================
  @override
  Future<bool> simpan(Transaksi transaksi) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("Sesi pengguna tidak ditemukan. Aksi dibatalkan demi keamanan.");
      }

      // Memastikan data yang disimpan diikat langsung ke UID pengguna aktif saat ini
      final Transaksi secureTransaksi = Transaksi(
        uid: currentUser.uid,
        kodeProduk: transaksi.kodeProduk,
        namaProduk: transaksi.namaProduk,
        nomorTujuan: transaksi.nomorTujuan,
        hargaNominal: transaksi.hargaNominal,
        refId: transaksi.refId,
        status: transaksi.status,
        metodePembayaran: transaksi.metodePembayaran,
      );

      // Menambahkan log mutasi langsung ke koleksi 'transaksi' produksi
      await _firestore.collection("transaksi").add(secureTransaksi.toFirestore());
      return true;
    } catch (e) {
      // Penanganan kesalahan terkendali tanpa memicu crash aplikasi saat rilis APK
      return false;
    }
  }

  // ===================================================
  // 2. STREAM BACA RIWAYAT REAL-TIME & TYPE-SAFE
  // ===================================================
  @override
  Stream<List<Transaksi>> dapatkanRiwayatUser() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    // Mengembalikan aliran data list objek model yang siap pakai langsung oleh StreamBuilder di UI
    return _firestore
        .collection("transaksi")
        .where("uid", isEqualTo: currentUser.uid)
        .orderBy("waktu", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Transaksi.fromFirestore(doc);
          }).toList();
        });
  }
}
