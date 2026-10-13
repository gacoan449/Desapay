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
    final data = doc.data() ?? <String, dynamic>{};

    final rawStatus = (data['status'] ?? 'PENDING').toString().toLowerCase();
    StatusTransaksi statusEnum;
    if (rawStatus == 'sukses' || rawStatus == 'success' || rawStatus == 'berhasil') {
      statusEnum = StatusTransaksi.sukses;
    } else if (rawStatus == 'gagal' || rawStatus == 'failed' || rawStatus == 'failure') {
      statusEnum = StatusTransaksi.gagal;
    } else {
      statusEnum = StatusTransaksi.pending;
    }

    final rawTime = data['waktu'] ?? data['createdAt'] ?? data['created_at'];
    DateTime? waktuParsed;
    if (rawTime is Timestamp) {
      waktuParsed = rawTime.toDate();
    } else if (rawTime is DateTime) {
      waktuParsed = rawTime;
    }

    int parseAmount(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return Transaksi(
      id: doc.id,
      uid: data['uid']?.toString() ?? '',
      kodeProduk: (data['kodeProduk'] ?? data['buyer_sku_code'] ?? data['sku'] ?? '').toString(),
      namaProduk: (data['namaProduk'] ?? data['productName'] ?? 'Transaksi DesaPay').toString(),
      nomorTujuan: (data['nomorTujuan'] ?? data['customerNo'] ?? data['customer_no'] ?? '').toString(),
      hargaNominal: parseAmount(data['hargaNominal'] ?? data['sellingPrice'] ?? data['amount']),
      refId: (data['refId'] ?? data['providerRefId'] ?? data['transactionId'] ?? data['requestId'] ?? doc.id).toString(),
      status: statusEnum,
      waktu: waktuParsed,
      metodePembayaran: (data['metodePembayaran'] ?? data['paymentMethod'] ?? 'SALDO').toString(),
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
