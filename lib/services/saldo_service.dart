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
    String? idempotencyKey,
  });

  Stream<int> streamSaldo(String uid);

  Stream<List<MutasiSaldo>> streamMutasiUser(String uid);
}

/// Implementasi layanan saldo dan mutasi DesaPay.
///
/// CATATAN:
/// - Saldo menggunakan field `balance`.
/// - Perubahan saldo menggunakan Firestore Transaction.
/// - Top-up callback WAJIB memberikan `idempotencyKey` unik
///   seperti reference/merchant_ref TriPay.
/// - Satu idempotencyKey hanya boleh diproses satu kali.
/// - Saldo dan log mutasi diperbarui dalam transaksi yang sama.
class SaldoService implements ISaldoService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _saldoField = 'balance';

  // Koleksi khusus untuk menyimpan idempotency transaksi saldo.
  static const String _processedCollection =
      'saldo_processed_transactions';

  // =========================================================
  // UPDATE SALDO ATOMIC + ANTI DOUBLE CREDIT
  // =========================================================

  @override
  Future<SaldoUpdateResult> updateSaldo({
    required String uid,
    required int nominal,
    required bool isTambah,
    String keterangan = "Transaksi",
    String? idempotencyKey,
  }) async {
    final String cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
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

    final String? cleanIdempotencyKey =
        idempotencyKey?.trim();

    // =======================================================
    // TRANSAKSI FINANSIAL DARI BACKEND WAJIB MEMILIKI KEY
    //
    // Untuk callback TriPay:
    // idempotencyKey = reference atau merchant_ref
    //
    // Tanpa key, fungsi tetap bisa digunakan untuk transaksi
    // internal biasa, tetapi perlindungan duplicate callback
    // tidak dapat diterapkan.
    // =======================================================

    if (isTambah &&
        (cleanIdempotencyKey == null ||
            cleanIdempotencyKey.isEmpty)) {
      return const SaldoUpdateResult(
        isSuccess: false,
        message:
            "ID transaksi wajib diberikan untuk pengisian saldo.",
      );
    }

    final DocumentReference<Map<String, dynamic>> userDoc =
        _firestore.collection("users").doc(cleanUid);

    final DocumentReference<Map<String, dynamic>>? processedDoc =
        cleanIdempotencyKey == null ||
                cleanIdempotencyKey.isEmpty
            ? null
            : _firestore
                .collection(_processedCollection)
                .doc(_safeDocumentId(cleanIdempotencyKey));

    try {
      return await _firestore.runTransaction<
          SaldoUpdateResult>((transaction) async {
        // =====================================================
        // 1. CEK TRANSAKSI SUDAH PERNAH DIPROSES ATAU BELUM
        // =====================================================

        if (processedDoc != null) {
          final processedSnapshot =
              await transaction.get(processedDoc);

          if (processedSnapshot.exists) {
            final processedData =
                processedSnapshot.data() ??
                    <String, dynamic>{};

            final int saldoTersimpan =
                _parseInteger(
              processedData['saldoAkhir'],
            );

            return SaldoUpdateResult(
              isSuccess: true,
              message:
                  "Transaksi sudah diproses sebelumnya.",
              saldoAkhir: saldoTersimpan,
            );
          }
        }

        // =====================================================
        // 2. BACA USER
        // =====================================================

        final userSnapshot =
            await transaction.get(userDoc);

        if (!userSnapshot.exists) {
          return const SaldoUpdateResult(
            isSuccess: false,
            message:
                "Akun dompet pengguna tidak terdaftar di sistem.",
          );
        }

        final Map<String, dynamic> data =
            userSnapshot.data() ??
                <String, dynamic>{};

        final int saldoSekarang =
            _parseInteger(data[_saldoField]);

        // =====================================================
        // 3. HITUNG SALDO BARU
        // =====================================================

        int saldoBaru;

        if (isTambah) {
          // Proteksi overflow integer.
          if (nominal >
              9223372036854775807 - saldoSekarang) {
            return const SaldoUpdateResult(
              isSuccess: false,
              message:
                  "Nominal transaksi terlalu besar.",
            );
          }

          saldoBaru =
              saldoSekarang + nominal;
        } else {
          // ===================================================
          // PROTEKSI SALDO MINUS
          // ===================================================

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
        // 4. UPDATE SALDO USER
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
        // 5. BUAT MUTASI
        // =====================================================

        final DocumentReference<Map<String, dynamic>> logRef =
            _firestore
                .collection("mutasi_saldo")
                .doc();

        final MutasiSaldo logMutasi = MutasiSaldo(
          uid: cleanUid,
          tipe: isTambah
              ? TipeMutasi.masuk
              : TipeMutasi.keluar,
          nominal: nominal,
          saldoAwal: saldoSekarang,
          saldoAkhir: saldoBaru,
          keterangan:
              keterangan.trim().isEmpty
                  ? "Transaksi"
                  : keterangan.trim(),
          waktu: null,
        );

        transaction.set(
          logRef,
          logMutasi.toFirestore(),
        );

        // =====================================================
        // 6. SIMPAN IDEMPOTENCY RECORD
        //
        // Harus berada dalam Firestore Transaction yang sama.
        // Jika transaksi rollback, record ini juga rollback.
        // =====================================================

        if (processedDoc != null) {
          transaction.set(
            processedDoc,
            {
              "uid": cleanUid,
              "nominal": nominal,
              "isTambah": isTambah,
              "saldoAwal": saldoSekarang,
              "saldoAkhir": saldoBaru,
              "keterangan":
                  keterangan.trim().isEmpty
                      ? "Transaksi"
                      : keterangan.trim(),
              "processedAt":
                  FieldValue.serverTimestamp(),
              "mutasiId": logRef.id,
              "idempotencyKey":
                  cleanIdempotencyKey,
            },
          );
        }

        // =====================================================
        // 7. HASIL
        // =====================================================

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
            "Gagal memproses transaksi saldo: "
            "${e.message ?? e.code}",
      );
    } catch (e) {
      return SaldoUpdateResult(
        isSuccess: false,
        message:
            "Gagal memproses transaksi saldo.",
      );
    }
  }

  // =========================================================
  // REALTIME SALDO
  // =========================================================

  @override
  Stream<int> streamSaldo(String uid) {
    final String cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return Stream<int>.value(0);
    }

    return _firestore
        .collection("users")
        .doc(cleanUid)
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
    final String cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return Stream<List<MutasiSaldo>>.value(
        <MutasiSaldo>[],
      );
    }

    return _firestore
        .collection("mutasi_saldo")
        .where(
          "uid",
          isEqualTo: cleanUid,
        )
        .orderBy(
          "waktu",
          descending: true,
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => MutasiSaldo.fromFirestore(doc),
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
      if (!value.isFinite) {
        return 0;
      }

      return value.round();
    }

    String text =
        value.toString().trim();

    if (text.isEmpty) {
      return 0;
    }

    final int? direct =
        int.tryParse(text);

    if (direct != null) {
      return direct;
    }

    // Format Rupiah:
    // Rp 1.500.000
    // 1.500.000
    // 1,500,000
    text = text
        .replaceAll("Rp", "")
        .replaceAll("rp", "")
        .replaceAll(" ", "")
        .replaceAll(".", "")
        .replaceAll(",", "");

    return int.tryParse(text) ?? 0;
  }

  // =========================================================
  // FIRESTORE DOCUMENT ID SAFE
  // =========================================================

  String _safeDocumentId(String value) {
    final String clean =
        value.trim();

    if (clean.isEmpty) {
      throw ArgumentError(
        "Idempotency key tidak boleh kosong.",
      );
    }

    // Firestore document ID tidak boleh "." atau "..".
    // Karakter "/" harus diubah agar tidak dianggap sebagai
    // path separator.
    return clean
        .replaceAll("/", "_")
        .replaceAll("\\", "_")
        .replaceAll(".", "_");
  }
}
