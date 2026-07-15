class Transaksi {
  final String produk;
  final String tujuan;
  final int harga;
  final String status;
  final String tanggal;

  Transaksi({
    required this.produk,
    required this.tujuan,
    required this.harga,
    required this.status,
    required this.tanggal,
  });

  // ===================================================
  // 1. FACTORY FROM JSON (SAFE TYPE-CASTING COMPLIANT)
  // ===================================================
  /// Membuat objek [Transaksi] secara aman dari respons mentah Map/JSON database atau API
  factory Transaksi.fromJson(Map<String, dynamic> json) {
    return Transaksi(
      produk: (json["produk"] ?? json["product_name"] ?? "-").toString(),
      tujuan: (json["tujuan"] ?? json["customer_no"] ?? "-").toString(),
      // DIKOREKSI: Proteksi mutlak tipe data int untuk mencegah error type-casting double/string
      harga: int.tryParse((json["harga"] ?? json["price"] ?? 0).toString()) ?? 0,
      status: (json["status"] ?? "PENDING").toString().toUpperCase(),
      tanggal: (json["tanggal"] ?? json["waktu"] ?? "").toString(),
    );
  }

  // ===================================================
  // 2. TO JSON (UNTUK LOCAL CACHING / FIREBASE WRITING)
  // ===================================================
  /// Mengonversi objek [Transaksi] menjadi format Map/JSON untuk local storage atau database
  Map<String, dynamic> toJson() {
    return {
      "produk": produk,
      "tujuan": tujuan,
      "harga": harga,
      "status": status,
      "tanggal": tanggal,
    };
  }

  // ===================================================
  // 3. COPY WITH HELPER (STATE-MANAGEMENT FRIENDLY)
  // ===================================================
  /// Memudahkan modifikasi parameter objek secara independen tanpa merusak instansi asli
  Transaksi copyWith({
    String? produk,
    String? tujuan,
    int? harga,
    String? status,
    String? tanggal,
  }) {
    return Transaksi(
      produk: produk ?? this.produk,
      tujuan: tujuan ?? this.tujuan,
      harga: harga ?? this.harga,
      status: status ?? this.status,
      tanggal: tanggal ?? this.tanggal,
    );
  }

  // ===================================================
  // 4. TO STRING OVERRIDE (FOR LUXURY DEBUGGING)
  // ===================================================
  @override
  String toString() {
    return 'Transaksi(produk: $produk, tujuan: $tujuan, harga: $harga, status: $status)';
  }
}
