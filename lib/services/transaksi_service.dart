import '../models/transaksi.dart';

class TransaksiService {
  // ===================================================
  // 1. MEMORI STATE LOKAL & PREMIUM PRESET DATA
  // ===================================================
  // Menyediakan daftar transaksi bawaan agar UI Riwayat terlihat premium saat mode demo
  static final List<Transaksi> _daftarTransaksi = [
    Transaksi(
      produk: "Telkomsel Pulsa Rp10.000",
      tujuan: "081234567890",
      harga: 11500,
      status: "SUKSES",
      tanggal: "15/07 14:20",
    ),
    Transaksi(
      produk: "Token Listrik PLN Rp50.000",
      tujuan: "53123456789",
      harga: 51500,
      status: "PENDING",
      tanggal: "15/07 10:15",
    ),
    Transaksi(
      produk: "Indosat Pulsa Rp5.000",
      tujuan: "085642131263",
      harga: 6500,
      status: "GAGAL",
      tanggal: "14/07 18:45",
    ),
  ];

  // ===================================================
  // 2. FUNGSI AMBIL SEMUA DATA RIWAYAT
  // ===================================================
  /// Mengambil semua list transaksi dengan susunan data terbaru berada di posisi paling atas.
  static List<Transaksi> semua() {
    return _daftarTransaksi.reversed.toList();
  }

  // ===================================================
  // 3. FUNGSI PENAMBAHAN DATA (AUTO TWO-DIGIT PADDING)
  // ===================================================
  /// Mencatat riwayat transaksi baru ke dalam memori dengan pemformatan tanggal premium.
  static void tambah({
    required String produk,
    required String tujuan,
    required int harga,
    required String status,
  }) {
    final DateTime sekarang = DateTime.now();

    // Menggunakan helper dua digit agar formatting tanggal rapi (contoh: 09:05, bukan 9:5)
    final String hari = sekarang.day.toString().padLeft(2, '0');
    final String bulan = sekarang.month.toString().padLeft(2, '0');
    final String jam = sekarang.hour.toString().padLeft(2, '0');
    final String menit = sekarang.minute.toString().padLeft(2, '0');

    final String stringTanggalFormated = "$hari/$bulan $jam:$menit";

    _daftarTransaksi.add(
      Transaksi(
        produk: produk,
        tujuan: tujuan,
        harga: harga,
        status: status,
        tanggal: stringTanggalFormated,
      ),
    );
  }

  // ===================================================
  // 4. FUNGSI CLEAR STATE (FOR TESTING PURPOSE)
  // ===================================================
  /// Menghapus seluruh data di dalam memori (biasanya digunakan untuk unit testing logout).
  static void bersihkanSemua() {
    _daftarTransaksi.clear();
  }
}
