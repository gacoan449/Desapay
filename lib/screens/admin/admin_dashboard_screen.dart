import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

import '../../config/warna.dart';
import '../../widgets/menu_item.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  late TabController _adminTabController;

  // ============================================================
  // CONTROLLER KONTEN UI
  // ============================================================

  final TextEditingController promoController =
      TextEditingController();

  final TextEditingController bannerController =
      TextEditingController();

  final TextEditingController namaMenuController =
      TextEditingController();

  final TextEditingController ikonController =
      TextEditingController();

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

  // Progress Excel
  int _excelProgress = 0;
  int _excelTotal = 0;

  // Progress sinkronisasi harga
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
  // LOAD KONFIGURASI
  // ============================================================

  Future<void> _loadInitialConfiguration() async {
    try {
      final DocumentSnapshot docApp = await _firestore
          .collection("pengaturan")
          .doc("aplikasi")
          .get();

      if (docApp.exists && mounted) {
        final data =
            docApp.data() as Map<String, dynamic>;

        setState(() {
          bannerController.text =
              data["teksBanner"] ?? "";

          promoController.text =
              data["teksPromo"] ?? "";
        });
      }

      final DocumentSnapshot docFin = await _firestore
          .collection("pengaturan")
          .doc("finansial")
          .get();

      if (docFin.exists && mounted) {
        final data =
            docFin.data() as Map<String, dynamic>;

        setState(() {
          markupPulsaController.text =
              _toInt(
                data["markupPulsa"] ?? 0,
              ).toString();

          markupKuotaController.text =
              _toInt(
                data["markupKuota"] ?? 0,
              ).toString();

          markupAngsuranController.text =
              _toInt(
                data["markupAngsuran"] ?? 0,
              ).toString();

          markupLainnyaController.text =
              _toInt(
                data["markupLainnya"] ?? 0,
              ).toString();
        });
      }
    } catch (e) {
      debugPrint(
        "Gagal memuat konfigurasi admin: $e",
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
  // SIMPAN KONTEN UI
  // ============================================================

  Future<void> _simpanPerubahanPromo() async {
    if (promoController.text.trim().isEmpty ||
        bannerController.text.trim().isEmpty) {
      _tampilkanSnackBar(
        "Teks banner dan promo tidak boleh kosong.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore
          .collection("pengaturan")
          .doc("aplikasi")
          .set(
        {
          "teksPromo":
              promoController.text.trim(),
          "teksBanner":
              bannerController.text.trim(),
          "updatedAt":
              FieldValue.serverTimestamp(),
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
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // AMBIL SEMUA MARKUP
  // ============================================================

  Future<Map<String, int>> _ambilSemuaMarkup() async {
    final DocumentSnapshot doc =
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

    final data =
        doc.data() as Map<String, dynamic>;

    return {
      "pulsa": _toInt(
        data["markupPulsa"],
      ),
      "kuota": _toInt(
        data["markupKuota"],
      ),
      "angsuran": _toInt(
        data["markupAngsuran"],
      ),
      "lainnya": _toInt(
        data["markupLainnya"],
      ),
    };
  }

  // ============================================================
  // SIMPAN MARKUP PER KATEGORI
  // ============================================================

  Future<void> _simpanSemuaMarkup() async {
    final int? pulsa =
        int.tryParse(
      markupPulsaController.text.trim(),
    );

    final int? kuota =
        int.tryParse(
      markupKuotaController.text.trim(),
    );

    final int? angsuran =
        int.tryParse(
      markupAngsuranController.text.trim(),
    );

    final int? lainnya =
        int.tryParse(
      markupLainnyaController.text.trim(),
    );

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

    setState(() => _isLoading = true);

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

          "updatedAt":
              FieldValue.serverTimestamp(),
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
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // TENTUKAN KATEGORI PRODUK
  // ============================================================

  String _tentukanKategoriProduk(
    Map<String, dynamic> produk,
  ) {
    final String kategori =
        (produk["category"] ??
                produk["kategori"] ??
                "")
            .toString()
            .toLowerCase();

    final String nama =
        (produk["product_name"] ??
                produk["nama_produk"] ??
                produk["produk"] ??
                "")
            .toString()
            .toLowerCase();

    final String brand =
        (produk["brand"] ?? "")
            .toString()
            .toLowerCase();

    final String sku =
        (produk["buyer_sku_code"] ??
                produk["sku"] ??
                "")
            .toString()
            .toLowerCase();

    final String gabungan =
        "$kategori $nama $brand $sku";

    // ==========================================================
    // ANGSURAN
    // ==========================================================

    if (gabungan.contains("angsuran") ||
        gabungan.contains("cicilan") ||
        gabungan.contains("kredit") ||
        gabungan.contains("finance") ||
        gabungan.contains("multifinance") ||
        gabungan.contains("leasing")) {
      return "angsuran";
    }

    // ==========================================================
    // KUOTA / DATA
    // ==========================================================

    if (gabungan.contains("kuota") ||
        gabungan.contains("data") ||
        gabungan.contains("internet") ||
        gabungan.contains("paket data") ||
        gabungan.contains("combo") ||
        gabungan.contains("internet")) {
      return "kuota";
    }

    // ==========================================================
    // PULSA
    // ==========================================================

    if (gabungan.contains("pulsa") ||
        gabungan.contains("voucher pulsa") ||
        gabungan.contains("pulsa reguler") ||
        gabungan.contains("regular")) {
      return "pulsa";
    }

    // ==========================================================
    // LAINNYA
    // ==========================================================

    return "lainnya";
  }

  // ============================================================
  // AMBIL MARKUP BERDASARKAN KATEGORI
  // ============================================================

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
  // UPLOAD EXCEL PRODUK
  // ============================================================

  Future<void> _uploadExcelProduk() async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
        _excelProgress = 0;
        _excelTotal = 0;
      });

      final FilePickerResult? result =
          await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          "xlsx",
          "xls",
        ],
        withData: true,
      );

      if (result == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final PlatformFile file =
          result.files.single;

      if (file.bytes == null) {
        throw Exception(
          "Data file Excel tidak dapat dibaca.",
        );
      }

      final Uint8List bytes =
          file.bytes!;

      final Excel excel =
          Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception(
          "File Excel tidak memiliki sheet.",
        );
      }

      final String sheetName =
          excel.tables.keys.first;

      final Sheet? sheet =
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

      // ========================================================
      // HEADER
      // ========================================================

      final List<dynamic> headerRow =
          sheet.rows.first;

      final List<String> headers =
          headerRow.map((cell) {
        return _normalisasiHeader(
          cell?.value?.toString() ?? "",
        );
      }).toList();

      if (headers.isEmpty) {
        throw Exception(
          "Header Excel tidak ditemukan.",
        );
      }

      // ========================================================
      // MARKUP TERBARU
      // ========================================================

      final Map<String, int> semuaMarkup =
          await _ambilSemuaMarkup();

      // ========================================================
      // LOOP PRODUK
      // ========================================================

      final List<Map<String, dynamic>>
          produkList = [];

      int jumlahGagal = 0;

      for (
        int rowIndex = 1;
        rowIndex < sheet.maxRows;
        rowIndex++
      ) {
        final row =
            sheet.rows[rowIndex];

        if (_barisKosong(row)) {
          continue;
        }

        try {
          final Map<String, dynamic>
              produk = {};

          for (
            int columnIndex = 0;
            columnIndex < headers.length;
            columnIndex++
          ) {
            if (columnIndex >= row.length) {
              continue;
            }

            final String header =
                headers[columnIndex];

            if (header.isEmpty) {
              continue;
            }

            final cell =
                row[columnIndex];

            final dynamic value =
                cell?.value;

            final dynamic cleaned =
                _bersihkanNilaiExcel(
              value,
            );

            if (cleaned != null) {
              produk[header] = cleaned;
            }
          }

          if (produk.isEmpty) {
            jumlahGagal++;
            continue;
          }

          // ====================================================
          // SKU
          // ====================================================

          final String sku =
              _ambilSKU(produk);

          if (sku.isEmpty) {
            jumlahGagal++;
            continue;
          }

          produk["buyer_sku_code"] =
              sku;

          // ====================================================
          // HARGA BELI
          // ====================================================

          final int hargaBeli =
              _ambilHargaProduk(produk);

          produk["hargaBeli"] =
              hargaBeli;

          if (!produk.containsKey("price")) {
            produk["price"] =
                hargaBeli;
          }

          // ====================================================
          // TENTUKAN KATEGORI
          // ====================================================

          final String kategori =
              _tentukanKategoriProduk(
            produk,
          );

          produk["jenisLayanan"] =
              kategori;

          // ====================================================
          // MARKUP SESUAI JENIS
          // ====================================================

          final int markup =
              _markupUntukKategori(
            kategori,
            semuaMarkup,
          );

          produk["markup"] =
              markup;

          // ====================================================
          // HARGA JUAL
          // ====================================================

          produk["hargaJual"] =
              hargaBeli + markup;

          // ====================================================
          // STATUS
          // ====================================================

          if (!produk.containsKey("isAktif")) {
            produk["isAktif"] = true;
          }

          if (!produk.containsKey("status")) {
            produk["status"] = "aktif";
          }

          // ====================================================
          // INFORMASI IMPORT
          // ====================================================

          produk["source"] =
              "excel";

          produk["importedAt"] =
              FieldValue.serverTimestamp();

          produk["updatedAt"] =
              FieldValue.serverTimestamp();

          produkList.add(produk);
        } catch (e) {
          debugPrint(
            "Gagal membaca baris Excel "
            "$rowIndex: $e",
          );

          jumlahGagal++;
        }
      }

      if (produkList.isEmpty) {
        throw Exception(
          "Tidak ada produk valid yang ditemukan.",
        );
      }

      // ========================================================
      // PROGRESS
      // ========================================================

      if (mounted) {
        setState(() {
          _excelTotal =
              produkList.length;

          _excelProgress = 0;
        });
      }

      // ========================================================
      // FIRESTORE BATCH
      // ========================================================

      const int batchSize = 450;

      int totalTersimpan = 0;

      for (
        int i = 0;
        i < produkList.length;
        i += batchSize
      ) {
        final int end =
            (i + batchSize <
                    produkList.length)
                ? i + batchSize
                : produkList.length;

        final List<Map<String, dynamic>>
            batchData =
            produkList.sublist(
          i,
          end,
        );

        final WriteBatch batch =
            _firestore.batch();

        for (final produk
            in batchData) {
          final String sku =
              produk["buyer_sku_code"]
                  .toString()
                  .trim();

          final DocumentReference ref =
              _firestore
                  .collection("produk")
                  .doc(sku);

          batch.set(
            ref,
            produk,
            SetOptions(
              merge: true,
            ),
          );
        }

        await batch.commit();

        totalTersimpan +=
            batchData.length;

        if (mounted) {
          setState(() {
            _excelProgress =
                totalTersimpan;
          });
        }
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _tampilkanSnackBar(
        "Upload selesai! "
        "$totalTersimpan produk berhasil disimpan. "
        "$jumlahGagal baris dilewati.",
        isError: false,
      );
    } catch (e) {
      debugPrint(
        "UPLOAD EXCEL ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _tampilkanSnackBar(
        "Gagal upload Excel: $e",
        isError: true,
      );
    }
  }

  // ============================================================
  // TERAPKAN MARKUP KE SEMUA PRODUK
  //
  // Jadi kalau nanti:
  //
  // Pulsa  = 500
  // Kuota  = 1500
  // Angsuran = 2500
  //
  // produk lama juga ikut berubah.
  // ============================================================

  Future<void> _terapkanMarkupKeSemuaProduk() async {
    if (_isLoading) return;

    final bool? konfirmasi =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Terapkan Markup?",
          ),
          content: const Text(
            "Semua produk di Firestore akan "
            "dihitung ulang berdasarkan jenis layanan. "
            "\n\n"
            "Pulsa, Kuota, Angsuran dan Lainnya "
            "akan menggunakan markup masing-masing.",
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child:
                  const Text(
                "TERAPKAN",
              ),
            ),
          ],
        );
      },
    );

    if (konfirmasi != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _syncProgress = 0;
      _syncTotal = 0;
    });

    try {
      final Map<String, int>
          semuaMarkup =
          await _ambilSemuaMarkup();

      final QuerySnapshot snapshot =
          await _firestore
              .collection("produk")
              .get();

      final docs =
          snapshot.docs;

      if (mounted) {
        setState(() {
          _syncTotal =
              docs.length;
        });
      }

      const int batchSize = 450;

      int totalUpdate = 0;

      for (
        int i = 0;
        i < docs.length;
        i += batchSize
      ) {
        final int end =
            (i + batchSize <
                    docs.length)
                ? i + batchSize
                : docs.length;

        final WriteBatch batch =
            _firestore.batch();

        for (
          int j = i;
          j < end;
          j++
        ) {
          final doc =
              docs[j];

          final data =
              doc.data()
                  as Map<String,
                      dynamic>;

          final String kategori =
              _tentukanKategoriProduk(
            data,
          );

          final int hargaBeli =
              _toInt(
            data["hargaBeli"] ??
                data["price"] ??
                0,
          );

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
              "jenisLayanan":
                  kategori,
              "markup":
                  markup,
              "hargaJual":
                  hargaJual,
              "updatedAt":
                  FieldValue
                      .serverTimestamp(),
            },
          );
        }

        await batch.commit();

        totalUpdate +=
            end - i;

        if (mounted) {
          setState(() {
            _syncProgress =
                totalUpdate;
          });
        }
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _tampilkanSnackBar(
        "$totalUpdate produk berhasil "
        "diperbarui dengan markup terbaru.",
        isError: false,
      );
    } catch (e) {
      debugPrint(
        "SYNC MARKUP ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _tampilkanSnackBar(
        "Gagal menerapkan markup: $e",
        isError: true,
      );
    }
  }

  // ============================================================
  // AMBIL SKU
  // ============================================================

  String _ambilSKU(
      Map<String, dynamic> produk) {
    final kandidat = [
      produk["buyer_sku_code"],
      produk["sku"],
      produk["kode_produk"],
      produk["kode_sku"],
      produk["product_code"],
    ];

    for (final item in kandidat) {
      if (item != null &&
          item.toString().trim().isNotEmpty) {
        return item
            .toString()
            .trim();
      }
    }

    return "";
  }

  // ============================================================
  // AMBIL HARGA PRODUK
  // ============================================================

  int _ambilHargaProduk(
      Map<String, dynamic> produk) {
    final kandidat = [
      produk["price"],
      produk["hargaBeli"],
      produk["harga"],
      produk["harga_beli"],
      produk["selling_price"],
    ];

    for (final item in kandidat) {
      if (item == null) continue;

      final int value =
          _toInt(item);

      if (value > 0) {
        return value;
      }
    }

    return 0;
  }

  // ============================================================
  // NORMALISASI HEADER
  // ============================================================

  String _normalisasiHeader(
      String value) {
    String hasil =
        value.trim().toLowerCase();

    hasil = hasil.replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );

    hasil = hasil.replaceAll(
      RegExp(r'_+'),
      '_',
    );

    hasil = hasil.replaceAll(
      RegExp(r'^_|_$'),
      '',
    );

    switch (hasil) {
      case "nama_produk":
        return "product_name";

      case "nama":
        return "product_name";

      case "deskripsi":
        return "description";

      case "deskripsi_produk":
        return "description";

      case "harga":
        return "price";

      case "harga_beli":
        return "hargaBeli";

      case "kode_produk":
        return "buyer_sku_code";

      case "kode_sku":
        return "buyer_sku_code";

      case "sku":
        return "buyer_sku_code";

      case "kategori":
        return "category";

      case "nama_kategori":
        return "category";

      case "status_produk":
        return "status";

      case "nomor":
        return "customer_no";

      case "produk":
        return "product_name";

      case "provider":
        return "brand";

      case "operator":
        return "brand";

      default:
        return hasil;
    }
  }

  // ============================================================
  // BERSIHKAN EXCEL
  // ============================================================

  dynamic _bersihkanNilaiExcel(
      dynamic value) {
    if (value == null) {
      return null;
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    final String lower =
        text.toLowerCase();

    if (lower == "true" ||
        lower == "yes" ||
        lower == "ya") {
      return true;
    }

    if (lower == "false" ||
        lower == "no" ||
        lower == "tidak") {
      return false;
    }

    String angka =
        text.replaceAll(
      RegExp(r'(?i)rp'),
      '',
    );

    angka = angka.replaceAll(
      '.',
      '',
    );

    angka = angka.replaceAll(
      ',',
      '',
    );

    final int? intValue =
        int.tryParse(angka);

    if (intValue != null) {
      return intValue;
    }

    final double? doubleValue =
        double.tryParse(text);

    if (doubleValue != null) {
      return doubleValue;
    }

    return text;
  }

  // ============================================================
  // TO INT
  // ============================================================

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

    String text =
        value.toString().trim();

    text = text
        .replaceAll(
          RegExp(r'(?i)rp'),
          '',
        )
        .replaceAll('.', '')
        .replaceAll(',', '');

    return int.tryParse(text) ?? 0;
  }

  // ============================================================
  // BARIS KOSONG
  // ============================================================

  bool _barisKosong(
      List<dynamic> row) {
    for (final cell in row) {
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
  // SNACKBAR
  // ============================================================

  void _tampilkanSnackBar(
    String pesan, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          pesan,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize: 13,
            color:
                Colors.white,
          ),
        ),
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
        backgroundColor:
            isError
                ? WarnaDesaPay.danger
                : WarnaDesaPay.success,
      ),
    );
  }

  // ============================================================
  // FORMAT CURRENCY
  // ============================================================

  String _formatCurrency(
      dynamic value) {
    final int parsed =
        _toInt(value);

    return parsed
        .toString()
        .replaceAllMapped(
          RegExp(
            r'(\d{1,3})(?=(\d{3})+(?!\d))',
          ),
          (Match m) =>
              '${m[1]}.',
        );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
      Timestamp? timestamp) {
    if (timestamp == null) {
      return "-";
    }

    final DateTime dt =
        timestamp.toDate();

    return "${dt.day}/"
        "${dt.month}/"
        "${dt.year} "
        "${dt.hour}:"
        "${dt.minute.toString().padLeft(2, '0')}";
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      backgroundColor:
          WarnaDesaPay.lightBg,

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            WarnaDesaPay.darkCard,
        foregroundColor:
            Colors.white,

        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "HQ Command Center",
              style: TextStyle(
                fontWeight:
                    FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "DesaPay Administrator Mode",
              style: TextStyle(
                fontSize: 11,
                color:
                    WarnaDesaPay.warning,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),

        leading: IconButton(
          icon: const Icon(
            Icons
                .arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: () =>
              Navigator.pop(context),
        ),

        bottom:
            PreferredSize(
          preferredSize:
              const Size.fromHeight(
            48,
          ),
          child: Container(
            color:
                WarnaDesaPay.darkBg,
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
  // TAB 1 — KONTEN UI
  // ============================================================

  Widget _buildPanelKontenUI() {
    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(),
      padding:
          const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          // ====================================================
          // KAMPANYE
          // ====================================================

          Container(
            padding:
                const EdgeInsets.all(20),
            decoration:
                BoxDecoration(
              color:
                  WarnaDesaPay.lightCard,
              borderRadius:
                  BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color:
                      WarnaDesaPay.shadow
                          .withOpacity(
                    0.05,
                  ),
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
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      "Kampanye & Teks Berjalan",
                      style:
                          TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            WarnaDesaPay
                                .textMain,
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

                CustomBounce(
                  onTap:
                      _simpanPerubahanPromo,
                  child:
                      Container(
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
                              .circular(
                        14,
                      ),
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
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.w900,
                              fontSize:
                                  13,
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

          // ====================================================
          // IMPORT EXCEL
          // ====================================================

          Container(
            padding:
                const EdgeInsets.all(20),
            decoration:
                BoxDecoration(
              color:
                  WarnaDesaPay.lightCard,
              borderRadius:
                  BorderRadius.circular(24),
              border:
                  Border.all(
                color:
                    WarnaDesaPay.primary
                        .withOpacity(
                  0.15,
                ),
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
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      "Import Produk Excel",
                      style:
                          TextStyle(
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
                  style:
                      TextStyle(
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
                      const EdgeInsets.all(
                    12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        WarnaDesaPay.primary
                            .withOpacity(
                      0.06,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child:
                      const Row(
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
                          style:
                              TextStyle(
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
                        CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value:
                            _excelProgress /
                                _excelTotal,
                        minHeight: 7,
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
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
                              FontWeight.bold,
                          color:
                              WarnaDesaPay.primary,
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
                    icon:
                        _isLoading
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
                    label:
                        Text(
                      _isLoading
                          ? "MEMPROSES EXCEL..."
                          : "UPLOAD EXCEL PRODUK",
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          WarnaDesaPay.primary,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
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
            style:
                TextStyle(
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

          StreamBuilder<QuerySnapshot>(
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
                  child:
                      Padding(
                    padding:
                        EdgeInsets.all(
                      20,
                    ),
                    child:
                        CircularProgressIndicator(
                      color:
                          WarnaDesaPay.primary,
                    ),
                  ),
                );
              }

              final docs =
                  snapshot.data
                          ?.docs ??
                      [];

              if (docs.isEmpty) {
                return const Center(
                  child:
                      Text(
                    "Belum ada menu custom yang dibuat.",
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
                  final item =
                      docs[index].data()
                          as Map<String,
                              dynamic>;

                  final bool isAktif =
                      item["isAktif"] ??
                          false;

                  return Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          WarnaDesaPay.lightCard,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      border:
                          Border.all(
                        color:
                            WarnaDesaPay.lightField,
                      ),
                    ),
                    child:
                        ListTile(
                      leading:
                          const Icon(
                        Icons
                            .grid_view_rounded,
                        color:
                            WarnaDesaPay.primary,
                      ),
                      title:
                          Text(
                        item["nama"] ??
                            "-",
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      subtitle:
                          Text(
                        "ID Modul: ${item["id"]}",
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
                            WarnaDesaPay.success,
                        onChanged:
                            (val) {
                          _firestore
                              .collection(
                                  "menu_layanan")
                              .doc(
                                  item["id"])
                              .update({
                            "isAktif":
                                val,
                          });
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
  // TAB 2 — PENGGUNA
  // ============================================================

  Widget _buildPanelPengguna() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("users")
          .orderBy(
            "createdAt",
            descending: true,
          )
          .snapshots(),
      builder:
          (context, snapshot) {
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

        final docs =
            snapshot.data?.docs ??
                [];

        if (docs.isEmpty) {
          return const Center(
            child:
                Text(
              "Belum ada pengguna terdaftar.",
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.all(20),
          itemCount:
              docs.length,
          itemBuilder:
              (context, index) {
            final user =
                docs[index].data()
                    as Map<String,
                        dynamic>;

            final userId =
                docs[index].id;

            final bool isBlocked =
                user["isBlocked"] ??
                    false;

            final String kycStatus =
                user["kycStatus"] ??
                    "Belum";

            final String tipeAkun =
                user["tipeAkun"] ??
                    "Basic";

            return Container(
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              padding:
                  const EdgeInsets.all(
                16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    isBlocked
                        ? WarnaDesaPay
                            .danger
                            .withOpacity(
                            0.05,
                          )
                        : WarnaDesaPay
                            .lightCard,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child:
                  Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            WarnaDesaPay
                                .primary
                                .withOpacity(
                          0.1,
                        ),
                        backgroundImage:
                            (user["fotoProfil"] !=
                                        null &&
                                    user["fotoProfil"]
                                        .toString()
                                        .isNotEmpty)
                                ? NetworkImage(
                                    user[
                                        "fotoProfil"],
                                  )
                                : null,
                        child:
                            (user["fotoProfil"] ==
                                        null ||
                                    user["fotoProfil"]
                                        .toString()
                                        .isEmpty)
                                ? const Icon(
                                    Icons.person,
                                    color:
                                        WarnaDesaPay.primary,
                                  )
                                : null,
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              user["nama"] ??
                                  "User Tanpa Nama",
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            Text(
                              user["email"] ??
                                  "-",
                              style:
                                  const TextStyle(
                                fontSize: 11,
                                color:
                                    WarnaDesaPay.textSub,
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
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    tipeAkun ==
                                            "Premium"
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
                            WarnaDesaPay.success,
                        onChanged:
                            (val) {
                          _firestore
                              .collection(
                                  "users")
                              .doc(
                                  userId)
                              .update({
                            "isBlocked":
                                !val,
                          });
                        },
                      ),
                    ],
                  ),

                  const Divider(
                    height: 24,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Saldo: Rp ${_formatCurrency(user["saldo"] ?? 0)}",
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w900,
                          color:
                              WarnaDesaPay.primary,
                        ),
                      ),

                      if (kycStatus ==
                          "Pending")
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
                              fontSize: 11,
                            ),
                          ),
                          onPressed:
                              () =>
                                  _tampilkanDialogReviewKYC(
                            userId,
                            user["nama"],
                            user["fotoKtp"],
                            user["fotoSelfie"],
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
                          onPressed:
                              () =>
                                  _tampilkanDialogEditSaldo(
                            userId,
                            _toInt(
                              user["saldo"],
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
  // REVIEW KYC
  // ============================================================

  void _tampilkanDialogReviewKYC(
    String userId,
    String? nama,
    String? fotoKtp,
    String? fotoSelfie,
  ) {
    showDialog(
      context: context,
      builder: (context) {
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
                  style:
                      TextStyle(
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
                  child:
                      fotoKtp != null &&
                              fotoKtp.isNotEmpty
                          ? Image.network(
                              fotoKtp,
                              fit:
                                  BoxFit.cover,
                            )
                          : const Center(
                              child:
                                  Text(
                                "Tidak ada gambar KTP",
                              ),
                            ),
                ),

                const SizedBox(
                  height: 16,
                ),

                const Text(
                  "Foto Selfie dengan KTP",
                  style:
                      TextStyle(
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
                  child:
                      fotoSelfie != null &&
                              fotoSelfie.isNotEmpty
                          ? Image.network(
                              fotoSelfie,
                              fit:
                                  BoxFit.cover,
                            )
                          : const Center(
                              child:
                                  Text(
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
                await _firestore
                    .collection(
                        "users")
                    .doc(userId)
                    .update({
                  "kycStatus":
                      "Ditolak",
                });

                if (context.mounted) {
                  Navigator.pop(
                    context,
                  );
                }

                _tampilkanSnackBar(
                  "Dokumen ditolak.",
                  isError: true,
                );
              },
              child:
                  const Text(
                "Tolak",
                style:
                    TextStyle(
                  color:
                      WarnaDesaPay.danger,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                await _firestore
                    .collection(
                        "users")
                    .doc(userId)
                    .update({
                  "kycStatus":
                      "Terverifikasi",
                  "tipeAkun":
                      "Premium",
                });

                if (context.mounted) {
                  Navigator.pop(
                    context,
                  );
                }

                _tampilkanSnackBar(
                  "Akun berhasil diupgrade ke PREMIUM!",
                  isError: false,
                );
              },
              child:
                  const Text(
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

  void _tampilkanDialogEditSaldo(
    String userId,
    int saldoSaatIni,
  ) {
    final controller =
        TextEditingController(
      text:
          saldoSaatIni.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            "Adjustment Saldo Manual",
          ),
          content:
              TextField(
            controller:
                controller,
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
                context,
              ),
              child:
                  const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final int? saldo =
                    int.tryParse(
                  controller.text.trim(),
                );

                if (saldo == null ||
                    saldo < 0) {
                  _tampilkanSnackBar(
                    "Saldo tidak valid.",
                    isError: true,
                  );
                  return;
                }

                await _firestore
                    .collection(
                        "users")
                    .doc(userId)
                    .update({
                  "saldo":
                      saldo,
                });

                if (context.mounted) {
                  Navigator.pop(
                    context,
                  );
                }

                _tampilkanSnackBar(
                  "Saldo berhasil diubah.",
                  isError: false,
                );
              },
              child:
                  const Text(
                "Simpan",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // TAB 3 — KEUANGAN
  // ============================================================

  Widget _buildPanelKeuangan() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          // ====================================================
          // MARKUP PER JENIS
          // ====================================================

          Container(
            padding:
                const EdgeInsets.all(20),
            decoration:
                BoxDecoration(
              color:
                  WarnaDesaPay.lightCard,
              borderRadius:
                  BorderRadius.circular(24),
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
                          WarnaDesaPay.success,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      "Markup Harga Layanan",
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w900,
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
                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        WarnaDesaPay.textSub,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                _buildMarkupInput(
                  icon:
                      Icons.phone_android_rounded,
                  title:
                      "Pulsa",
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
                  title:
                      "Lainnya",
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
                    icon:
                        const Icon(
                      Icons.save_rounded,
                    ),
                    label:
                        const Text(
                      "SIMPAN SEMUA MARKUP",
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          WarnaDesaPay.success,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
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
          // TERAPKAN KE PRODUK LAMA
          // ====================================================

          Container(
            padding:
                const EdgeInsets.all(18),
            decoration:
                BoxDecoration(
              color:
                  WarnaDesaPay.warning
                      .withOpacity(
                0.08,
              ),
              borderRadius:
                  BorderRadius.circular(20),
              border:
                  Border.all(
                color:
                    WarnaDesaPay.warning
                        .withOpacity(
                  0.25,
                ),
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
                          .sync_rounded,
                      color:
                          WarnaDesaPay.warning,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      "Sinkronisasi Harga Produk",
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w900,
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
                  style:
                      TextStyle(
                    fontSize: 11,
                    color:
                        WarnaDesaPay.textSub,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                if (_isLoading &&
                    _syncTotal > 0)
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value:
                            _syncProgress /
                                _syncTotal,
                        minHeight: 7,
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        "Update "
                        "$_syncProgress / "
                        "$_syncTotal produk...",
                        style:
                            const TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.bold,
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
                    icon:
                        const Icon(
                      Icons.sync_rounded,
                    ),
                    label:
                        const Text(
                      "TERAPKAN KE SEMUA PRODUK",
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          WarnaDesaPay.warning,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
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
              DocumentSnapshot>(
            stream: _firestore
                .collection(
                    "pengaturan")
                .doc(
                    "finansial")
                .snapshots(),
            builder:
                (context, snapshot) {
              int saldoDigi = 0;
              int saldoTri = 0;

              if (snapshot.hasData &&
                  snapshot.data!.exists) {
                final data =
                    snapshot.data!.data()
                        as Map<String,
                            dynamic>;

                saldoDigi =
                    _toInt(
                  data[
                      "saldoDigiflazz"],
                );

                saldoTri =
                    _toInt(
                  data[
                      "saldoTriPay"],
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
                      WarnaDesaPay.primary,
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
                      Icons.payment_rounded,
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
            style:
                TextStyle(
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
  // INPUT MARKUP
  // ============================================================

  Widget _buildMarkupInput({
    required IconData icon,
    required String title,
    required String subtitle,
    required TextEditingController controller,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            WarnaDesaPay.lightBg,
        borderRadius:
            BorderRadius.circular(16),
        border:
            Border.all(
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
              color:
                  WarnaDesaPay.primary
                      .withOpacity(
                0.1,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                Icon(
              icon,
              color:
                  WarnaDesaPay.primary,
              size: 21,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        WarnaDesaPay.textSub,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: 110,
            child:
                TextField(
              controller:
                  controller,
              keyboardType:
                  TextInputType.number,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w900,
              ),
              decoration:
                  InputDecoration(
                prefixText:
                    "Rp ",
                prefixStyle:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                filled:
                    true,
                fillColor:
                    Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSAKSI
  // ============================================================

  Widget _buildTransaksiStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("transaksi")
          .orderBy(
            "waktu",
            descending: true,
          )
          .limit(50)
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

        final docs =
            snapshot.data?.docs ??
                [];

        if (docs.isEmpty) {
          return const Center(
            child:
                Text(
              "Belum ada log transaksi.",
            ),
          );
        }

        return ListView.builder(
          shrinkWrap:
              true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount:
              docs.length,
          itemBuilder:
              (context, index) {
            final log =
                docs[index].data()
                    as Map<String,
                        dynamic>;

            final String status =
                (log["status"] ??
                        "PENDING")
                    .toString()
                    .toUpperCase();

            Color statusColor =
                WarnaDesaPay.warning;

            if (status.contains(
                    "SUKSES") ||
                status.contains(
                    "BERHASIL")) {
              statusColor =
                  WarnaDesaPay.success;
            } else if (status
                .contains("GAGAL")) {
              statusColor =
                  WarnaDesaPay.danger;
            }

            return Container(
              margin:
                  const EdgeInsets.only(
                bottom: 14,
              ),
              padding:
                  const EdgeInsets.all(
                16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    WarnaDesaPay.lightCard,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                              FontWeight.w900,
                          fontSize:
                              10,
                        ),
                      ),
                      Text(
                        "Rp ${_formatCurrency(log["hargaJual"] ?? log["price"] ?? 0)}",
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w900,
                          fontSize:
                              14,
                        ),
                      ),
                    ],
                  ),

                  const Divider(),

                  _buildDetailRow(
                    "Produk",
                    log["product_name"] ??
                        log["buyer_sku_code"] ??
                        "-",
                  ),

                  _buildDetailRow(
                    "Jenis",
                    log["jenisLayanan"] ??
                        "-",
                  ),

                  _buildDetailRow(
                    "Tujuan",
                    log["customer_no"] ??
                        log["tujuan"] ??
                        "-",
                  ),

                  _buildDetailRow(
                    "SN/Reff",
                    log["sn"] ??
                        log["message"] ??
                        "-",
                  ),

                  _buildDetailRow(
                    "Waktu",
                    _formatDate(
                      log["waktu"]
                          as Timestamp?,
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
        color:
            color.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(16),
        border:
            Border.all(
          color:
              color.withOpacity(0.3),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                color,
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            title,
            style:
                TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.bold,
              color:
                  color,
            ),
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

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child:
          Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(
              color:
                  WarnaDesaPay.textSub,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          Expanded(
            child:
                Text(
              value,
              textAlign:
                  TextAlign.end,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 4 — SISTEM
  // ============================================================

  Widget _buildPanelSistem() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("system_logs")
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

        final docs =
            snapshot.data?.docs ??
                [];

        if (docs.isEmpty) {
          return const Center(
            child:
                Text(
              "Sistem Berjalan Aman",
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.all(20),
          itemCount:
              docs.length,
          itemBuilder:
              (context, index) {
            final log =
                docs[index].data()
                    as Map<String,
                        dynamic>;

            final String tipe =
                log["tipe"] ??
                    "INFO";

            final String pesan =
                log["pesan"] ??
                    "-";

            return Container(
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color:
                    WarnaDesaPay.lightCard,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    tipe,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize:
                          10,
                      color:
                          WarnaDesaPay.primary,
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
    );
  }

  // ============================================================
  // TAB 5 — TIKET CS
  // ============================================================

  Widget _buildPanelTiketCS() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(
              "keluhan_pelanggan")
          .orderBy(
            "waktuMasuk",
            descending: true,
          )
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

        final docs =
            snapshot.data?.docs ??
                [];

        if (docs.isEmpty) {
          return const Center(
            child:
                Text(
              "Inbox Bersih!",
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.all(20),
          itemCount:
              docs.length,
          itemBuilder:
              (context, index) {
            final tiket =
                docs[index].data()
                    as Map<String,
                        dynamic>;

            final tiketId =
                docs[index].id;

            final String status =
                tiket["status"] ??
                    "Pending";

            final String balasan =
                tiket["balasanAdmin"] ??
                    "";

            return Container(
              margin:
                  const EdgeInsets.only(
                bottom: 14,
              ),
              padding:
                  const EdgeInsets.all(
                16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    WarnaDesaPay.lightCard,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text(
                        tiket["namaUser"] ??
                            "Anonymous",
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      DropdownButton<
                          String>(
                        value:
                            status,
                        items: [
                          "Pending",
                          "Proses",
                          "Selesai",
                        ].map(
                          (value) {
                            return DropdownMenuItem<
                                String>(
                              value:
                                  value,
                              child:
                                  Text(
                                value,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged:
                            (value) {
                          if (value !=
                              null) {
                            _firestore
                                .collection(
                                    "keluhan_pelanggan")
                                .doc(
                                    tiketId)
                                .update({
                              "status":
                                  value,
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  Text(
                    "Kontak: ${tiket["phoneUser"] ?? "-"}",
                    style:
                        const TextStyle(
                      color:
                          WarnaDesaPay.primary,
                      fontSize:
                          12,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.all(
                      10,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          WarnaDesaPay.lightField,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                    child:
                        Text(
                      "\"${tiket["pesan"] ?? "-"}\"",
                      style:
                          const TextStyle(
                        fontSize:
                            12,
                        fontStyle:
                            FontStyle.italic,
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
                            WarnaDesaPay.success,
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                  Align(
                    alignment:
                        Alignment.centerRight,
                    child:
                        TextButton.icon(
                      icon:
                          const Icon(
                        Icons.reply_rounded,
                        size:
                            16,
                      ),
                      label:
                          Text(
                        balasan.isEmpty
                            ? "Balas Pesan"
                            : "Edit Balasan",
                      ),
                      onPressed:
                          () =>
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

  void _tampilkanDialogBalasCS(
    String tiketId,
    String balasanLama,
  ) {
    final controller =
        TextEditingController(
      text:
          balasanLama,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            "Balas Tiket Pengguna",
          ),
          content:
              TextField(
            controller:
                controller,
            maxLines:
                4,
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
                context,
              ),
              child:
                  const Text(
                "Batal",
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final String balasan =
                    controller.text
                        .trim();

                if (balasan.isEmpty) {
                  return;
                }

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
                });

                if (context.mounted) {
                  Navigator.pop(
                    context,
                  );
                }

                _tampilkanSnackBar(
                  "Balasan berhasil dikirim.",
                  isError: false,
                );
              },
              child:
                  const Text(
                "Kirim Balasan",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MODERN INPUT
  // ============================================================

  Widget _buildModernInput({
    required BuildContext context,
    required TextEditingController controller,
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
          controller:
              controller,
          maxLines:
              maxLines,
          style:
              const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w700,
          ),
          decoration:
              InputDecoration(
            hintText:
                hint,
            filled:
                true,
            fillColor:
                WarnaDesaPay.lightBg,
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
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
}
