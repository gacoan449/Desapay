import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Kontrak Layanan Digiflazz Service untuk DesaPay (Domain Layer)
abstract class IDigiflazzService {
  Future<List<dynamic>> ambilSemuaProduk();
  Future<Map<String, dynamic>> kirimTransaksi({
    required String buyerSkuCode,
    required String customerNo,
  });
  Future<Map<String, dynamic>> mintaTiketDeposit({
    required int jumlahNominal,
    required String bank,
    required String namaPemilik,
  });
  Future<Map<String, dynamic>> cekStatusDeposit({
    required int jumlahNominal,
    required String bank,
    required String namaPemilik,
  });
  Future<int> cekSaldoModal();
}

/// Implementasi Layanan Integrasi API Digiflazz (Data Layer - Enterprise Grade)
class DigiflazzService implements IDigiflazzService {
  static const String _baseUrlPriceList = 'https://api.digiflazz.com/v1/price-list';
  static const String _baseUrlTransaction = 'https://api.digiflazz.com/v1/transaction';
  static const String _baseUrlDeposit = 'https://api.digiflazz.com/v1/deposit';
  static const String _baseUrlCekSaldo = 'https://api.digiflazz.com/v1/cek-saldo';

  /// Mengambil data kredensial secara aman dari environment variables (.env)
  String get _username => dotenv.env['DIGIFLAZZ_USERNAME'] ?? '';
  String get _apiKey => dotenv.env['DIGIFLAZZ_API_KEY'] ?? '';

  /// Helper internal untuk melakukan enkripsi MD5 sesuai regulasi Digiflazz
  String _generateSign(String suffix) {
    final String rawString = _username + _apiKey + suffix;
    return md5.convert(utf8.encode(rawString)).toString();
  }

  // ===================================================
  // 3. LOGIKA MARGIN DINAMIS BERDASARKAN KATEGORI PRODUK
  // ===================================================
  int _hitungMarginBerdasarkanKategori(String category) {
    final String cat = category.toLowerCase();
    
    if (cat.contains('angsuran') || cat.contains('multifinance') || cat.contains('finance')) {
      return 3800; // Margin Rp3.500 s.d Rp4.000 (diambil tengah Rp3.800)
    } else if (cat.contains('pln') || cat.contains('pdam') || cat.contains('tagihan')) {
      return 2200; // Margin Rp2.000 s.d Rp2.500 (diambil tengah Rp2.200)
    } else if (cat.contains('pulsa') || cat.contains('data')) {
      return 800;  // Margin Rp500 s.d Rp1.000 (diambil tengah Rp800)
    } else {
      return 1500; // Margin Default kategori lainnya
    }
  }

  // ===================================================
  // 4. VALIDASI SAKELAR MAINTENANCE WAKTU LOKAL
  // ===================================================
  void _validasiJamMaintenance() {
    final int jamSekarang = DateTime.now().hour;
    // Contoh aturan maintenance harian server/operator pukul 23.00 s.d 00.00 WIB
    if (jamSekarang >= 23 && jamSekarang < 24) {
      throw Exception("Sistem sedang dalam jadwal pemeliharaan rutin (Maintenance harian pukul 23:00 - 00:00 WIB). Mohon coba beberapa saat lagi.");
    }
  }

  // ===================================================
  // 1 & 2. AMBIL PRODUK, REKONSILIASI, & ASYMMETRIC PRICING
  // ===================================================
  @override
  Future<List<dynamic>> ambilSemuaProduk() async {
    try {
      final String sign = _generateSign('pricelist');

      final response = await http.post(
        Uri.parse(_baseUrlPriceList),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "cmd": "prepaid",
          "username": _username,
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['data'] != null && data['data'] is List) {
          final List<dynamic> produkAsli = data['data'];

          return produkAsli.map((item) {
            final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
            
            // Harga Modal Asli dari Digiflazz
            final int hargaModal = int.tryParse(itemMap['price'].toString()) ?? 0;
            
            // Ambil kategori produk untuk menentukan margin dinamis
            final String kategori = itemMap['category']?.toString() ?? '';
            final int marginBersih = _hitungMarginBerdasarkanKategori(kategori);

            // 1. SISTEM TALANGAN REKONSILIASI (Harga Jual Bersih Asli)
            final int hargaJualAsli = hargaModal + marginBersih;

            // 2. ASYMMETRIC PRICING & PSIKOLOGI PROMO (Harga Coret Display)
            // Ditambah nominal psikologis Rp4.000 untuk efek dicoret (strikethrough) di UI Flutter
            final int hargaCoretDisplay = hargaJualAsli + 4000;

            // Inject nilai kalkulasi baru ke model data untuk UI
            itemMap['harga_modal'] = hargaModal;
            itemMap['harga_jual_asli'] = hargaJualAsli;
            itemMap['harga_coret_display'] = hargaCoretDisplay;
            
            // Kompatibilitas mundur dengan widget yang memanggil key 'price'
            itemMap['price'] = hargaJualAsli; 

            return itemMap;
          }).toList();
        }
        
        if (data['data'] != null && data['data']['message'] != null) {
          throw Exception(data['data']['message']);
        }
        return [];
      } else {
        throw Exception("Server merespon dengan kode status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Gagal memuat daftar produk Digiflazz: ${e.toString()}");
    }
  }

  // ===================================================
  // 2, 4. TEMBAK TRANSAKSI DENGAN BALANCE GUARD & MAINTENANCE
  // ===================================================
  @override
  Future<Map<String, dynamic>> kirimTransaksi({
    required String buyerSkuCode,
    required String customerNo,
  }) async {
    try {
      // A. Validasi Sakelar Maintenance Waktu Lokal
      _validasiJamMaintenance();

      // B. Ambil daftar produk untuk mencocokkan harga modal produk yang dipilih
      final List<dynamic> semuaProduk = await ambilSemuaProduk();
      final produkDipilih = semuaProduk.firstWhere(
        (p) => p['buyer_sku_code'] == buyerSkuCode,
        orElse: () => null,
      );

      if (produkDipilih == null) {
        return {'status': 'Gagal', 'message': 'Produk tidak ditemukan atau sudah tidak aktif di server.'};
      }

      final int hargaModalProduk = int.tryParse(produkDipilih['harga_modal'].toString()) ?? 0;

      // C. Cek Saldo Pancingan (Balance Guard) di Akun Digiflazz
      final int sisaSaldoModal = await cekSaldoModal();
      if (sisaSaldoModal < hargaModalProduk) {
        // Keamanan cash flow: Gagalkan transaksi agar saldo utama tidak minus/bermasalah
        return {
          'status': 'Gagal', 
          'message': 'Stok sedang kosong, mohon coba beberapa saat lagi'
        };
      }

      // D. Eksekusi Kirim Transaksi API Digiflazz
      final String refId = "DESAPAY-${DateTime.now().millisecondsSinceEpoch}";
      final String sign = _generateSign(refId);

      final response = await http.post(
        Uri.parse(_baseUrlTransaction),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": _username,
          "buyer_sku_code": buyerSkuCode,
          "customer_no": customerNo,
          "ref_id": refId,
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        return {'status': 'Gagal', 'message': 'Format respon data transaksi tidak valid'};
      } else {
        return {'status': 'Gagal', 'message': 'Server transaksi merespon dengan kode: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'Gagal', 'message': 'Terjadi gangguan transaksi: ${e.toString()}'};
    }
  }

  // ===================================================
  // 3. FUNGSI MINTA TIKET DEPOSIT / ISI SALDO AGEN
  // ===================================================
  @override
  Future<Map<String, dynamic>> mintaTiketDeposit({
    required int jumlahNominal,
    required String bank,
    required String namaPemilik,
  }) async {
    try {
      final String sign = _generateSign('deposit');

      final response = await http.post(
        Uri.parse(_baseUrlDeposit),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": _username,
          "amount": jumlahNominal,
          "Bank": bank.toUpperCase(),
          "owner_name": namaPemilik.trim(),
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        return {'status': 'Gagal', 'message': 'Format data tiket deposit tidak sesuai'};
      } else {
        return {'status': 'Gagal', 'message': 'Server deposit merespon dengan kode: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'Gagal', 'message': 'Terjadi masalah jaringan deposit: ${e.toString()}'};
    }
  }

  // ===================================================
  // 4. FUNGSI CEK STATUS TRANSFER DEPOSIT AGEN
  // ===================================================
  @override
  Future<Map<String, dynamic>> cekStatusDeposit({
    required int jumlahNominal,
    required String bank,
    required String namaPemilik,
  }) async {
    try {
      final String sign = _generateSign('deposit');

      final response = await http.post(
        Uri.parse(_baseUrlDeposit),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": _username,
          "amount": jumlahNominal,
          "Bank": bank.toUpperCase(),
          "owner_name": namaPemilik.trim(),
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        return {};
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  // ===================================================
  // 5. FUNGSI CEK SALDO MODAL UTAMA AGEN
  // ===================================================
  @override
  Future<int> cekSaldoModal() async {
    try {
      final String sign = _generateSign('depo');

      final response = await http.post(
        Uri.parse(_baseUrlCekSaldo),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "cmd": "deposit",
          "username": _username,
          "sign": sign
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['deposit'] != null) {
          return int.tryParse(data['data']['deposit'].toString()) ?? 0;
        }
        return 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }
}
