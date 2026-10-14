import '../models/transaksi.dart';
import '../models/produk.dart';
import 'digiflazz_service.dart';
import 'pin_service.dart';
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
    required String pin,
  });
}

/// Implementasi Orkes Logika Bisnis Transaksi Finansial Terintegrasi (Data Layer)
class TransaksiService implements ITransaksiService {
  final IDigiflazzService _digiflazzService;
  // Dipertahankan untuk kompatibilitas constructor dengan pemanggil lama.
  TransaksiService({
    required IDigiflazzService digiflazzService,
    required ISaldoService saldoService,
    required IRiwayatService riwayatService,
  }) : _digiflazzService = digiflazzService;

  // =========================================================================
  // CORE ENGINE TRANSAKSI PPOB (ANTI BALAPAN DATA & VERIFIKASI MULTI-LAYER)
  // =========================================================================
  @override
  Future<HasilEksekusiTransaksi> prosesPembelianProdukBahu({
    required String uid,
    required Produk produk,
    required String nomorTujuan,
    required String metodePembayaran,
    required String pin,
  }) async {
    // 1. Validasi Awal Parameter Input Finansial
    if (nomorTujuan.trim().length < 4) {
      return const HasilEksekusiTransaksi(
        isSukses: false,
        pesan: "Nomor tujuan atau ID pelanggan tidak valid. Periksa kembali.",
      );
    }

    // Pembuatan ID Referensi Unik Sistem DesaPay (Sesuai Regulasi Pencegahan Double Payment)
    final String generatedRefId = "DESAPAY-${DateTime.now().microsecondsSinceEpoch}";

    // PIN diverifikasi server dan token otorisasi hanya dapat dipakai sekali.
    final authorizationId = await PinService().authorizePurchase(
      pin: pin,
      requestId: generatedRefId,
      sku: produk.kode,
      customerNo: nomorTujuan.trim(),
    );

    // Saldo dan transaksi ditangani atomik oleh backend. Tidak ada debit/refund
    // dari client, sehingga aplikasi tidak dapat memalsukan atau menggandakan saldo.
    final Map<String, dynamic> responDigiflazz =
        await _digiflazzService.kirimTransaksi(
      buyerSkuCode: produk.kode,
      customerNo: nomorTujuan.trim(),
      requestId: generatedRefId,
      pinAuthorizationId: authorizationId,
    );

    final String statusRespon = (responDigiflazz['status'] ?? 'Gagal').toString().toLowerCase();
    final String providerRefId = (responDigiflazz['ref_id'] ?? generatedRefId).toString();
    final String pesanRespon = responDigiflazz['message'] ?? 'Transaksi sedang diproses oleh aggregator';

    StatusTransaksi statusAkhir = StatusTransaksi.pending;
    bool isTransaksiBerhasil = false;

    if (statusRespon == 'sukses' || statusRespon == 'success') {
      statusAkhir = StatusTransaksi.sukses;
      isTransaksiBerhasil = true;
    } else if (statusRespon == 'gagal' || statusRespon == 'failed' || statusRespon == 'failure') {
      statusAkhir = StatusTransaksi.gagal;
      isTransaksiBerhasil = false;
    }

    // 7. Hasilkan Konfirmasi Final untuk Disajikan ke Halaman UI Resi Pengguna
    return HasilEksekusiTransaksi(
      isSukses: isTransaksiBerhasil || statusAkhir == StatusTransaksi.pending,
      pesan: statusAkhir == StatusTransaksi.sukses
          ? "Transaksi berhasil diproses!"
          : statusAkhir == StatusTransaksi.gagal
              ? "Transaksi gagal: $pesanRespon"
              : "Transaksi Anda sedang dalam antrean jaringan pusat.",
      refId: providerRefId,
      statusAkhir: statusAkhir,
    );
  }
}
