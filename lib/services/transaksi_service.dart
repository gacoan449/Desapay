import '../models/transaksi.dart';
import '../models/produk.dart';
import 'digiflazz_service.dart';
import 'saldo_service.dart';
import 'riwayat_service.dart';

/// Objek pembungkus status keluaran dari eksekusi transaksi PPOB di DesaPay
class HasilEksekusiTransaksi {
  final bool isSukses;
  final String pesan;
  final String refId;
  final StatusTransaksi statusAkhir;

  const HasilEksekusiTransaksi({
    required this.isSukses,
    required this.pesan,
    this.refId = '',
    this.statusAkhir = StatusTransaksi.gagal,
  });
}

/// Kontrak Abstraksi Layanan Alur Kerja Eksekusi Transaksi Finansial DesaPay (Domain Layer)
abstract class ITransaksiService {
  Future<HasilEksekusiTransaksi> prosesPembelianProdukBahu({
    required String uid,
    required Produk produk,
    required String nomorTujuan,
    required String metodePembayaran,
    required String transactionPin,
  });
}

/// Implementasi Orkes Logika Bisnis Transaksi Finansial Terintegrasi (Data Layer)
class TransaksiService implements ITransaksiService {
  final IDigiflazzService _digiflazzService;
  final ISaldoService _saldoService;
  final IRiwayatService _riwayatService;

  /// Dependency Injection via Constructor untuk menjamin ketaatan pada SOLID Principles
  TransaksiService({
    required IDigiflazzService digiflazzService,
    required ISaldoService saldoService,
    required IRiwayatService riwayatService,
  })  : _digiflazzService = digiflazzService,
        _saldoService = saldoService,
        _riwayatService = riwayatService;

  // =========================================================================
  // CORE ENGINE TRANSAKSI PPOB (ANTI BALAPAN DATA & VERIFIKASI MULTI-LAYER)
  // =========================================================================
  @override
  Future<HasilEksekusiTransaksi> prosesPembelianProdukBahu({
    required String uid,
    required Produk produk,
    required String nomorTujuan,
    required String metodePembayaran,
    required String transactionPin,
  }) async {
    if (nomorTujuan.trim().length < 4) {
      return const HasilEksekusiTransaksi(
        isSukses: false,
        pesan: "Nomor tujuan atau ID pelanggan tidak valid.",
      );
    }

    if (metodePembayaran.toUpperCase() != 'SALDO') {
      return const HasilEksekusiTransaksi(
        isSukses: false,
        pesan: "Pembelian produk hanya mendukung saldo DesaPay.",
      );
    }

    // Debit, refund, status, and ledger are exclusively server-owned.
    // Do not debit/refund from Flutter: the callable already performs the
    // authoritative price lookup and atomic balance operation.
    final respon = await _digiflazzService.kirimTransaksi(
      buyerSkuCode: produk.kode,
      customerNo: nomorTujuan.trim(),
      transactionPin: transactionPin,
    );

    final statusText =
        (respon['status'] ?? 'FAILED').toString().trim().toUpperCase();
    final refId = (respon['ref_id'] ?? '').toString();
    final message = (respon['message'] ?? respon['msg'] ?? '').toString();

    if (statusText == 'SUCCESS' || statusText == 'SUKSES') {
      return HasilEksekusiTransaksi(
        isSukses: true,
        pesan: message.isEmpty ? "Transaksi berhasil diproses." : message,
        refId: refId,
        statusAkhir: StatusTransaksi.sukses,
      );
    }

    if (statusText == 'FAILED' || statusText == 'GAGAL' || statusText == 'FAIL') {
      return HasilEksekusiTransaksi(
        isSukses: false,
        pesan: message.isEmpty ? "Transaksi gagal. Periksa riwayat transaksi." : message,
        refId: refId,
        statusAkhir: StatusTransaksi.gagal,
      );
    }

    return HasilEksekusiTransaksi(
      isSukses: false,
      pesan: "Transaksi sedang diproses. Periksa status sebelum mencoba kembali.",
      refId: refId,
      statusAkhir: StatusTransaksi.pending,
    );
  }}
