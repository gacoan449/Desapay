import '../models/transaksi.dart';

class TransaksiService {
  // Tempat menampung data daftar riwayat transaksi di dalam memori aplikasi
  static final List<Transaksi> _daftarTransaksi = [];

  // Fungsi untuk mengambil semua data riwayat transaksi
  static List<Transaksi> semua() {
    // Mengembalikan data dengan urutan transaksi terbaru berada di paling atas
    return _daftarTransaksi.reversed.toList();
  }

  // Fungsi otomatis untuk mencatat/menambahkan riwayat transaksi baru (BARU)
  static void tambah({
    required String produk,
    required String tujuan,
    required int harga,
    required String status,
  }) {
    // Mengambil jam dan tanggal saat transaksi terjadi
    final sekarang = DateTime.now();
    final stringTanggal = "${sekarang.day}/${sekarang.month} ${sekarang.hour}:${sekarang.minute}";

    _daftarTransaksi.add(
      Transaksi(
        produk: produk,
        tujuan: tujuan,
        harga: harga,
        status: status,
        tanggal: stringTanggal,
      ),
    );
  }
}
