import '../models/transaksi.dart';

class TransaksiService {

  static final List<Transaksi> _riwayat = [];

  static void tambah(Transaksi transaksi) {
    _riwayat.insert(0, transaksi);
  }

  static List<Transaksi> semua() {
    return _riwayat;
  }

  static void hapusSemua() {
    _riwayat.clear();
  }

}
