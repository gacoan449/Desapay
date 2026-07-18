import 'package:intl/intl.dart';

/// Representasi kategori produk di ekosistem Fintech DesaPay
enum KategoriProduk { pulsa, paketData, tokenPln, eWallet, ppobLainnya }

/// Model Data Objek Produk PPOB DesaPay (Domain & Data Layer)
class Produk {
  final String kode;
  final String nama;
  final int harga;
  final String provider;
  final KategoriProduk kategori;
  final bool tersedia;
  final String deskripsi;

  const Produk({
    required this.kode,
    required this.nama,
    required this.harga,
    this.provider = 'TELKOMSEL',
    this.kategori = KategoriProduk.pulsa,
    this.tersedia = true,
    this.deskripsi = 'Proses instan 24 jam non-stop',
  });

  /// Factory untuk memparsing data JSON ter-markup dari DigiflazzService secara aman
  factory Produk.fromDigiflazz(Map<String, dynamic> json) {
    final String skuCode = json['buyer_sku_code']?.toString() ?? '';
    final String productName = json['product_name']?.toString() ?? 'Produk Tanpa Nama';
    final int mappedPrice = int.tryParse(json['price'].toString()) ?? 0;
    final String brand = (json['brand']?.toString() ?? 'LAINNYA').toUpperCase();
    final bool isAvailable = json['buyer_product_status'] == true && json['seller_product_status'] == true;
    final String desc = json['desc']?.toString() ?? 'Proses instan 24 jam non-stop';

    // Deteksi Kategori Secara Otomatis Berdasarkan Aturan Bisnis Fintech DesaPay
    KategoriProduk detectedCategory = KategoriProduk.pulsa;
    final String lowerSku = skuCode.toLowerCase();
    final String lowerName = productName.toLowerCase();

    if (lowerSku.contains('pln') || lowerName.contains('token') || lowerName.contains('listrik')) {
      detectedCategory = KategoriProduk.tokenPln;
    } else if (lowerSku.contains('data') || lowerSku.contains('paket') || lowerName.contains('kuota')) {
      detectedCategory = KategoriProduk.paketData;
    } else if (lowerSku.contains('gopay') || lowerSku.contains('ovo') || lowerSku.contains('dana') || lowerSku.contains('shopee')) {
      detectedCategory = KategoriProduk.eWallet;
    } else if (lowerSku.contains('pdam') || lowerSku.contains('bpjs') || lowerSku.contains('pasca')) {
      detectedCategory = KategoriProduk.ppobLainnya;
    }

    return Produk(
      kode: skuCode,
      nama: productName,
      harga: mappedPrice,
      provider: brand,
      kategori: detectedCategory,
      tersedia: isAvailable,
      deskripsi: desc,
    );
  }

  /// Menghasilkan representasi teks nominal Rupiah yang rapi dan premium untuk UI
  String get hargaFormatRupiah {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(harga);
  }

  /// Konversi objek model ke Map/JSON untuk penyimpanan lokal / caching
  Map<String, dynamic> toJson() {
    return {
      'kode': kode,
      'nama': nama,
      'harga': harga,
      'provider': provider,
      'kategori': kategori.index,
      'tersedia': tersedia,
      'deskripsi': deskripsi,
    };
  }
}
