import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Representasi status transaksi di ekosistem Fintech DesaPay
enum StatusTransaksi { pending, sukses, gagal }

/// Model Data Resmi untuk Mutasi & Riwayat Transaksi DesaPay (Domain & Data Layer)
class Transaksi {
  final String? id;
  final String uid;
  final String kodeProduk;
  final String namaProduk;
  final String nomorTujuan;
  final int hargaNominal;
  final String refId;
  final StatusTransaksi status;
  final DateTime? waktu;
  final String metodePembayaran;

  const Transaksi({
    this.id,
    required this.uid,
    required this.kodeProduk,
    required this.namaProduk,
    required this.nomorTujuan,
    required this.hargaNominal,
    required this.refId,
    required this.status,
    this.waktu,
    required this.metodePembayaran,
  });

  /// Factory untuk memparsing dokumen dari Firestore Snapshot secara aman (Type-Safe)
  factory Transaksi.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    // Konversi enum status secara aman
    StatusTransaksi statusEnum = StatusTransaksi.pending;
    final String dbStatus = (data['status'] ?? 'PENDING').toString().toLowerCase();
    if (dbStatus == 'sukses') {
      statusEnum = StatusTransaksi.sukses;
    } else if (dbStatus == 'gagal') {
      statusEnum = StatusTransaksi.gagal;
    }

    // Parsing Timestamp Server Firebase secara aman
    DateTime? waktuParsed;
    if (data['waktu'] != null && data['waktu'] is Timestamp) {
      waktuParsed = (data['waktu'] as Timestamp).toDate();
    }

    return Transaksi(
      id: doc.id,
      uid: data['uid']?.toString() ?? '',
      kodeProduk: data['kodeProduk']?.toString() ?? '',
      namaProduk: data['namaProduk']?.toString() ?? 'Transaksi DesaPay',
      nomorTujuan: data['nomorTujuan']?.toString() ?? '',
      hargaNominal: int.tryParse(data['hargaNominal'].toString()) ?? 0,
      refId: data['refId']?.toString() ?? '',
      status: statusEnum,
      waktu: waktuParsed,
      metodePembayaran: data['metodePembayaran']?.toString() ?? 'SALDO',
    );
  }

  /// Menghasilkan format mata uang Rupiah premium untuk komponen UI
  String get hargaFormatRupiah {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(hargaNominal);
  }

  /// Menghasilkan format tanggal transaksi yang elegan untuk riwayat aplikasi
  String get tanggalFormatIndo {
    if (waktu == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(waktu!);
  }

  /// Konversi objek model ke Map/JSON untuk dikirim ke Firestore Database
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'kodeProduk': kodeProduk,
      'namaProduk': namaProduk,
      'nomorTujuan': nomorTujuan,
      'hargaNominal': hargaNominal,
      'refId': refId,
      'status': status.name.toUpperCase(),
      'waktu': waktu != null ? Timestamp.fromDate(waktu!) : FieldValue.serverTimestamp(),
      'metodePembayaran': metodePembayaran,
    };
  }
}
