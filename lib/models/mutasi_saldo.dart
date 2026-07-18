import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Representasi tipe aliran dana di DesaPay
enum TipeMutasi { masuk, keluar }

/// Model Data Resmi Log Audit Aliran Dana Pengguna DesaPay (Domain & Data Layer)
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

  /// Factory untuk memparsing dokumen dari Firestore Snapshot secara aman (Type-Safe)
  factory MutasiSaldo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    // Konversi enum tipe secara aman
    final String dbTipe = (data['tipe'] ?? 'KELUAR').toString().toLowerCase();
    final TipeMutasi tipeEnum = dbTipe == 'masuk' ? TipeMutasi.masuk : TipeMutasi.keluar;

    // Parsing Timestamp Server Firebase
    DateTime? waktuParsed;
    if (data['waktu'] != null && data['waktu'] is Timestamp) {
      waktuParsed = (data['waktu'] as Timestamp).toDate();
    }

    return MutasiSaldo(
      id: doc.id,
      uid: data['uid']?.toString() ?? '',
      tipe: tipeEnum,
      nominal: int.tryParse(data['nominal'].toString()) ?? 0,
      saldoAwal: int.tryParse(data['saldoAwal'].toString()) ?? 0,
      saldoAkhir: int.tryParse(data['saldoAkhir'].toString()) ?? 0,
      keterangan: data['keterangan']?.toString() ?? 'Transaksi',
      waktu: waktuParsed,
    );
  }

  /// Menghasilkan format mata uang Rupiah premium untuk komponen nominal
  String get nominalFormatRupiah {
    final String prefix = tipe == TipeMutasi.masuk ? '+ ' : '- ';
    final String formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(nominal);
    return '$prefix$formatted';
  }

  /// Konversi objek model ke Map/JSON untuk dikirim ke Firestore Database
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'tipe': tipe.name.toUpperCase(),
      'nominal': nominal,
      'saldoAwal': saldoAwal,
      'saldoAkhir': saldoAkhir,
      'keterangan': keterangan,
      'waktu': waktu != null ? Timestamp.fromDate(waktu!) : FieldValue.serverTimestamp(),
    };
  }
}
