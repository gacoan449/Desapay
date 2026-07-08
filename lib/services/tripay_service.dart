import 'dart:convert';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import '../models/payment_channel.dart';

class TripayService {

  // Ganti nanti setelah punya akun Tripay
  static const String apiKey = "ISI_API_KEY_DISINI";
  static const String privateKey = "ISI_PRIVATE_KEY_DISINI";
  static const String merchantCode = "ISI_MERCHANT_CODE";
  static const String baseUrl = "https://tripay.co.id/api";

  static Map<String, String> headers() {
    return {
      "Authorization": "Bearer $apiKey",
    };
  }

  static Future<List<dynamic>> getPaymentChannelsLama() async {
    final response = await http.get(
      Uri.parse("$baseUrl/merchant/payment-channel"),
      headers: {
        "Authorization": "Bearer $apiKey",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json["data"];
    }
    return [];
  }

  Future<List<PaymentChannel>> getPaymentChannels() async {
    final response = await http.get(
      Uri.parse("$baseUrl/merchant/payment-channel"),
      headers: headers(),
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal mengambil payment channel");
    }

    final json = jsonDecode(response.body);
    final List data = json["data"];

    return data
        .map((e) => PaymentChannel.fromJson(e))
        .toList();
  }

  String createSignature(String merchantRef, int amount) {
    final payload = merchantCode + merchantRef + amount.toString();

    return Hmac(
      sha256,
      utf8.encode(privateKey),
    ).convert(
      utf8.encode(payload),
    ).toString();
  }

  Future<Map<String, dynamic>> createTransaction({
    required String method,
    required String merchantRef,
    required int amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/transaction/create"),
      headers: headers(),
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

        "signature": createSignature(
          merchantRef,
          amount,
        ),

      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal membuat transaksi");
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> cekStatus(String reference) async {

    final response = await http.get(
      Uri.parse(
        "$baseUrl/transaction/detail?reference=$reference",
      ),
      headers: headers(),
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal mengambil status transaksi");
    }

    return jsonDecode(response.body);
  }

}
