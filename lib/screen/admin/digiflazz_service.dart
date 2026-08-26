import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DigiflazzService {
  static const String baseUrl =
      'https://api.digiflazz.com/v1';

  static String get username =>
      dotenv.env['DIGIFLAZZ_USERNAME'] ?? '';

  static String get apiKey =>
      dotenv.env['DIGIFLAZZ_API_KEY'] ?? '';

  static String get sign {
    final raw = '$username$apiKey';

    return md5
        .convert(utf8.encode(raw))
        .toString();
  }

  static Future<Map<String, dynamic>> saldo() async {
    final response = await http.post(
      Uri.parse('$baseUrl/cek-saldo'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cmd': 'deposit',
        'username': username,
        'sign': sign,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> priceList() async {
    final response = await http.post(
      Uri.parse('$baseUrl/price-list'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cmd': 'prepaid',
        'username': username,
        'sign': sign,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> transaction({
    required String refId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transaction'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'commands': 'status',
        'username': username,
        'buyer_sku_code': '',
        'customer_no': '',
        'ref_id': refId,
        'sign': sign,
      }),
    );

    return jsonDecode(response.body);
  }
}
