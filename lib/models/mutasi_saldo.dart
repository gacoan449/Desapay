// lib/models/mutasi_saldo.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum TipeMutasi { masuk, keluar }

class MutasiSaldo {
  final String? id;
  final String uid;
  final TipeMutasi tipe;
  final int nominal;
  final int saldoAwal;
  final int saldoAkhir;
  final String keterangan;
  final DateTime? waktu;

  const MutasiSaldo({
    this.id,
    required this.uid,
    required this.tipe,
    required this.nominal,
    required this.saldoAwal,
    required this.saldoAkhir,
    required this.keterangan,
    this.waktu,
  });

  factory MutasiSaldo.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final tipeString =
        data['tipe']?.toString().toLowerCase().trim() ?? 'keluar';

    final tipe = tipeString == 'masuk'
        ? TipeMutasi.masuk
        : TipeMutasi.keluar;

    DateTime? waktu;

    final rawWaktu = data['waktu'];

    if (rawWaktu is Timestamp) {
      waktu = rawWaktu.toDate();
    } else if (rawWaktu is DateTime) {
      waktu = rawWaktu;
    }

    return MutasiSaldo(
      id: doc.id,
      uid: data['uid']?.toString() ?? '',
      tipe: tipe,
      nominal: _toInt(data['nominal']),
      saldoAwal: _toInt(data['saldoAwal']),
      saldoAkhir: _toInt(data['saldoAkhir']),
      keterangan:
          data['keterangan']?.toString().trim().isNotEmpty == true
              ? data['keterangan'].toString()
              : 'Transaksi',
      waktu: waktu,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get nominalFormatRupiah {
    final prefix = tipe == TipeMutasi.masuk ? '+ ' : '- ';

    final formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(nominal);

    return '$prefix$formatted';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'tipe': tipe == TipeMutasi.masuk ? 'MASUK' : 'KELUAR',
      'nominal': nominal,
      'saldoAwal': saldoAwal,
      'saldoAkhir': saldoAkhir,
      'keterangan':
          keterangan.trim().isEmpty ? 'Transaksi' : keterangan.trim(),
      'waktu': waktu != null
          ? Timestamp.fromDate(waktu!)
          : FieldValue.serverTimestamp(),
    };
  }
}
