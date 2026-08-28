import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mutasi_saldo.dart';

/// Hasil operasi perubahan saldo.
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

/// Kontrak layanan saldo DesaPay.
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

/// Implementasi layanan saldo dan mutasi.
class SaldoService implements ISaldoService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // FIELD SALDO UTAMA DESAPAY
  //
  // balance = sumber saldo utama.
  //
  // FirestoreService dan backend transaksi DesaPay
  // juga menggunakan field "balance".
  // =========================================================

  static const String _saldoField = 'balance';

  // =========================================================
  // UPDATE SALDO ATOMIC
  // =========================================================

  @override
  Future<SaldoUpdateResult> updateSaldo({
    required String uid,
    required int nominal,
    required bool isTambah,
    String keterangan = "Transaksi",
  }) async {
    if (uid.trim().isEmpty) {
      return const SaldoUpdateResult(
        isSuccess: false,
        message: "UID pengguna tidak valid.",
      );
    }

    if (nominal <= 0) {
      return const SaldoUpdateResult(
        isSuccess: false,
        message: "Nominal transaksi harus lebih besar dari nol.",
      );
    }

    final userDoc =
        _firestore.collection("users").doc(uid);

    try {
      return await _firestore.runTransaction<
          SaldoUpdateResult>((transaction) async {
        final snap =
            await transaction.get(userDoc);

        if (!snap.exists) {
          return const SaldoUpdateResult(
            isSuccess: false,
            message:
                "Akun dompet pengguna tidak terdaftar di sistem.",
          );
        }

        final data =
            snap.data() ?? <String, dynamic>{};

        final saldoSekarang =
            _parseInteger(data[_saldoField]);

        int saldoBaru;

        if (isTambah) {
          saldoBaru =
              saldoSekarang + nominal;
        } else {
          if (saldoSekarang < nominal) {
            return SaldoUpdateResult(
              isSuccess: false,
              message:
                  "Transaksi ditolak. Saldo DesaPay tidak mencukupi.",
              saldoAkhir: saldoSekarang,
            );
          }

          saldoBaru =
              saldoSekarang - nominal;
        }

        // =====================================================
        // UPDATE SALDO
        // =====================================================

        transaction.update(
          userDoc,
          {
            _saldoField: saldoBaru,
            "updatedAt":
                FieldValue.serverTimestamp(),
          },
        );

        // =====================================================
        // AUDIT MUTASI
        // =====================================================

        final logRef = _firestore
            .collection("mutasi_saldo")
            .doc();

        final logMutasi = MutasiSaldo(
          uid: uid,
          tipe: isTambah
              ? TipeMutasi.masuk
              : TipeMutasi.keluar,
          nominal: nominal,
          saldoAwal: saldoSekarang,
          saldoAkhir: saldoBaru,
          keterangan: keterangan.trim().isEmpty
              ? "Transaksi"
              : keterangan.trim(),
        );

        transaction.set(
          logRef,
          logMutasi.toFirestore(),
        );

        return SaldoUpdateResult(
          isSuccess: true,
          message: isTambah
              ? "Pengisian saldo berhasil."
              : "Pembayaran saldo berhasil.",
          saldoAkhir: saldoBaru,
        );
      });
    } on FirebaseException catch (e) {
      return SaldoUpdateResult(
        isSuccess: false,
        message:
            "Gagal memproses transaksi saldo: ${e.message ?? e.code}",
      );
    } catch (e) {
      return SaldoUpdateResult(
        isSuccess: false,
        message:
            "Gagal memproses transaksi saldo: $e",
      );
    }
  }

  // =========================================================
  // REALTIME SALDO
  // =========================================================

  @override
  Stream<int> streamSaldo(String uid) {
    if (uid.trim().isEmpty) {
      return Stream.value(0);
    }

    return _firestore
        .collection("users")
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists ||
          snap.data() == null) {
        return 0;
      }

      return _parseInteger(
        snap.data()![_saldoField],
      );
    });
  }

  // =========================================================
  // REALTIME MUTASI USER
  // =========================================================

  @override
  Stream<List<MutasiSaldo>> streamMutasiUser(
    String uid,
  ) {
    if (uid.trim().isEmpty) {
      return Stream.value(
        <MutasiSaldo>[],
      );
    }

    return _firestore
        .collection("mutasi_saldo")
        .where(
          "uid",
          isEqualTo: uid,
        )
        .orderBy(
          "waktu",
          descending: true,
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => MutasiSaldo.fromFirestore(
              doc,
            ),
          )
          .toList();
    });
  }

  // =========================================================
  // PARSE ANGKA
  // =========================================================

  int _parseInteger(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return 0;
    }

    final direct =
        int.tryParse(text);

    if (direct != null) {
      return direct;
    }

    final decimal =
        double.tryParse(text);

    if (decimal != null) {
      return decimal.round();
    }

    final cleaned =
        text
            .replaceAll("Rp", "")
            .replaceAll("rp", "")
            .replaceAll(" ", "")
            .replaceAll(".", "")
            .replaceAll(",", "");

    return int.tryParse(cleaned) ?? 0;
  }
}
