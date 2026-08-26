import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;

import '../../config/warna.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _adminTabController;

  // ============================================================
  // CONTROLLER UI
  // ============================================================
  final TextEditingController promoController = TextEditingController();
  final TextEditingController bannerController = TextEditingController();
  final TextEditingController namaMenuController = TextEditingController();
  final TextEditingController ikonController = TextEditingController();

  // ============================================================
  // CONTROLLER MARKUP
  // ============================================================
  final TextEditingController markupPulsaController =
      TextEditingController();
  final TextEditingController markupKuotaController =
      TextEditingController();
  final TextEditingController markupAngsuranController =
      TextEditingController();
  final TextEditingController markupLainnyaController =
      TextEditingController();

  bool _isLoading = false;
  bool _isMaintenance = false;

  // ============================================================
  // PROGRESS
  // ============================================================
  int _excelProgress = 0;
  int _excelTotal = 0;

  int _syncProgress = 0;
  int _syncTotal = 0;

  @override
  void initState() {
    super.initState();

    _adminTabController = TabController(
      length: 5,
      vsync: this,
    );

    _loadInitialConfiguration();
  }

  // ============================================================
  // HELPER FIRESTORE / TYPE SAFETY
  // ============================================================

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  String _toStringValue(
    dynamic value, {
    String fallback = "",
  }) {
    if (value == null) return fallback;

    final String result = value.toString().trim();

    if (result.isEmpty) return fallback;

    return result;
  }

  bool _toBool(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text = value?.toString().trim().toLowerCase() ?? "";

    if (text == "true" ||
        text == "1" ||
        text == "yes" ||
        text == "ya" ||
        text == "aktif") {
      return true;
    }

    if (text == "false" ||
        text == "0" ||
        text == "no" ||
        text == "tidak" ||
        text == "nonaktif") {
      return false;
    }

    return fallback;
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    if (value is num) {
      return value.round();
    }

    String text = value.toString().trim();

    if (text.isEmpty) {
      return 0;
    }

    text = text
        .replaceAll(RegExp(r'(?i)rp'), '')
        .replaceAll(RegExp(r'\s+'), '');

    if (text.isEmpty) {
      return 0;
    }

    // Format Indonesia:
    // 10.000
    // 10.000,50
    // 1.500.000
    //
    // Format umum:
    // 10,000
    // 1,500,000
    //
    // Jika ada titik DAN koma:
    // titik dianggap pemisah ribuan,
    // koma dianggap desimal.
    if (text.contains('.') && text.contains(',')) {
      final int lastDot = text.lastIndexOf('.');
      final int lastComma = text.lastIndexOf(',');

      if (lastComma > lastDot) {
        text = text.replaceAll('.', '').replaceAll(',', '.');

        final double? decimalValue = double.tryParse(text);

        if (decimalValue != null) {
          return decimalValue.round();
        }
      } else {
        text = text.replaceAll(',', '');

        final double? decimalValue = double.tryParse(text);

        if (decimalValue != null) {
          return decimalValue.round();
        }
      }
    } else if (text.contains(',')) {
      final int commaCount = ','.allMatches(text).length;

      if (commaCount > 1) {
        text = text.replaceAll(',', '');

        final int? intValue = int.tryParse(text);

        if (intValue != null) {
          return intValue;
        }
      } else {
        final List<String> parts = text.split(',');

        if (parts.length == 2 && parts[1].length <= 2) {
          final double? decimalValue = double.tryParse(
            text.replaceAll(',', '.'),
          );

          if (decimalValue != null) {
            return decimalValue.round();
          }
        } else {
          text = text.replaceAll(',', '');

          final int? intValue = int.tryParse(text);

          if (intValue != null) {
            return intValue;
          }
        }
      }
    } else if (text.contains('.')) {
      final List<String> parts = text.split('.');

      // 10.000 / 100.000 / 1.500.000
      if (parts.length > 2 ||
          (parts.length == 2 && parts[1].length == 3)) {
        text = text.replaceAll('.', '');

        final int? intValue = int.tryParse(text);

        if (intValue != null) {
          return intValue;
        }
      }
    }

    final int? directInt = int.tryParse(text);

    if (directInt != null) {
      return directInt;
    }

    final double? directDouble = double.tryParse(text);

    if (directDouble != null) {
      return directDouble.round();
    }

    // Ambil hanya angka jika string mengandung simbol lain.
    final String cleaned = text.replaceAll(RegExp(r'[^0-9\-]'), '');

    return int.tryParse(cleaned) ?? 0;
  }

  Timestamp? _toTimestamp(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value;
    }

    if (value is DateTime) {
      return Timestamp.fromDate(value);
    }

    if (value is int) {
      try {
        // Milliseconds sejak epoch.
        return Timestamp.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }

    if (value is double) {
      try {
        return Timestamp.fromMillisecondsSinceEpoch(value.round());
      } catch (_) {
        return null;
      }
    }

    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);

      if (parsed != null) {
        return Timestamp.fromDate(parsed);
      }
    }

    return null;
  }

  String _formatDate(dynamic value) {
    final Timestamp? timestamp = _toTimestamp(value);

    if (timestamp == null) {
      return "-";
    }

    try {
      final DateTime dt = timestamp.toDate();

      return "${dt.day.toString().padLeft(2, '0')}/"
          "${dt.month.toString().padLeft(2, '0')}/"
          "${dt.year} "
          "${dt.hour.toString().padLeft(2, '0')}:"
          "${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "-";
    }
  }

  String _formatCurrency(dynamic value) {
    final int parsed = _toInt(value);

    final bool negative = parsed < 0;
    final String digits = parsed.abs().toString();

    final String formatted = digits.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );

    return negative ? "-$formatted" : formatted;
  }

  // ============================================================
  // INITIAL CONFIGURATION
  // ============================================================

  Future<void> _loadInitialConfiguration() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> docApp =
          await _firestore
              .collection("pengaturan")
              .doc("aplikasi")
              .get();

      if (docApp.exists) {
        final Map<String, dynamic> data = _asMap(docApp.data());

        if (!mounted) return;

        setState(() {
          bannerController.text =
              _toStringValue(data["teksBanner"]);

          promoController.text =
              _toStringValue(data["teksPromo"]);

          _isMaintenance = _toBool(
            data["isMaintenance"],
            fallback: false,
          );
        });
      }

      final DocumentSnapshot<Map<String, dynamic>> docFin =
          await _firestore
              .collection("pengaturan")
              .doc("finansial")
              .get();

      if (docFin.exists) {
        final Map<String, dynamic> data = _asMap(docFin.data());

        if (!mounted) return;

        setState(() {
          markupPulsaController.text =
              _toInt(data["markupPulsa"]).toString();

          markupKuotaController.text =
              _toInt(data["markupKuota"]).toString();

          markupAngsuranController.text =
              _toInt(data["markupAngsuran"]).toString();

          markupLainnyaController.text =
              _toInt(data["markupLainnya"]).toString();
        });
      }
    } catch (e, stackTrace) {
      debugPrint(
        "Gagal memuat konfigurasi admin: $e\n$stackTrace",
      );
    }
  }

  @override
  void dispose() {
    _adminTabController.dispose();

    promoController.dispose();
    bannerController.dispose();
    namaMenuController.dispose();
    ikonController.dispose();

    markupPulsaController.dispose();
    markupKuotaController.dispose();
    markupAngsuranController.dispose();
    markupLainnyaController.dispose();

    super.dispose();
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _tampilkanSnackBar(
    String pesan, {
    required bool isError,
  }) {
    if (!mounted) return;

    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          pesan,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: isError
            ? WarnaDesaPay.danger
            : WarnaDesaPay.success,
      ),
    );
  }

  // ============================================================
  // MAINTENANCE
  // ============================================================

  Future<void> _toggleMaintenance(bool value) async {
    if (!mounted) return;

    final bool oldValue = _isMaintenance;

    setState(() {
      _isMaintenance = value;
    });

    try {
      await _firestore
          .collection("pengaturan")
          .doc("aplikasi")
          .set(
        {
          "isMaintenance": value,
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _tampilkanSnackBar(
        value
            ? "Mode Maintenance AKTIF! User tidak bisa masuk."
            : "Mode Maintenance DIMATIKAN! Aplikasi normal.",
        isError: value,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMaintenance = oldValue;
        });
      }

      _tampilkanSnackBar(
        "Gagal mengubah status maintenance: $e",
        isError: true,
      );
    }
  }

  // ============================================================
  // KONTEN UI
  // ============================================================

  Future<void> _simpanPerubahanPromo() async {
    final String promo = promoController.text.trim();
    final String banner = bannerController.text.trim();

    if (promo.isEmpty || banner.isEmpty) {
      _tampilkanSnackBar(
        "Teks banner dan promo tidak boleh kosong.",
        isError: true,
      );
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore
          .collection("pengaturan")
          .doc("aplikasi")
          .set(
        {
          "teksPromo": promo,
          "teksBanner": banner,
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _tampilkanSnackBar(
        "Konfigurasi UI berhasil diperbarui!",
        isError: false,
      );
    } catch (e) {
      _tampilkanSnackBar(
        "Gagal memperbarui UI: $e",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // MARKUP
  // ============================================================

  Future<Map<String, int>> _ambilSemuaMarkup() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore
              .collection("pengaturan")
              .doc("finansial")
              .get();

      if (!doc.exists) {
        return {
          "pulsa": 0,
          "kuota": 0,
          "angsuran": 0,
          "lainnya": 0,
        };
      }

      final Map<String, dynamic> data = _asMap(doc.data());

      return {
        "pulsa": _toInt(data["markupPulsa"]),
        "kuota": _toInt(data["markupKuota"]),
        "angsuran": _toInt(data["markupAngsuran"]),
        "lainnya": _toInt(data["markupLainnya"]),
      };
    } catch (e) {
      debugPrint("Gagal mengambil markup: $e");

      rethrow;
    }
  }

  Future<void> _simpanSemuaMarkup() async {
    if (_isLoading) return;

    final int? pulsa =
        int.tryParse(markupPulsaController.text.trim());

    final int? kuota =
        int.tryParse(markupKuotaController.text.trim());

    final int? angsuran =
        int.tryParse(markupAngsuranController.text.trim());

    final int? lainnya =
        int.tryParse(markupLainnyaController.text.trim());

    if (pulsa == null ||
        kuota == null ||
        angsuran == null ||
        lainnya == null ||
        pulsa < 0 ||
        kuota < 0 ||
        angsuran < 0 ||
        lainnya < 0) {
      _tampilkanSnackBar(
        "Semua markup harus berupa angka 0 atau lebih.",
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore
          .collection("pengaturan")
          .doc("finansial")
          .set(
        {
          "markupPulsa": pulsa,
          "markupKuota": kuota,
          "markupAngsuran": angsuran,
          "markupLainnya": lainnya,
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _tampilkanSnackBar(
        "Markup semua kategori berhasil disimpan.",
        isError: false,
      );
    } catch (e) {
      _tampilkanSnackBar(
        "Gagal menyimpan markup: $e",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _tentukanKategoriProduk(
    Map<String, dynamic> produk,
  ) {
    final String kategori = _toStringValue(
      produk["category"] ?? produk["kategori"],
    ).toLowerCase();

    final String nama = _toStringValue(
      produk["product_name"] ??
          produk["nama_produk"] ??
          produk["produk"] ??
          produk["nama"],
    ).toLowerCase();

    final String brand = _toStringValue(
      produk["brand"] ??
          produk["provider"] ??
          produk["operator"],
    ).toLowerCase();

    final String sku = _toStringValue(
      produk["buyer_sku_code"] ??
          produk["sku"] ??
          produk["kode_produk"] ??
          produk["kode_sku"],
    ).toLowerCase();

    final String gabungan =
        "$kategori $nama $brand $sku";

    if (gabungan.contains("angsuran") ||
        gabungan.contains("cicilan") ||
        gabungan.contains("kredit") ||
        gabungan.contains("finance") ||
        gabungan.contains("multifinance") ||
        gabungan.contains("leasing") ||
        gabungan.contains("angs")) {
      return "angsuran";
    }

    if (gabungan.contains("kuota") ||
        gabungan.contains("quota") ||
        gabungan.contains("data") ||
        gabungan.contains("internet") ||
        gabungan.contains("paket data") ||
        gabungan.contains("combo") ||
        gabungan.contains("internetan")) {
      return "kuota";
    }

    if (gabungan.contains("pulsa") ||
        gabungan.contains("voucher pulsa") ||
        gabungan.contains("pulsa reguler") ||
        gabungan.contains("regular") ||
        gabungan.contains("reguler")) {
      return "pulsa";
    }

    return "lainnya";
  }

  int _markupUntukKategori(
    String kategori,
    Map<String, int> markup,
  ) {
    switch (kategori) {
      case "pulsa":
        return markup["pulsa"] ?? 0;

      case "kuota":
        return markup["kuota"] ?? 0;

      case "angsuran":
        return markup["angsuran"] ?? 0;

      default:
        return markup["lainnya"] ?? 0;
    }
  }

  // ============================================================
  // EXCEL
  // ============================================================

  Future<void> _uploadExcelProduk() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _excelProgress = 0;
      _excelTotal = 0;
    });

    try {
      final FilePickerResult? result =
          await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["xlsx", "xls"],
        withData: true,
      );

      if (result == null) {
        return;
      }

      final PlatformFile file = result.files.single;

      if (file.bytes == null) {
        throw Exception(
          "Data file Excel tidak dapat dibaca.",
        );
      }

      final Uint8List bytes = file.bytes!;

      late excel_lib.Excel excel;

      try {
        excel = excel_lib.Excel.decodeBytes(bytes);
      } catch (e) {
        throw Exception(
          "File Excel tidak dapat dibaca. Pastikan file XLS/XLSX valid. Detail: $e",
        );
      }

      if (excel.tables.isEmpty) {
        throw Exception(
          "File Excel tidak memiliki sheet.",
        );
      }

      final String sheetName = excel.tables.keys.first;

      final excel_lib.Sheet? sheet =
          excel.tables[sheetName];

      if (sheet == null) {
        throw Exception(
          "Sheet Excel tidak ditemukan.",
        );
      }

      if (sheet.maxRows < 2) {
        throw Exception(
          "Excel tidak memiliki data produk.",
        );
      }

      final List<dynamic> headerRow =
          sheet.rows.isNotEmpty
              ? sheet.rows.first
              : <dynamic>[];

      final List<String> headers = headerRow
          .map(
            (cell) => _normalisasiHeader(
              cell?.value?.toString() ?? "",
            ),
          )
          .toList();

      if (headers.isEmpty ||
          headers.every((header) => header.isEmpty)) {
        throw Exception(
          "Header Excel tidak ditemukan.",
        );
      }

      final Map<String, int> semuaMarkup =
          await _ambilSemuaMarkup();

      final List<Map<String, dynamic>> produkList =
          <Map<String, dynamic>>[];

      int jumlahGagal = 0;

      for (int rowIndex = 1;
          rowIndex < sheet.maxRows;
          rowIndex++) {
        try {
          final List<dynamic> row =
              sheet.rows[rowIndex];

          if (_barisKosong(row)) {
            continue;
          }

          final Map<String, dynamic> produk =
              <String, dynamic>{};

          for (int columnIndex = 0;
              columnIndex < headers.length;
              columnIndex++) {
            if (columnIndex >= row.length) {
              continue;
            }

            final String header =
                headers[columnIndex];

            if (header.isEmpty) {
              continue;
            }

            final dynamic cell =
                row[columnIndex];

            final dynamic cleaned =
                _bersihkanNilaiExcel(
              cell?.value,
            );

            if (cleaned != null) {
              produk[header] = cleaned;
            }
          }

          if (produk.isEmpty) {
            jumlahGagal++;
            continue;
          }

          final String sku =
              _ambilSKU(produk);

          if (sku.isEmpty) {
            jumlahGagal++;
            continue;
          }

          final int hargaBeli =
              _ambilHargaProduk(produk);

          if (hargaBeli <= 0) {
            jumlahGagal++;
            continue;
          }

          produk["buyer_sku_code"] = sku;
          produk["hargaBeli"] = hargaBeli;

          if (!produk.containsKey("price") ||
              _toInt(produk["price"]) <= 0) {
            produk["price"] = hargaBeli;
          }

          final String kategori =
              _tentukanKategoriProduk(produk);

          final int markup =
              _markupUntukKategori(
            kategori,
            semuaMarkup,
          );

          final int hargaJual =
              hargaBeli + markup;

          produk["jenisLayanan"] = kategori;
          produk["markup"] = markup;
          produk["hargaJual"] = hargaJual;

          if (!produk.containsKey("isAktif")) {
            produk["isAktif"] = true;
          } else {
            produk["isAktif"] =
                _toBool(
              produk["isAktif"],
              fallback: true,
            );
          }

          if (!produk.containsKey("status") ||
              _toStringValue(
                produk["status"],
              ).isEmpty) {
            produk["status"] = "aktif";
          }

          produk["source"] = "excel";
          produk["importedAt"] =
              FieldValue.serverTimestamp();
          produk["updatedAt"] =
              FieldValue.serverTimestamp();

          produkList.add(produk);
        } catch (e, stackTrace) {
          debugPrint(
            "Gagal membaca baris Excel $rowIndex: "
            "$e\n$stackTrace",
          );

          jumlahGagal++;
        }
      }

      if (produkList.isEmpty) {
        throw Exception(
          "Tidak ada produk valid yang ditemukan.",
        );
      }

      if (mounted) {
        setState(() {
          _excelTotal = produkList.length;
          _excelProgress = 0;
        });
      }

      // Di bawah 500 operasi Firestore.
      const int batchSize = 450;

      int totalTersimpan = 0;

      for (int i = 0;
          i < produkList.length;
          i += batchSize) {
        final int end =
            (i + batchSize < produkList.length)
                ? i + batchSize
                : produkList.length;

        final List<Map<String, dynamic>> batchData =
            produkList.sublist(i, end);

        final WriteBatch batch =
            _firestore.batch();

        for (final Map<String, dynamic> produk
            in batchData) {
          final String sku =
              _toStringValue(
            produk["buyer_sku_code"],
          ).trim();

          if (sku.isEmpty) {
            continue;
          }

          final DocumentReference<Map<String, dynamic>>
              ref = _firestore
                  .collection("produk")
                  .doc(sku);

          batch.set(
            ref,
            produk,
            SetOptions(merge: true),
          );
        }

        await batch.commit();

        totalTersimpan += batchData.length;

        if (mounted) {
          setState(() {
            _excelProgress = totalTersimpan;
          });
        }
      }

      _tampilkanSnackBar(
        "Upload selesai! $totalTersimpan produk berhasil disimpan. "
        "$jumlahGagal baris dilewati.",
        isError: false,
      );
    } catch (e, stackTrace) {
      debugPrint(
        "UPLOAD EXCEL ERROR: $e\n$stackTrace",
      );

      _tampilkanSnackBar(
        "Gagal upload Excel: $e",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _ambilSKU(
    Map<String, dynamic> produk,
  ) {
    final List<dynamic> kandidat = [
      produk["buyer_sku_code"],
      produk["sku"],
      produk["kode_produk"],
      produk["kode_sku"],
      produk["product_code"],
      produk["kode"],
    ];

    for (final dynamic item in kandidat) {
      final String value =
          _toStringValue(item).trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    return "";
  }

  int _ambilHargaProduk(
    Map<String, dynamic> produk,
  ) {
    // Prioritas hargaBeli harus paling tinggi.
    final List<dynamic> kandidatHargaBeli = [
      produk["hargaBeli"],
      produk["harga_beli"],
      produk["buy_price"],
      produk["purchase_price"],
      produk["cost_price"],
    ];

    for (final dynamic item in kandidatHargaBeli) {
      final int value = _toInt(item);

      if (value > 0) {
        return value;
      }
    }

    // Hanya gunakan price jika hargaBeli memang tidak tersedia.
    final List<dynamic> kandidatHargaLain = [
      produk["price"],
      produk["harga"],
      produk["selling_price"],
    ];

    for (final dynamic item in kandidatHargaLain) {
      final int value = _toInt(item);

      if (value > 0) {
        return value;
      }
    }

    return 0;
  }

  String _normalisasiHeader(String value) {
    String hasil =
        value.trim().toLowerCase();

    hasil = hasil
        .replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        )
        .replaceAll(
          RegExp(r'_+'),
          '_',
        )
        .replaceAll(
          RegExp(r'^_|_$'),
          '',
        );

    switch (hasil) {
      case "nama_produk":
      case "nama_product":
      case "nama":
      case "produk":
      case "product":
      case "product_name":
        return "product_name";

      case "deskripsi":
      case "deskripsi_produk":
      case "description":
        return "description";

      case "harga":
      case "price":
      case "harga_jual":
      case "harga_produk":
        return "price";

      case "harga_beli":
      case "harga_modal":
      case "modal":
      case "buy_price":
      case "purchase_price":
        return "hargaBeli";

      case "kode_produk":
      case "kode_sku":
      case "sku":
      case "buyer_sku":
      case "buyer_sku_code":
      case "product_code":
        return "buyer_sku_code";

      case "kategori":
      case "nama_kategori":
      case "category":
        return "category";

      case "status_produk":
      case "status":
        return "status";

      case "nomor":
      case "nomor_tujuan":
      case "customer_no":
      case "customer_number":
        return "customer_no";

      case "provider":
      case "operator":
      case "brand":
        return "brand";

      case "aktif":
      case "is_aktif":
      case "isaktif":
      case "active":
        return "isAktif";

      default:
        return hasil;
    }
  }

  dynamic _bersihkanNilaiExcel(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      // Nilai numerik dari Excel dipertahankan sebagai num.
      // Jika nanti digunakan sebagai harga, _toInt akan membulatkan.
      return value;
    }

    if (value is num) {
      return value;
    }

    String text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    final String lower =
        text.toLowerCase();

    if (lower == "true" ||
        lower == "yes" ||
        lower == "ya" ||
        lower == "aktif") {
      return true;
    }

    if (lower == "false" ||
        lower == "no" ||
        lower == "tidak" ||
        lower == "nonaktif") {
      return false;
    }

    String angka = text
        .replaceAll(
          RegExp(r'(?i)rp'),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          '',
        );

    if (angka.isEmpty) {
      return null;
    }

    // Format Indonesia:
    // 10.000
    // 10.000,50
    if (angka.contains('.') &&
        angka.contains(',')) {
      final int lastDot =
          angka.lastIndexOf('.');

      final int lastComma =
          angka.lastIndexOf(',');

      if (lastComma > lastDot) {
        angka = angka
            .replaceAll('.', '')
            .replaceAll(',', '.');

        final double? valueDouble =
            double.tryParse(angka);

        if (valueDouble != null) {
          return valueDouble;
        }
      } else {
        angka = angka.replaceAll(',', '');

        final double? valueDouble =
            double.tryParse(angka);

        if (valueDouble != null) {
          return valueDouble;
        }
      }
    } else if (angka.contains(',')) {
      final List<String> parts =
          angka.split(',');

      if (parts.length == 2 &&
          parts[1].length <= 2) {
        final double? valueDouble =
            double.tryParse(
          angka.replaceAll(',', '.'),
        );

        if (valueDouble != null) {
          return valueDouble;
        }
      }

      final int? valueInt =
          int.tryParse(
        angka.replaceAll(',', ''),
      );

      if (valueInt != null) {
        return valueInt;
      }
    } else if (angka.contains('.')) {
      final List<String> parts =
          angka.split('.');

      if (parts.length > 2 ||
          (parts.length == 2 &&
              parts[1].length == 3)) {
        final int? valueInt =
            int.tryParse(
          angka.replaceAll('.', ''),
        );

        if (valueInt != null) {
          return valueInt;
        }
      }
    }

    final int? intValue =
        int.tryParse(angka);

    if (intValue != null) {
      return intValue;
    }

    final double? doubleValue =
        double.tryParse(angka);

    if (doubleValue != null) {
      return doubleValue;
    }

    return text;
  }

  bool _barisKosong(
    List<dynamic> row,
  ) {
    for (final dynamic cell in row) {
      final dynamic value =
          cell?.value;

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // TERAPKAN MARKUP KE SEMUA PRODUK
  // ============================================================

  Future<void> _terapkanMarkupKeSemuaProduk() async {
    if (_isLoading) return;

    final bool? konfirmasi =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            "Terapkan Markup?",
          ),
          content: const Text(
            "Semua produk di Firestore akan dihitung ulang "
            "berdasarkan jenis layanan.\n\n"
            "Pulsa, Kuota, Angsuran dan Lainnya akan "
            "menggunakan markup masing-masing.",
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text("TERAPKAN"),
            ),
          ],
        );
      },
    );

    if (konfirmasi != true) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _syncProgress = 0;
      _syncTotal = 0;
    });

    try {
      final Map<String, int> semuaMarkup =
          await _ambilSemuaMarkup();

      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await _firestore
              .collection("produk")
              .get();

      final List<QueryDocumentSnapshot<Map<String, dynamic>>>
          docs = snapshot.docs;

      if (mounted) {
        setState(() {
          _syncTotal = docs.length;
        });
      }

      const int batchSize = 450;

      int totalUpdate = 0;

      for (int i = 0;
          i < docs.length;
          i += batchSize) {
        final int end =
            (i + batchSize < docs.length)
                ? i + batchSize
                : docs.length;

        final WriteBatch batch =
            _firestore.batch();

        for (int j = i;
            j < end;
            j++) {
          final QueryDocumentSnapshot<Map<String, dynamic>>
              doc = docs[j];

          final Map<String, dynamic> data =
              _asMap(doc.data());

          final String kategori =
              _tentukanKategoriProduk(data);

          int hargaBeli =
              _toInt(data["hargaBeli"]);

          if (hargaBeli <= 0) {
            hargaBeli = _toInt(
              data["harga_beli"],
            );
          }

          if (hargaBeli <= 0) {
            hargaBeli = _toInt(
              data["buy_price"],
            );
          }

          if (hargaBeli <= 0) {
            hargaBeli = _toInt(
              data["price"],
            );
          }

          final int markup =
              _markupUntukKategori(
            kategori,
            semuaMarkup,
          );

          final int hargaJual =
              hargaBeli + markup;

          batch.update(
            doc.reference,
            {
              "hargaBeli": hargaBeli,
              "jenisLayanan": kategori,
              "markup": markup,
              "hargaJual": hargaJual,
              "updatedAt":
                  FieldValue.serverTimestamp(),
            },
          );
        }

        await batch.commit();

        totalUpdate += end - i;

        if (mounted) {
          setState(() {
            _syncProgress = totalUpdate;
          });
        }
      }

      _tampilkanSnackBar(
        "$totalUpdate produk berhasil diperbarui "
        "dengan markup terbaru.",
        isError: false,
      );
    } catch (e, stackTrace) {
      debugPrint(
        "SYNC MARKUP ERROR: $e\n$stackTrace",
      );

      _tampilkanSnackBar(
        "Gagal menerapkan markup: $e",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD UTAMA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.darkCard,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "HQ Command Center",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "DesaPay Administrator Mode",
              style: TextStyle(
                fontSize: 11,
                color: WarnaDesaPay.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: () =>
              Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(48),
          child: Container(
            color: WarnaDesaPay.darkBg,
            child: TabBar(
              controller:
                  _adminTabController,
              isScrollable: true,
              indicatorColor:
                  WarnaDesaPay.warning,
              indicatorWeight: 3,
              labelColor:
                  WarnaDesaPay.warning,
              unselectedLabelColor:
                  WarnaDesaPay.textSub,
              labelStyle:
                  const TextStyle(
                fontWeight:
                    FontWeight.w800,
                fontSize: 12,
              ),
              tabs: const [
                Tab(
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 18,
                  ),
                  text: "KONTEN UI",
                ),
                Tab(
                  icon: Icon(
                    Icons.people_alt_rounded,
                    size: 18,
                  ),
                  text: "PENGGUNA",
                ),
                Tab(
                  icon: Icon(
                    Icons
                        .account_balance_wallet_rounded,
                    size: 18,
                  ),
                  text: "KEUANGAN",
                ),
                Tab(
                  icon: Icon(
                    Icons.security_rounded,
                    size: 18,
                  ),
                  text: "SISTEM",
                ),
                Tab(
                  icon: Icon(
                    Icons.support_agent_rounded,
                    size: 18,
                  ),
                  text: "TIKET CS",
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller:
            _adminTabController,
        physics:
            const BouncingScrollPhysics(),
        children: [
          _buildPanelKontenUI(),
          _buildPanelPengguna(),
          _buildPanelKeuangan(),
          _buildPanelSistem(),
          _buildPanelTiketCS(),
        ],
      ),
    );
  }

  // ============================================================
  // PANEL KONTEN UI
  // ============================================================

  Widget _buildPanelKontenUI() {
    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  WarnaDesaPay.lightCard,
              borderRadius:
                  BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: WarnaDesaPay.shadow
                      .withOpacity(0.05),
                  blurRadius: 14,
                  offset:
                      const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons
                          .amp_stories_rounded,
                      color:
                          WarnaDesaPay.warning,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Kampanye & Teks Berjalan",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            WarnaDesaPay.textMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                _buildModernInput(
                  context: context,
                  controller:
                      bannerController,
                  label:
                      "Teks Pengumuman Header",
                  hint:
                      "Tulis pengumuman...",
                ),
                const SizedBox(
                  height: 16,
                ),
                _buildModernInput(
                  context: context,
                  controller:
                      promoController,
                  label:
                      "Teks Ticker Beranda",
                  hint:
                      "Tulis promo berjalan...",
                ),
                const SizedBox(
                  height: 24,
                ),
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : _simpanPerubahanPromo,
                  child: Container(
                    width:
                        double.infinity,
                    height: 50,
                    decoration:
                        BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          WarnaDesaPay
                              .warning,
                          Color(
                            0xFFD97706,
                          ),
                        ],
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(14),
                    ),
                    alignment:
                        Alignment.center,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color:
                                Colors.white,
                          )
                        : const Text(
                            "UPDATE REALTIME PLATFORM",
                            style: TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight
                                      .w900,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            padding:
                const EdgeInsets.all(20),
            decoration:
                BoxDecoration(
              color:
                  WarnaDesaPay.lightCard,
              borderRadius:
                  BorderRadius.circular(24),
              border: Border.all(
                color: WarnaDesaPay.primary
                    .withOpacity(0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons
                          .upload_file_rounded,
                      color:
                          WarnaDesaPay.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Import Produk Excel",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "Upload produk Digiflazz atau format DesaPay. "
                  "Harga jual otomatis mengikuti markup Pulsa, "
                  "Kuota, Angsuran atau Lainnya.",
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        WarnaDesaPay.textSub,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Container(
                  padding:
                      const EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(
                    color:
                        WarnaDesaPay.primary
                            .withOpacity(
                                0.06),
                    borderRadius:
                        BorderRadius
                            .circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Icon(
                        Icons
                            .info_outline_rounded,
                        size: 18,
                        color:
                            WarnaDesaPay.primary,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          "SKU digunakan sebagai ID dokumen. "
                          "Sistem akan mendeteksi jenis layanan "
                          "dan menghitung harga jual otomatis.",
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                WarnaDesaPay
                                    .textSub,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                if (_isLoading &&
                    _excelTotal > 0)
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      LinearProgressIndicator(
                        value: _excelTotal >
                                0
                            ? (_excelProgress /
                                    _excelTotal)
                                .clamp(
                                    0.0,
                                    1.0)
                            : 0,
                        minHeight: 7,
                        borderRadius:
                            BorderRadius
                                .circular(
                                    10),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        "Memasukkan "
                        "$_excelProgress / "
                        "$_excelTotal produk...",
                        style:
                            const TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color:
                              WarnaDesaPay
                                  .primary,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                    ],
                  ),
                SizedBox(
                  width:
                      double.infinity,
                  height: 50,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _isLoading
                            ? null
                            : _uploadExcelProduk,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .file_upload_rounded,
                          ),
                    label: Text(
                      _isLoading
                          ? "MEMPROSES EXCEL..."
                          : "UPLOAD EXCEL PRODUK",
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .w900,
                        fontSize: 13,
                      ),
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          WarnaDesaPay
                              .primary,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 32,
          ),
          const Text(
            "Manajemen Modul Layanan",
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w800,
              color:
                  WarnaDesaPay.textMain,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream: _firestore
                .collection(
                    "menu_layanan")
                .orderBy("urutan")
                .snapshots(),
            builder:
                (context, snapshot) {
              if (snapshot
                      .connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.all(
                            20),
                    child:
                        CircularProgressIndicator(
                      color:
                          WarnaDesaPay
                              .primary,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorMessage(
                  "Gagal memuat menu layanan: "
                  "${snapshot.error}",
                );
              }

              final List<
                      QueryDocumentSnapshot<
                          Map<String, dynamic>>>
                  docs =
                  snapshot.data?.docs ??
                      [];

              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.all(
                            20),
                    child: Text(
                      "Belum ada menu custom yang dibuat.",
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount:
                    docs.length,
                itemBuilder:
                    (context, index) {
                  final QueryDocumentSnapshot<
                          Map<String, dynamic>>
                      doc =
                      docs[index];

                  final Map<String,
                          dynamic>
                      item =
                      _asMap(
                    doc.data(),
                  );

                  final String id =
                      _toStringValue(
                    item["id"],
                    fallback:
                        doc.id,
                  );

                  final String nama =
                      _toStringValue(
                    item["nama"],
                    fallback:
                        "Menu Tanpa Nama",
                  );

                  final bool isAktif =
                      _toBool(
                    item["isAktif"],
                    fallback:
                        false,
                  );

                  return Container(
                    margin:
                        const EdgeInsets
                            .only(
                      bottom: 12,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          WarnaDesaPay
                              .lightCard,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  16),
                      border:
                          Border.all(
                        color:
                            WarnaDesaPay
                                .lightField,
                      ),
                    ),
                    child: ListTile(
                      leading:
                          const Icon(
                        Icons
                            .grid_view_rounded,
                        color:
                            WarnaDesaPay
                                .primary,
                      ),
                      title: Text(
                        nama,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
                      subtitle:
                          Text(
                        "ID Modul: $id",
                        style:
                            const TextStyle(
                          fontSize: 11,
                        ),
                      ),
                      trailing:
                          Switch.adaptive(
                        value:
                            isAktif,
                        activeColor:
                            WarnaDesaPay
                                .success,
                        onChanged:
                            (bool val) async {
                          try {
                            await _firestore
                                .collection(
                                    "menu_layanan")
                                .doc(
                                    doc.id)
                                .update({
                              "isAktif":
                                  val,
                              "updatedAt":
                                  FieldValue
                                      .serverTimestamp(),
                            });
                          } catch (e) {
                            _tampilkanSnackBar(
                              "Gagal mengubah status menu: $e",
                              isError:
                                  true,
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PANEL PENGGUNA
  // ============================================================

  Widget _buildPanelPengguna() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection("users")
          .orderBy(
            "createdAt",
            descending: true,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot
                .connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(
              color:
                  WarnaDesaPay.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorMessage(
            "Gagal memuat pengguna: "
            "${snapshot.error}",
          );
        }

        final List<
                QueryDocumentSnapshot<
                    Map<String, dynamic>>>
            docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada pengguna terdaftar.",
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder:
              (context, index) {
            final QueryDocumentSnapshot<
                    Map<String, dynamic>>
                doc =
                docs[index];

            final Map<String, dynamic>
                user =
                _asMap(doc.data());

            final String userId =
                doc.id;

            final bool isBlocked =
                _toBool(
              user["isBlocked"],
              fallback:
                  false,
            );

            final String kycStatus =
                _toStringValue(
              user["kycStatus"],
              fallback:
                  "Belum",
            );

            final String tipeAkun =
                _toStringValue(
              user["tipeAkun"],
              fallback:
                  "Basic",
            );

            final String nama =
                _toStringValue(
              user["nama"],
              fallback:
                  "User Tanpa Nama",
            );

            final String email =
                _toStringValue(
              user["email"],
              fallback: "-",
            );

            final String fotoProfil =
                _toStringValue(
              user["fotoProfil"],
            );

            return Container(
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              padding:
                  const EdgeInsets.all(
                      16),
              decoration:
                  BoxDecoration(
                color: isBlocked
                    ? WarnaDesaPay
                        .danger
                        .withOpacity(
                            0.05)
                    : WarnaDesaPay
                        .lightCard,
                borderRadius:
                    BorderRadius.circular(
                        16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            WarnaDesaPay
                                .primary
                                .withOpacity(
                                    0.1),
                        backgroundImage:
                            fotoProfil
                                    .isNotEmpty
                                ? NetworkImage(
                                    fotoProfil)
                                : null,
                        child: fotoProfil
                                .isEmpty
                            ? const Icon(
                                Icons
                                    .person,
                                color:
                                    WarnaDesaPay
                                        .primary,
                              )
                            : null,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              nama,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            Text(
                              email,
                              style:
                                  const TextStyle(
                                fontSize:
                                    11,
                                color:
                                    WarnaDesaPay
                                        .textSub,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              tipeAkun
                                  .toUpperCase(),
                              style:
                                  TextStyle(
                                fontSize:
                                    9,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color: tipeAkun
                                            .toLowerCase() ==
                                        "premium"
                                    ? WarnaDesaPay
                                        .warning
                                    : Colors
                                        .grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value:
                            !isBlocked,
                        activeColor:
                            WarnaDesaPay
                                .success,
                        onChanged:
                            (bool val) async {
                          try {
                            await _firestore
                                .collection(
                                    "users")
                                .doc(
                                    userId)
                                .update({
                              "isBlocked":
                                  !val,
                              "updatedAt":
                                  FieldValue
                                      .serverTimestamp(),
                            });
                          } catch (e) {
                            _tampilkanSnackBar(
                              "Gagal mengubah status akun: $e",
                              isError:
                                  true,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(
                    height: 24,
                  ),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "Saldo: Rp ${_formatCurrency(user["saldo"])}",
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w900,
                            color:
                                WarnaDesaPay
                                    .primary,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      if (kycStatus
                              .toLowerCase() ==
                          "pending")
                        ElevatedButton.icon(
                          icon:
                              const Icon(
                            Icons
                                .verified_user_rounded,
                            size: 14,
                          ),
                          label:
                              const Text(
                            "Cek KYC",
                            style:
                                TextStyle(
                              fontSize:
                                  11,
                            ),
                          ),
                          onPressed: () =>
                              _tampilkanDialogReviewKYC(
                            userId,
                            nama,
                            _toStringValue(
                              user[
                                  "fotoKtp"],
                            ),
                            _toStringValue(
                              user[
                                  "fotoSelfie"],
                            ),
                          ),
                        )
                      else
                        TextButton.icon(
                          icon:
                              const Icon(
                            Icons
                                .edit_note_rounded,
                            size: 16,
                          ),
                          label:
                              const Text(
                            "Edit Saldo",
                          ),
                          onPressed: () =>
                              _tampilkanDialogEditSaldo(
                            userId,
                            _toInt(
                              user[
                                  "saldo"],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // KYC
  // ============================================================

  Future<void> _tampilkanDialogReviewKYC(
    String userId,
    String nama,
    String fotoKtp,
    String fotoSelfie,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Review Dokumen KYC\n$nama",
            textAlign:
                TextAlign.center,
          ),
          content:
              SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  "Foto KTP",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Container(
                  height: 150,
                  width:
                      double.infinity,
                  color:
                      Colors.grey.shade200,
                  child: fotoKtp
                          .isNotEmpty
                      ? Image.network(
                          fotoKtp,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Center(
                              child: Text(
                                "Gambar KTP tidak dapat dimuat",
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            "Tidak ada gambar KTP",
                          ),
                        ),
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  "Foto Selfie dengan KTP",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Container(
                  height: 150,
                  width:
                      double.infinity,
                  color:
                      Colors.grey.shade200,
                  child: fotoSelfie
                          .isNotEmpty
                      ? Image.network(
                          fotoSelfie,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Center(
                              child: Text(
                                "Gambar selfie tidak dapat dimuat",
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            "Tidak ada gambar selfie",
                          ),
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await _firestore
                      .collection("users")
                      .doc(userId)
                      .update({
                    "kycStatus":
                        "Ditolak",
                    "updatedAt":
                        FieldValue
                            .serverTimestamp(),
                  });

                  if (dialogContext
                      .mounted) {
                    Navigator.pop(
                      dialogContext,
                    );
                  }

                  _tampilkanSnackBar(
                    "Dokumen ditolak.",
                    isError: true,
                  );
                } catch (e) {
                  _tampilkanSnackBar(
                    "Gagal menolak KYC: $e",
                    isError: true,
                  );
                }
              },
              child: const Text(
                "Tolak",
                style: TextStyle(
                  color:
                      WarnaDesaPay.danger,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestore
                      .collection("users")
                      .doc(userId)
                      .update({
                    "kycStatus":
                        "Terverifikasi",
                    "tipeAkun":
                        "Premium",
                    "updatedAt":
                        FieldValue
                            .serverTimestamp(),
                  });

                  if (dialogContext
                      .mounted) {
                    Navigator.pop(
                      dialogContext,
                    );
                  }

                  _tampilkanSnackBar(
                    "Akun berhasil diupgrade ke PREMIUM!",
                    isError: false,
                  );
                } catch (e) {
                  _tampilkanSnackBar(
                    "Gagal menyetujui KYC: $e",
                    isError: true,
                  );
                }
              },
              child: const Text(
                "Setujui & Upgrade",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EDIT SALDO
  // ============================================================

  Future<void> _tampilkanDialogEditSaldo(
    String userId,
    int saldoSaatIni,
  ) async {
    final TextEditingController controller =
        TextEditingController(
      text: saldoSaatIni.toString(),
    );

    try {
      await showDialog<void>(
        context: context,
        builder:
            (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text(
              "Adjustment Saldo Manual",
            ),
            content: TextField(
              controller: controller,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText:
                    "Nominal Baru",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  dialogContext,
                ),
                child:
                    const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final String raw =
                      controller.text
                          .trim();

                  final int? saldo =
                      int.tryParse(raw);

                  if (saldo == null ||
                      saldo < 0) {
                    _tampilkanSnackBar(
                      "Saldo tidak valid.",
                      isError: true,
                    );
                    return;
                  }

                  try {
                    await _firestore
                        .collection(
                            "users")
                        .doc(userId)
                        .update({
                      "saldo": saldo,
                      "updatedAt":
                          FieldValue
                              .serverTimestamp(),
                    });

                    if (dialogContext
                        .mounted) {
                      Navigator.pop(
                        dialogContext,
                      );
                    }

                    _tampilkanSnackBar(
                      "Saldo berhasil diubah.",
                      isError: false,
                    );
                  } catch (e) {
                    _tampilkanSnackBar(
                      "Gagal mengubah saldo: $e",
                      isError: true,
                    );
                  }
                },
                child:
                    const Text("Simpan"),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  // ============================================================
  // PANEL KEUANGAN
  // ============================================================

  Widget _buildPanelKeuangan() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          FutureBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            future: _firestore
                .collection("transaksi")
                .get(),
            builder:
                (context, snapshot) {
              int totalOmset = 0;

              if (snapshot.hasData) {
                for (final QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    doc
                    in snapshot.data!.docs) {
                  final Map<String,
                          dynamic>
                      log =
                      _asMap(doc.data());

                  final String status =
                      _toStringValue(
                    log["status"],
                  ).toUpperCase();

                  if (status
                          .contains(
                              "SUKSES") ||
                      status.contains(
                          "BERHASIL")) {
                    totalOmset += _toInt(
                      log["hargaJual"] ??
                          log["price"] ??
                          0,
                    );
                  }
                }
              }

              if (snapshot.hasError) {
                return Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 20,
                  ),
                  child:
                      _buildInfoCard(
                    "Total Omset Bersih",
                    "Gagal memuat",
                    Icons
                        .error_outline_rounded,
                    WarnaDesaPay.danger,
                  ),
                );
              }

              return Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 20,
                ),
                width:
                    double.infinity,
                child:
                    _buildInfoCard(
                  "Total Omset Bersih (Sukses)",
                  "Rp ${_formatCurrency(totalOmset)}",
                  Icons
                      .trending_up_rounded,
                  WarnaDesaPay.success,
                ),
              );
            },
          ),

          // ====================================================
          // MARKUP
          // ====================================================

          Container(
            padding:
                const EdgeInsets.all(20),
            decoration:
                BoxDecoration(
              color:
                  WarnaDesaPay.lightCard,
              borderRadius:
                  BorderRadius.circular(
                      24),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons
                          .price_change_rounded,
                      color:
                          WarnaDesaPay
                              .success,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Markup Harga Layanan",
                      style: TextStyle(
                        fontWeight:
                            FontWeight
                                .w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  "Atur keuntungan berdasarkan jenis layanan. "
                  "Tidak perlu mengubah SKU satu per satu.",
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        WarnaDesaPay
                            .textSub,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                _buildMarkupInput(
                  icon:
                      Icons.phone_android_rounded,
                  title: "Pulsa",
                  subtitle:
                      "Pulsa reguler / isi ulang",
                  controller:
                      markupPulsaController,
                ),
                const SizedBox(
                  height: 12,
                ),
                _buildMarkupInput(
                  icon:
                      Icons.language_rounded,
                  title:
                      "Kuota / Data",
                  subtitle:
                      "Paket internet / data",
                  controller:
                      markupKuotaController,
                ),
                const SizedBox(
                  height: 12,
                ),
                _buildMarkupInput(
                  icon:
                      Icons.credit_card_rounded,
                  title:
                      "Angsuran",
                  subtitle:
                      "Cicilan / pembayaran finance",
                  controller:
                      markupAngsuranController,
                ),
                const SizedBox(
                  height: 12,
                ),
                _buildMarkupInput(
                  icon:
                      Icons.category_rounded,
                  title: "Lainnya",
                  subtitle:
                      "Produk yang tidak terdeteksi",
                  controller:
                      markupLainnyaController,
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width:
                      double.infinity,
                  height: 48,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _isLoading
                            ? null
                            : _simpanSemuaMarkup,
                    icon: const Icon(
                      Icons.save_rounded,
                    ),
                    label:
                        const Text(
                      "SIMPAN SEMUA MARKUP",
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .w900,
                      ),
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          WarnaDesaPay
                              .success,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // SYNC MARKUP
          // ====================================================

          Container(
            padding:
                const EdgeInsets.all(18),
            decoration:
                BoxDecoration(
              color: WarnaDesaPay
                  .warning
                  .withOpacity(
                      0.08),
              borderRadius:
                  BorderRadius.circular(
                      20),
              border: Border.all(
                color: WarnaDesaPay
                    .warning
                    .withOpacity(
                        0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      color:
                          WarnaDesaPay
                              .warning,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Sinkronisasi Harga Produk",
                      style: TextStyle(
                        fontWeight:
                            FontWeight
                                .w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  "Jika markup baru sudah disimpan, tombol ini "
                  "menghitung ulang harga jual seluruh produk "
                  "yang sudah ada.",
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        WarnaDesaPay
                            .textSub,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                if (_isLoading &&
                    _syncTotal > 0)
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      LinearProgressIndicator(
                        value: _syncTotal >
                                0
                            ? (_syncProgress /
                                    _syncTotal)
                                .clamp(
                                    0.0,
                                    1.0)
                            : 0,
                        minHeight: 7,
                        borderRadius:
                            BorderRadius
                                .circular(
                                    10),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        "Update $_syncProgress / $_syncTotal produk...",
                        style:
                            const TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                    ],
                  ),
                SizedBox(
                  width:
                      double.infinity,
                  height: 48,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _isLoading
                            ? null
                            : _terapkanMarkupKeSemuaProduk,
                    icon: const Icon(
                      Icons.sync_rounded,
                    ),
                    label:
                        const Text(
                      "TERAPKAN KE SEMUA PRODUK",
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .w900,
                      ),
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          WarnaDesaPay
                              .warning,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ====================================================
          // SALDO PROVIDER
          // ====================================================

          StreamBuilder<
              DocumentSnapshot<
                  Map<String, dynamic>>>(
            stream: _firestore
                .collection(
                    "pengaturan")
                .doc("finansial")
                .snapshots(),
            builder:
                (context, snapshot) {
              int saldoDigi = 0;
              int saldoTri = 0;

              if (snapshot.hasData &&
                  snapshot.data!.exists) {
                final Map<String,
                        dynamic>
                    data =
                    _asMap(
                  snapshot.data!.data(),
                );

                saldoDigi = _toInt(
                  data["saldoDigiflazz"],
                );

                saldoTri = _toInt(
                  data["saldoTriPay"],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child:
                        _buildInfoCard(
                      "Saldo Digiflazz",
                      "Rp ${_formatCurrency(saldoDigi)}",
                      Icons.api_rounded,
                      WarnaDesaPay
                          .primary,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                        _buildInfoCard(
                      "Saldo TriPay",
                      "Rp ${_formatCurrency(saldoTri)}",
                      Icons
                          .payment_rounded,
                      Colors.orange,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(
            height: 24,
          ),

          const Text(
            "Live Mutasi Transaksi User",
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          _buildTransaksiStream(),
        ],
      ),
    );
  }

  // ============================================================
  // MARKUP INPUT
  // ============================================================

  Widget _buildMarkupInput({
    required IconData icon,
    required String title,
    required String subtitle,
    required TextEditingController
        controller,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            WarnaDesaPay.lightBg,
        borderRadius:
            BorderRadius.circular(
                16),
        border: Border.all(
          color:
              WarnaDesaPay.lightField,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color: WarnaDesaPay
                  .primary
                  .withOpacity(
                      0.1),
              borderRadius:
                  BorderRadius
                      .circular(
                          12),
            ),
            child: Icon(
              icon,
              color:
                  WarnaDesaPay
                      .primary,
              size: 21,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight
                            .w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        WarnaDesaPay
                            .textSub,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              controller:
                  controller,
              keyboardType:
                  TextInputType
                      .number,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight
                        .w900,
              ),
              decoration:
                  InputDecoration(
                prefixText:
                    "Rp ",
                prefixStyle:
                    const TextStyle(
                  fontWeight:
                      FontWeight
                          .bold,
                ),
                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                filled: true,
                fillColor:
                    Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                              10),
                  borderSide:
                      BorderSide
                          .none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSAKSI STREAM
  // ============================================================

  Widget _buildTransaksiStream() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection("transaksi")
          .orderBy(
            "waktu",
            descending: true,
          )
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot
                .connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorMessage(
            "Gagal memuat transaksi: "
            "${snapshot.error}",
          );
        }

        final List<
                QueryDocumentSnapshot<
                    Map<String, dynamic>>>
            docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding:
                  EdgeInsets.all(20),
              child: Text(
                "Belum ada log transaksi.",
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder:
              (context, index) {
            final Map<String,
                    dynamic>
                log =
                _asMap(
              docs[index].data(),
            );

            final String status =
                _toStringValue(
              log["status"],
              fallback:
                  "PENDING",
            ).toUpperCase();

            Color statusColor =
                WarnaDesaPay.warning;

            if (status
                    .contains(
                        "SUKSES") ||
                status.contains(
                    "BERHASIL")) {
              statusColor =
                  WarnaDesaPay
                      .success;
            } else if (status
                .contains("GAGAL")) {
              statusColor =
                  WarnaDesaPay
                      .danger;
            }

            final String produk =
                _toStringValue(
              log["product_name"] ??
                  log["buyer_sku_code"],
              fallback: "-",
            );

            final String jenis =
                _toStringValue(
              log["jenisLayanan"],
              fallback: "-",
            );

            final String tujuan =
                _toStringValue(
              log["customer_no"] ??
                  log["tujuan"],
              fallback: "-",
            );

            final String sn =
                _toStringValue(
              log["sn"] ??
                  log["message"],
              fallback: "-",
            );

            return Container(
              margin:
                  const EdgeInsets.only(
                bottom: 14,
              ),
              padding:
                  const EdgeInsets.all(
                      16),
              decoration:
                  BoxDecoration(
                color:
                    WarnaDesaPay
                        .lightCard,
                borderRadius:
                    BorderRadius.circular(
                        18),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text(
                        status,
                        style:
                            TextStyle(
                          color:
                              statusColor,
                          fontWeight:
                              FontWeight
                                  .w900,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        "Rp ${_formatCurrency(log["hargaJual"] ?? log["price"] ?? 0)}",
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildDetailRow(
                    "Produk",
                    produk,
                  ),
                  _buildDetailRow(
                    "Jenis",
                    jenis,
                  ),
                  _buildDetailRow(
                    "Tujuan",
                    tujuan,
                  ),
                  _buildDetailRow(
                    "SN/Reff",
                    sn,
                  ),
                  _buildDetailRow(
                    "Waktu",
                    _formatDate(
                      log["waktu"],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: color.withOpacity(
            0.1),
        borderRadius:
            BorderRadius.circular(
                16),
        border: Border.all(
          color:
              color.withOpacity(
                  0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(
            height: 3,
          ),
          Text(
            value,
            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(
              color:
                  WarnaDesaPay
                      .textSub,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              value,
              textAlign:
                  TextAlign.end,
              maxLines: 1,
              overflow:
                  TextOverflow
                      .ellipsis,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight
                        .w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PANEL SISTEM
  // ============================================================

  Widget _buildPanelSistem() {
    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(),
      padding:
          const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.all(16),
            margin:
                const EdgeInsets.only(
              bottom: 24,
            ),
            decoration:
                BoxDecoration(
              color: _isMaintenance
                  ? WarnaDesaPay
                      .danger
                      .withOpacity(
                          0.1)
                  : WarnaDesaPay
                      .lightCard,
              borderRadius:
                  BorderRadius.circular(
                      16),
              border: Border.all(
                color: _isMaintenance
                    ? WarnaDesaPay
                        .danger
                    : WarnaDesaPay
                        .lightField,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.build_rounded,
                  color: _isMaintenance
                      ? WarnaDesaPay
                          .danger
                      : WarnaDesaPay
                          .textSub,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        "Mode Maintenance",
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                          color: _isMaintenance
                              ? WarnaDesaPay
                                  .danger
                              : WarnaDesaPay
                                  .textMain,
                        ),
                      ),
                      const Text(
                        "Matikan server: 'Harap menunggu dan coba nanti'",
                        style:
                            TextStyle(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value:
                      _isMaintenance,
                  activeColor:
                      WarnaDesaPay
                          .danger,
                  onChanged:
                      _toggleMaintenance,
                ),
              ],
            ),
          ),
          const Text(
            "Live System Logs",
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream: _firestore
                .collection(
                    "system_logs")
                .orderBy(
                  "timestamp",
                  descending: true,
                )
                .limit(30)
                .snapshots(),
            builder:
                (context, snapshot) {
              if (snapshot
                      .connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorMessage(
                  "Gagal memuat system logs: "
                  "${snapshot.error}",
                );
              }

              final List<
                      QueryDocumentSnapshot<
                          Map<String, dynamic>>>
                  docs =
                  snapshot.data?.docs ??
                      [];

              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.all(
                            20),
                    child: Text(
                      "Sistem Berjalan Aman",
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount:
                    docs.length,
                itemBuilder:
                    (context, index) {
                  final Map<String,
                          dynamic>
                      log =
                      _asMap(
                    docs[index].data(),
                  );

                  final String tipe =
                      _toStringValue(
                    log["tipe"],
                    fallback:
                        "INFO",
                  );

                  final String pesan =
                      _toStringValue(
                    log["pesan"],
                    fallback: "-",
                  );

                  return Container(
                    margin:
                        const EdgeInsets
                            .only(
                      bottom: 12,
                    ),
                    padding:
                        const EdgeInsets
                            .all(12),
                    decoration:
                        BoxDecoration(
                      color:
                          WarnaDesaPay
                              .lightCard,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  12),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          tipe,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                            fontSize: 10,
                            color:
                                WarnaDesaPay
                                    .primary,
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          pesan,
                          style:
                              const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PANEL TIKET CS
  // ============================================================

  Widget _buildPanelTiketCS() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection(
              "keluhan_pelanggan")
          .orderBy(
            "waktuMasuk",
            descending: true,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot
                .connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorMessage(
            "Gagal memuat tiket CS: "
            "${snapshot.error}",
          );
        }

        final List<
                QueryDocumentSnapshot<
                    Map<String, dynamic>>>
            docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Inbox Bersih!",
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder:
              (context, index) {
            final QueryDocumentSnapshot<
                    Map<String, dynamic>>
                doc =
                docs[index];

            final Map<String,
                    dynamic>
                tiket =
                _asMap(
              doc.data(),
            );

            final String tiketId =
                doc.id;

            final String namaUser =
                _toStringValue(
              tiket["namaUser"],
              fallback:
                  "Anonymous",
            );

            final String phoneUser =
                _toStringValue(
              tiket["phoneUser"],
              fallback: "-",
            );

            final String pesan =
                _toStringValue(
              tiket["pesan"],
              fallback: "-",
            );

            String status =
                _toStringValue(
              tiket["status"],
              fallback:
                  "Pending",
            );

            const List<String>
                statusValid = [
              "Pending",
              "Proses",
              "Selesai",
            ];

            if (!statusValid
                .contains(status)) {
              status = "Pending";
            }

            final String balasan =
                _toStringValue(
              tiket["balasanAdmin"],
            );

            return Container(
              margin:
                  const EdgeInsets.only(
                bottom: 14,
              ),
              padding:
                  const EdgeInsets.all(
                      16),
              decoration:
                  BoxDecoration(
                color:
                    WarnaDesaPay
                        .lightCard,
                borderRadius:
                    BorderRadius.circular(
                        16),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Expanded(
                        child: Text(
                          namaUser,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      DropdownButton<
                          String>(
                        value: status,
                        items: statusValid
                            .map(
                              (
                                String value,
                              ) =>
                                  DropdownMenuItem<
                                      String>(
                                value:
                                    value,
                                child:
                                    Text(
                                  value,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged:
                            (String? value) async {
                          if (value ==
                              null) {
                            return;
                          }

                          try {
                            await _firestore
                                .collection(
                                    "keluhan_pelanggan")
                                .doc(
                                    tiketId)
                                .update({
                              "status":
                                  value,
                              "updatedAt":
                                  FieldValue
                                      .serverTimestamp(),
                            });
                          } catch (e) {
                            _tampilkanSnackBar(
                              "Gagal mengubah status tiket: $e",
                              isError:
                                  true,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  Text(
                    "Kontak: $phoneUser",
                    style:
                        const TextStyle(
                      color:
                          WarnaDesaPay
                              .primary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .all(10),
                    decoration:
                        BoxDecoration(
                      color:
                          WarnaDesaPay
                              .lightField,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  10),
                    ),
                    child: Text(
                      "\"$pesan\"",
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontStyle:
                            FontStyle
                                .italic,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  if (balasan.isNotEmpty)
                    Text(
                      "Balasan Admin: $balasan",
                      style:
                          const TextStyle(
                        color:
                            WarnaDesaPay
                                .success,
                        fontSize: 12,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  Align(
                    alignment:
                        Alignment
                            .centerRight,
                    child:
                        TextButton.icon(
                      icon:
                          const Icon(
                        Icons
                            .reply_rounded,
                        size: 16,
                      ),
                      label: Text(
                        balasan.isEmpty
                            ? "Balas Pesan"
                            : "Edit Balasan",
                      ),
                      onPressed: () =>
                          _tampilkanDialogBalasCS(
                        tiketId,
                        balasan,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BALAS CS
  // ============================================================

  Future<void> _tampilkanDialogBalasCS(
    String tiketId,
    String balasanLama,
  ) async {
    final TextEditingController
        controller =
        TextEditingController(
      text: balasanLama,
    );

    try {
      await showDialog<void>(
        context: context,
        builder:
            (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text(
              "Balas Tiket Pengguna",
            ),
            content: TextField(
              controller:
                  controller,
              maxLines: 4,
              decoration:
                  const InputDecoration(
                hintText:
                    "Ketik balasan...",
                border:
                    OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  dialogContext,
                ),
                child:
                    const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final String
                      balasan =
                      controller.text
                          .trim();

                  if (balasan.isEmpty) {
                    _tampilkanSnackBar(
                      "Balasan tidak boleh kosong.",
                      isError: true,
                    );
                    return;
                  }

                  try {
                    await _firestore
                        .collection(
                            "keluhan_pelanggan")
                        .doc(tiketId)
                        .update({
                      "balasanAdmin":
                          balasan,
                      "status":
                          "Selesai",
                      "waktuBalasan":
                          FieldValue
                              .serverTimestamp(),
                      "updatedAt":
                          FieldValue
                              .serverTimestamp(),
                    });

                    if (dialogContext
                        .mounted) {
                      Navigator.pop(
                        dialogContext,
                      );
                    }

                    _tampilkanSnackBar(
                      "Balasan berhasil dikirim.",
                      isError: false,
                    );
                  } catch (e) {
                    _tampilkanSnackBar(
                      "Gagal mengirim balasan: $e",
                      isError: true,
                    );
                  }
                },
                child: const Text(
                  "Kirim Balasan",
                ),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  // ============================================================
  // MODERN INPUT
  // ============================================================

  Widget _buildModernInput({
    required BuildContext context,
    required TextEditingController
        controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
            color:
                WarnaDesaPay.textSub,
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style:
              const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w700,
          ),
          decoration:
              InputDecoration(
            hintText: hint,
            filled: true,
            fillColor:
                WarnaDesaPay.lightBg,
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius
                      .circular(
                          14),
              borderSide:
                  BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  Widget _buildErrorMessage(
    String message,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
                20),
        child: Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.all(
                  16),
          decoration:
              BoxDecoration(
            color: WarnaDesaPay
                .danger
                .withOpacity(
                    0.08),
            borderRadius:
                BorderRadius.circular(
                    14),
            border: Border.all(
              color: WarnaDesaPay
                  .danger
                  .withOpacity(
                      0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const Icon(
                Icons
                    .error_outline_rounded,
                color:
                    WarnaDesaPay
                        .danger,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  message,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        WarnaDesaPay
                            .danger,
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
