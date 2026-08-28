// lib/services/tripay_service.dart
//
// PENTING:
// File Flutter TIDAK lagi menyimpan PRIVATE KEY.
// Pembuatan transaksi harus dilakukan oleh backend/server.
//
// Endpoint backend:
// POST https://DOMAIN-BACKEND-ANDA/api/topup/create

import 'dart:convert';

import 'package:http/http.dart' as http;

class TriPayInvoiceResult {
  final bool isSukses;
  final String pesan;
  final String? reference;
  final String? merchantRef;
  final String? paymentMethod;
  final String? paymentCode;
  final String? qrUrl;
  final String? qrString;
  final int? totalAmount;
  final int? feeAdmin;
  final int? expiredTimeTimestamp;

  const TriPayInvoiceResult({
    required this.isSukses,
    required this.pesan,
    this.reference,
    this.merchantRef,
    this.paymentMethod,
    this.paymentCode,
    this.qrUrl,
    this.qrString,
    this.totalAmount,
    this.feeAdmin,
    this.expiredTimeTimestamp,
  });

  factory TriPayInvoiceResult.fromJson(Map<String, dynamic> json) {
    return TriPayInvoiceResult(
      isSukses: json['success'] == true,
      pesan: json['message']?.toString() ?? 'Tidak ada informasi.',
      reference: json['reference']?.toString(),
      merchantRef: json['merchant_ref']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      paymentCode: json['payment_code']?.toString(),
      qrUrl: json['qr_url']?.toString(),
      qrString: json['qr_string']?.toString(),
      totalAmount: _toInt(json['total_amount']),
      feeAdmin: _toInt(json['fee_admin']),
      expiredTimeTimestamp: _toInt(json['expired_time']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }
}

abstract class ITriPayService {
  Future<TriPayInvoiceResult> buatTagihanClosedPayment({
    required String uid,
    required String method,
    required int amount,
  });
}

class TriPayService implements ITriPayService {
  // GANTI dengan URL backend Anda.
  //
  // JANGAN isi dengan URL API TriPay langsung.
  // API Key + Private Key harus berada di backend.
  static const String _backendBaseUrl =
      'https://DOMAIN-BACKEND-ANDA';

  @override
  Future<TriPayInvoiceResult> buatTagihanClosedPayment({
    required String uid,
    required String method,
    required int amount,
  }) async {
    if (uid.trim().isEmpty) {
      return const TriPayInvoiceResult(
        isSukses: false,
        pesan: 'Sesi pengguna tidak valid.',
      );
    }

    if (amount < 10000) {
      return const TriPayInvoiceResult(
        isSukses: false,
        pesan: 'Minimal top up adalah Rp 10.000.',
      );
    }

    if (method.trim().isEmpty) {
      return const TriPayInvoiceResult(
        isSukses: false,
        pesan: 'Metode pembayaran belum dipilih.',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_backendBaseUrl/api/topup/create'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'uid': uid,
              'method': method.trim().toUpperCase(),
              'amount': amount,
            }),
          )
          .timeout(const Duration(seconds: 30));

      Map<String, dynamic> json;

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          json = decoded;
        } else {
          return const TriPayInvoiceResult(
            isSukses: false,
            pesan: 'Respons server tidak valid.',
          );
        }
      } catch (_) {
        return TriPayInvoiceResult(
          isSukses: false,
          pesan:
              'Server mengembalikan respons tidak valid (${response.statusCode}).',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return TriPayInvoiceResult(
          isSukses: false,
          pesan: json['message']?.toString() ??
              'Gagal membuat tagihan pembayaran.',
        );
      }

      return TriPayInvoiceResult.fromJson(json);
    } catch (_) {
      return const TriPayInvoiceResult(
        isSukses: false,
        pesan: 'Tidak dapat menghubungi server pembayaran.',
      );
    }
  }
}
