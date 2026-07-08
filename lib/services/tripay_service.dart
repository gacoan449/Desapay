import 'dart:convert';

import 'package:http/http.dart' as http;

class TripayService {

  // Ganti nanti setelah punya akun Tripay
  static const String apiKey = "ISI_API_KEY_DISINI";

  static const String privateKey = "ISI_PRIVATE_KEY_DISINI";

  static const String merchantCode = "ISI_MERCHANT_CODE";

  static const String baseUrl =
      "https://tripay.co.id/api";

  static Future<List<dynamic>> getPaymentChannels() async {

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

}
