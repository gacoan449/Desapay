// lib/services/tripay_service.dart
//
// PENTING:
// File Flutter TIDAK lagi menyimpan PRIVATE KEY.
// Pembuatan transaksi harus dilakukan oleh backend/server.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_channel.dart';

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
  static const String _backendBaseUrl = 'https://DOMAIN-BACKEND-ANDA';

  @override
  Future<TriPayInvoiceResult> buatTagihanClosedPayment({
    required String uid,
    required String method,
    required int amount,
  }) async {
    if (uid.trim().isEmpty) {
      return const TriPayInvoiceResult(isSukses: false, pesan: 'Sesi pengguna tidak valid.');
    }
    if (amount < 10000) {
      return const TriPayInvoiceResult(isSukses: false, pesan: 'Minimal top up adalah Rp 10.000.');
    }
    if (method.trim().isEmpty) {
      return const TriPayInvoiceResult(isSukses: false, pesan: 'Metode pembayaran belum dipilih.');
    }

    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/api/topup/create'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'uid': uid, 'method': method.trim().toUpperCase(), 'amount': amount}),
      ).timeout(const Duration(seconds: 30));

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const TriPayInvoiceResult(isSukses: false, pesan: 'Respons server tidak valid.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return TriPayInvoiceResult(isSukses: false, pesan: decoded['message']?.toString() ?? 'Gagal membuat tagihan pembayaran.');
      }
      return TriPayInvoiceResult.fromJson(decoded);
    } catch (_) {
      return const TriPayInvoiceResult(isSukses: false, pesan: 'Tidak dapat menghubungi server pembayaran.');
    }
  }

  Future<List<PaymentChannel>> getPaymentChannels() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/api/payment/channels'),
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) return <PaymentChannel>[];
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .whereType<Map>()
            .map((item) => PaymentChannel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return <PaymentChannel>[];
    } catch (_) {
      return <PaymentChannel>[];
    }
  }
}

/// Backward-compatible class name used by existing screens.
class TripayService extends TriPayService {}
