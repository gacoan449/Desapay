import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/payment_channel.dart';

class TripayService {
  // ===================================================
  // KREDENSIAL INTEGRASI GATEWAY TRIPAY
  // ===================================================
  static const String apiKey = "ISI_API_KEY_DISINI";
  static const String privateKey = "ISI_PRIVATE_KEY_DISINI";
  static const String merchantCode = "ISI_MERCHANT_CODE";

  // Mode Toggle: Ganti ke 'false' jika aplikasi DesaPay sudah siap rilis rill (Live Production)
  static const bool _isSandbox = true;

  static String get _baseUrl => _isSandbox
      ? "https://tripay.co.id/api-sandbox"
      : "https://tripay.co.id/api";

  // Helper Headers untuk request bertipe GET
  static Map<String, String> _getHeaders() {
    return {
      "Authorization": "Bearer $apiKey",
      "Accept": "application/json",
    };
  }

  // Helper Headers untuk request bertipe POST (DIKOREKSI: Menambahkan Content-Type JSON)
  static Map<String, String> _postHeaders() {
    return {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  // ===================================================
  // 1. AMBIL DAFTAR PAYMENT CHANNELS AKTIF
  // ===================================================
  /// Mengambil semua saluran pembayaran yang aktif dari Tripay
  Future<List<PaymentChannel>> getPaymentChannels() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/merchant/payment-channel"),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode != 200) {
        final String errMsg = json["message"] ?? "Gagal memuat saluran pembayaran.";
        throw Exception(errMsg);
      }

      final List data = json["data"] ?? [];
      return data.map((e) => PaymentChannel.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) print("Tripay Exception [getPaymentChannels]: $e");
      rethrow;
    }
  }

  // ===================================================
  // 2. GENERATE SIGNATURE TRANSAKSI (SECURE GENERATOR)
  // ===================================================
  /// Membuat signature HMAC-SHA256 validasi keamanan Tripay
  String createSignature(String merchantRef, int amount) {
    final String payload = merchantCode + merchantRef + amount.toString();
    return Hmac(
      sha256,
      utf8.encode(privateKey),
    ).convert(utf8.encode(payload)).toString();
  }

  // ===================================================
  // 3. TERBITKAN INVOICE TRANSAKSI BARU (CREATE TX)
  // ===================================================
  /// Mengirimkan permintaan pembuatan tiket pembayaran baru ke Tripay
  Future<Map<String, dynamic>> createTransaction({
    required String method,
    required String merchantRef,
    required int amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      final String signature = createSignature(merchantRef, amount);

      final response = await http.post(
        Uri.parse("$_baseUrl/transaction/create"),
        headers: _postHeaders(), // DIKOREKSI: Menggunakan header posting lengkap (Content-Type)
        body: jsonEncode({
          "method": method,
          "merchant_ref": merchantRef,
          "amount": amount,
          "customer_name": customerName,
          "customer_email": customerEmail,
          "customer_phone": customerPhone,
          "order_items": [
            {
              "sku": "TOPUP",
              "name": "Top Up Saldo DesaPay",
              "price": amount,
              "quantity": 1,
            }
          ],
          "signature": signature,
        }),
      ).timeout(const Duration(seconds: 25));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode != 200) {
        // REVISI: Mengembalikan keterangan kegagalan spesifik dari API Tripay
        final String detailGagal = responseData["message"] ?? "Gagal membuat invoice transaksi.";
        throw Exception(detailGagal);
      }

      return responseData;
    } catch (e) {
      if (kDebugMode) print("Tripay Exception [createTransaction]: $e");
      rethrow;
    }
  }

  // ===================================================
  // 4. PERIKSA DETAIL STATUS INVOICE (INQUIRY DETAIL)
  // ===================================================
  /// Memeriksa status pembayaran invoice Tripay menggunakan kode referensi transaksi
  Future<Map<String, dynamic>> cekStatus(String reference) async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/transaction/detail?reference=$reference"),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode != 200) {
        final String detailGagal = responseData["message"] ?? "Gagal memuat rincian status.";
        throw Exception(detailGagal);
      }

      return responseData;
    } catch (e) {
      if (kDebugMode) print("Tripay Exception [cekStatus]: $e");
      rethrow;
    }
  }
}
