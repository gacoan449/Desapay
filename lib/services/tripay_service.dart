import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Hasil enkapsulasi respons pembuatan tagihan TriPay demi keamanan tipe data di UI
class TriPayInvoiceResult {
  final bool isSukses;
  final String pesan;
  final String? reference;
  final String? merchantRef;
  final String? paymentMethod;
  final String? paymentCode; // Nomor VA atau Kode Bayar Alfamart/Indomaret
  final String? qrUrl;       // Tautan gambar QRIS jika memilih metode QRIS
  final String? qrString;    // String mentah QRIS untuk di-render lokal
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
}

/// Kontrak Abstraksi Layanan Finansial TriPay Gateway DesaPay (Domain Layer)
abstract class ITriPayService {
  Future<TriPayInvoiceResult> buatTagihanClosedPayment({
    required String method,
    required int amount,
    required String namaPelanggan,
    required String emailPelanggan,
    required String nomorHpPelanggan,
    required String namaProduk,
  });

  bool verifikasiCallbackSignature({
    required String rawJsonBody,
    required String remoteSignatureHeader,
  });
}

/// Implementasi Layanan Gerbang Pembayaran TriPay Terikat Sistem Enkripsi (Data Layer)
class TriPayService implements ITriPayService {
  // Menggunakan URL dasar dinamis yang dikonfigurasi via .env (Mendukung transisi Sandbox ke Production)
  String get _baseUrl => dotenv.env['TRIPAY_BASE_URL'] ?? 'https://tripay.co.id/api/transaction/create';
  String get _merchantCode => dotenv.env['TRIPAY_MERCHANT_CODE'] ?? '';
  String get _privateKey => dotenv.env['TRIPAY_PRIVATE_KEY'] ?? '';
  String get _apiKey => dotenv.env['TRIPAY_API_KEY'] ?? '';

  /// Pembuatan Tanda Tangan Digital Kriptografi untuk Validasi Request ke Server TriPay
  String _generateRequestSignature(String merchantRef, int amount) {
    final String payload = '$_merchantCode$merchantRef$amount';
    final List<int> keyBytes = utf8.encode(_privateKey);
    final List<int> payloadBytes = utf8.encode(payload);

    final Hmac hmacSha256 = Hmac(sha256, keyBytes);
    return hmacSha256.convert(payloadBytes).toString();
  }

  // =========================================================================
  // 1. PROSES PEMBUATAN INVOICE / CLOSED PAYMENT (TOP-UP SALDO REAL-TIME)
  // =========================================================================
  @override
  Future<TriPayInvoiceResult> buatTagihanClosedPayment({
    required String method,
    required int amount,
    required String namaPelanggan,
    required String emailPelanggan,
    required String nomorHpPelanggan,
    required String namaProduk,
  }) async {
    // Validasi konfigurasi sistem environment sebelum eksekusi jaringan
    if (_merchantCode.isEmpty || _privateKey.isEmpty || _apiKey.isEmpty) {
      return const TriPayInvoiceResult(
        isSukses: false,
        pesan: "Konfigurasi kredensial Payment Gateway DesaPay belum lengkap.",
      );
    }

    if (amount < 10000) {
      return const TriPayInvoiceResult(
        isSukses: false,
        pesan: "Batas minimum pengisian saldo melalui Payment Gateway adalah Rp 10.000",
      );
    }

    final String merchantRef = 'DP-${DateTime.now().millisecondsSinceEpoch}';
    final String signature = _generateRequestSignature(merchantRef, amount);

    final Map<String, dynamic> bodyPayload = {
      'method': method.trim().toUpperCase(),
      'merchant_ref': merchantRef,
      'amount': amount,
      'customer_name': namaPelanggan.trim(),
      'customer_email': emailPelanggan.trim(),
      'customer_phone': nomorHpPelanggan.trim(),
      'order_items': [
        {
          'sku': 'TOPUP_SALDO',
          'name': namaProduk.trim(),
          'price': amount,
          'quantity': 1,
        }
      ],
      'signature': signature,
    };

    try {
      final http.Response response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(bodyPayload),
      ).timeout(const Duration(seconds: 25));

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(jsonResponse['data'] ?? {});

        return TriPayInvoiceResult(
          isSukses: true,
          pesan: "Tagihan pembayaran berhasil diterbitkan.",
          reference: data['reference']?.toString(),
          merchantRef: data['merchant_ref']?.toString(),
          paymentMethod: data['payment_name']?.toString(),
          paymentCode: data['pay_code']?.toString(),
          qrUrl: data['qr_url']?.toString(),
          qrString: data['qr_string']?.toString(),
          totalAmount: int.tryParse(data['amount'].toString()),
          feeAdmin: int.tryParse(data['total_fee'].toString()),
          expiredTimeTimestamp: int.tryParse(data['expired_time'].toString()),
        );
      } else {
        // Ekstraksi pesan kesalahan spesifik dari server TriPay
        final String pesanGagal = jsonResponse['message'] ?? "Gagal mendapatkan kode pembayaran dari server.";
        return TriPayInvoiceResult(
          isSukses: false,
          pesan: "Respon TriPay: $pesanGagal",
        );
      }
    } catch (e) {
      return TriPayInvoiceResult(
        isSukses: false,
        pesan: "Terjadi kegagalan jaringan saat menghubungi gateway: ${e.toString()}",
      );
    }
  }

  // =========================================================================
  // 2. VERIFIKASI KEASLIAN WEBHOOK CALLBACK (PRODUKSI ANTI FRAUD & ANTI DOUBLE)
  // =========================================================================
  @override
  bool verifikasiCallbackSignature({
    required String rawJsonBody,
    required String remoteSignatureHeader,
  }) {
    if (_privateKey.isEmpty || remoteSignatureHeader.isEmpty || rawJsonBody.isEmpty) {
      return false;
    }

    try {
      // Pembentukan HMAC-SHA256 dari JSON Mentah yang dikirim oleh Webhook TriPay
      final List<int> keyBytes = utf8.encode(_privateKey);
      final List<int> payloadBytes = utf8.encode(rawJsonBody.trim());

      final Hmac hmacSha256 = Hmac(sha256, keyBytes);
      final String computedSignature = hmacSha256.convert(payloadBytes).toString();

      // Membandingkan signature lokal dengan signature yang dikirim pada Header HTTP secara presisi
      return computedSignature == remoteSignatureHeader.trim();
    } catch (_) {
      return false;
    }
  }
}
