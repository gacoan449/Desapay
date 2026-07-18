import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaksi.dart';

/// Kontrak Abstraksi Layanan Riwayat Transaksi DesaPay (Domain Layer)
abstract class IRiwayatService {
  Future<bool> simpan(Transaksi transaksi);
  Stream<List<Transaksi>> streamRiwayatTransaksi({required String uid, required String filter});
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
  // 2. STREAM BACA RIWAYAT REAL-TIME & TYPE-SAFE (ENUM COMPATIBLE)
  // ===================================================
  @override
  Stream<List<Transaksi>> streamRiwayatTransaksi({required String uid, required String filter}) {
    return _firestore
        .collection("transaksi")
        .where("uid", isEqualTo: uid)
        .orderBy("waktu", descending: true)
        .snapshots()
        .map((snapshot) {
          final List<Transaksi> semuaTransaksi = snapshot.docs.map((doc) {
            return Transaksi.fromFirestore(doc);
          }).toList();

          // Memanfaatkan nama properti dari Enum secara aman (.name) untuk penyaringan data
          if (filter == 'berhasil') {
            return semuaTransaksi.where((tx) => 
              tx.status.name.toLowerCase() == 'sukses' || 
              tx.status.name.toLowerCase() == 'berhasil'
            ).toList();
          } else if (filter == 'pending_gagal') {
            return semuaTransaksi.where((tx) => 
              tx.status.name.toLowerCase() != 'sukses' && 
              tx.status.name.toLowerCase() != 'berhasil'
            ).toList();
          }
          
          return semuaTransaksi;
        });
  }
}
