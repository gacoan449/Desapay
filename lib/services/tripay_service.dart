import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TriPayService {
  final String _baseUrl = 'https://tripay.co.id/api/transaction/create';

  String _generateSignature(String merchantRef, int amount) {
    final String merchantCode = dotenv.get('TRIPAY_MERCHANT_CODE', fallback: '').trim();
    final String privateKey = dotenv.get('TRIPAY_PRIVATE_KEY', fallback: '').trim();
    final String payload = '$merchantCode$merchantRef$amount';
    
    final List<int> keyBytes = utf8.encode(privateKey);
    final List<int> payloadBytes = utf8.encode(payload);

    final Hmac hmacSha256 = Hmac(sha256, keyBytes);
    return hmacSha256.convert(payloadBytes).toString();
  }

  Future<Map<String, dynamic>?> buatTagihanClosedPayment({
    required String method, 
    required int amount,
    required String namaPelanggan,
    required String emailPelanggan,
    required String nomorHpPelanggan,
    required String namaProduk,
  }) async {
    final String apiKey = dotenv.get('TRIPAY_API_KEY', fallback: '').trim();
    final String merchantRef = 'DP-${DateTime.now().millisecondsSinceEpoch}';
    final String signature = _generateSignature(merchantRef, amount);

    final Map<String, dynamic> bodyPayload = {
      'method': method.trim(),
      'merchant_ref': merchantRef,
      'amount': amount,
      'customer_name': namaPelanggan.trim(),
      'customer_email': emailPelanggan.trim(),
      'customer_phone': nomorHpPelanggan.trim(),
      'order_items': [
        {
          'sku': 'TOPUP',
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
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(bodyPayload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
