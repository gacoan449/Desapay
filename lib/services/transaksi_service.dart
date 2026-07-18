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
  }) async {
    // 1. Validasi Awal Parameter Input Finansial
    if (nomorTujuan.trim().length < 4) {
      return const HasilEksekusiTransaksi(
        isSukses: false,
        pesan: "Nomor tujuan atau ID pelanggan tidak valid. Periksa kembali.",
      );
    }

    // Pembuatan ID Referensi Unik Sistem DesaPay (Sesuai Regulasi Pencegahan Double Payment)
    final String generatedRefId = "DESAPAY-${DateTime.now().millisecondsSinceEpoch}";

    // 2. Proteksi Finansial 1: Uji dan Kurangi Saldo Pengguna Lewat Jalur Transaksi Atomic
    if (metodePembayaran.toUpperCase() == 'SALDO') {
      final SaldoUpdateResult hasilPotongSaldo = await _saldoService.updateSaldo(
        uid: uid,
        nominal: produk.harga,
        isTambah: false,
        keterangan: "Pembelian ${produk.nama} ke $nomorTujuan",
      );

      if (!hasilPotongSaldo.isSuccess) {
        return HasilEksekusiTransaksi(
          isSukses: false,
          pesan: hasilPotongSaldo.message,
        );
      }
    }

    // 3. Tembak API Pihak Ketiga (Digiflazz Gateway Engine)
    final Map<String, dynamic> responDigiflazz = await _digiflazzService.kirimTransaksi(
      buyerSkuCode: produk.kode,
      customerNo: nomorTujuan.trim(),
    );

    final String statusRespon = (responDigiflazz['status'] ?? 'Gagal').toString().toLowerCase();
    final String pesanRespon = responDigiflazz['message'] ?? 'Transaksi sedang diproses oleh aggregator';

    StatusTransaksi statusAkhir = StatusTransaksi.pending;
    bool isTransaksiBerhasil = false;

    if (statusRespon == 'sukses') {
      statusAkhir = StatusTransaksi.sukses;
      isTransaksiBerhasil = true;
    } else if (statusRespon == 'gagal') {
      statusAkhir = StatusTransaksi.gagal;
      isTransaksiBerhasil = false;
    }

    // 4. Siapkan Rekaman Model Objek Transaksi Resmi DesaPay (Type-Safe)
    final Transaksi modelTransaksiLog = Transaksi(
      uid: uid,
      kodeProduk: produk.kode,
      namaProduk: produk.nama,
      nomorTujuan: nomorTujuan.trim(),
      hargaNominal: produk.harga,
      refId: generatedRefId,
      status: statusAkhir,
      metodePembayaran: metodePembayaran.toUpperCase(),
      waktu: DateTime.now(),
    );

    // 5. Simpan Data Rekam Jejak Ke Firebase Cloud Firestore Melalui RiwayatService
    await _riwayatService.simpan(modelTransaksiLog);

    // 6. Rollback Engine: Mekanisme Refund Otomatis Jika Deteksi Status Digiflazz Menyatakan 'Gagal'
    if (statusAkhir == StatusTransaksi.gagal && metodePembayaran.toUpperCase() == 'SALDO') {
      await _saldoService.updateSaldo(
        uid: uid,
        nominal: produk.harga,
        isTambah: true,
        keterangan: "REFUND: Gagal isi ${produk.nama} ke $nomorTujuan",
      );
      
      return HasilEksekusiTransaksi(
        isSukses: false,
        pesan: "Transaksi Gagal dari Provider: $pesanRespon. Saldo Anda telah dikembalikan secara utuh.",
        refId: generatedRefId,
        statusAkhir: StatusTransaksi.gagal,
      );
    }

    // 7. Hasilkan Konfirmasi Final untuk Disajikan ke Halaman UI Resi Pengguna
    return HasilEksekusiTransaksi(
      isSukses: isTransaksiBerhasil || statusAkhir == StatusTransaksi.pending,
      pesan: statusAkhir == StatusTransaksi.sukses 
          ? "Transaksi berhasil diproses!" 
          : "Transaksi Anda sedang dalam antrean jaringan pusat.",
      refId: generatedRefId,
      statusAkhir: statusAkhir,
    );
  }
}
