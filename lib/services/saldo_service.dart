import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mutasi_saldo.dart';

/// Objek pembungkus respon transaksi saldo agar UI dapat membaca status secara rinci
class SaldoUpdateResult {
  final bool isSuccess;
  final String message;
  final int saldoAkhir;

  const SaldoUpdateResult({
    required this.isSuccess,
    required this.message,
    this.saldoAkhir = 0,
  });
}

/// Kontrak Abstraksi Layanan Manajemen Saldo DesaPay (Domain Layer)
abstract class ISaldoService {
  Future<SaldoUpdateResult> updateSaldo({
    required String uid,
    required int nominal,
    required bool isTambah,
    String keterangan,
  });
  Stream<int> streamSaldo(String uid);
  Stream<List<MutasiSaldo>> streamMutasiUser(String uid);
}

/// Implementasi Layanan Manajemen Dompet & Audit Saldo Finansial (Data Layer)
class SaldoService implements ISaldoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================================================================
  // 1. UPDATE SALDO DENGAN ATOMIC TRANSACTION & SAFETY (ANTI DOUBLE SPENDING)
  // =========================================================================
  @override
  Future<SaldoUpdateResult> updateSaldo({
    required String uid,
    required int nominal,
    required bool isTambah,
    String keterangan = "Transaksi",
  }) async {
    if (nominal <= 0) {
      return const SaldoUpdateResult(
        isSuccess: false, 
        message: "Nominal transaksi harus lebih besar dari nol.",
      );
    }

    final DocumentReference<Map<String, dynamic>> userDoc =
        _firestore.collection("users").doc(uid);

    try {
      final SaldoUpdateResult result = await _firestore.runTransaction<SaldoUpdateResult>((transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snap = await transaction.get(userDoc);

        if (!snap.exists) {
          return const SaldoUpdateResult(
            isSuccess: false, 
            message: "Akun dompet pengguna tidak terdaftar di sistem.",
          );
        }

        final Map<String, dynamic> data = snap.data() ?? {};
        final int saldoSekarang = int.tryParse(data["saldo"].toString()) ?? 0;

        int saldoBaru = 0;

        if (isTambah) {
          saldoBaru = saldoSekarang + nominal;
        } else {
          // PROTEKSI FINANCIAL: Validasi kecukupan saldo (Cegah Nilai Minus/Fraud)
          if (saldoSekarang < nominal) {
            return SaldoUpdateResult(
              isSuccess: false, 
              message: "Transaksi ditolak. Saldo DesaPay Anda tidak mencukupi.",
              saldoAkhir: saldoSekarang,
            );
          }
          saldoBaru = saldoSekarang - nominal;
        }

        // 1. Eksekusi mutasi saldo pada dokumen user secara aman
        transaction.update(userDoc, {"saldo": saldoBaru});

        // 2. Buat Log Audit Trail Mutasi (Type-Safe & Menggunakan Model Transaksi Asli)
        final DocumentReference logMutasiDoc = _firestore.collection("mutasi_saldo").doc();
        final MutasiSaldo logMutasi = MutasiSaldo(
          uid: uid,
          tipe: isTambah ? TipeMutasi.masuk : TipeMutasi.keluar,
          nominal: nominal,
          saldoAwal: saldoSekarang,
          saldoAkhir: saldoBaru,
          keterangan: keterangan.trim(),
        );

        transaction.set(logMutasiDoc, logMutasi.toFirestore());

        return SaldoUpdateResult(
          isSuccess: true, 
          message: isTambah ? "Pengisian saldo berhasil." : "Pembayaran saldo berhasil.",
          saldoAkhir: saldoBaru,
        );
      });

      return result;
    } catch (e) {
      // Keamanan Finansial: Jika transaction timeout/interrupted, otomatis rollback & no crash
      return SaldoUpdateResult(
        isSuccess: false, 
        message: "Gagal memproses transaksi saldo: ${e.toString()}",
      );
    }
  }

  // =========================================================================
  // 2. STREAM MONITORING SALDO REAL-TIME UNTUK DASHBOARD PREMIUM
  // =========================================================================
  @override
  Stream<int> streamSaldo(String uid) {
    if (uid.isEmpty) return Stream.value(0);
    
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

  // =========================================================================
  // 3. STREAM LOG MUTASI UANG MASUK/KELUAR UNTUK HALAMAN POCKET/AKUN
  // =========================================================================
  @override
  Stream<List<MutasiSaldo>> streamMutasiUser(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    return _firestore
        .collection("mutasi_saldo")
        .where("uid", isEqualTo: uid)
        .orderBy("waktu", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MutasiSaldo.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            );
          }).toList();
        });
  }
}
