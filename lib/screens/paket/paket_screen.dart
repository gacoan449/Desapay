import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium saat Paket Data Dipilih
class CustomBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const CustomBounce({super.key, required this.child, required this.onTap});

  @override
  State<CustomBounce> createState() => _CustomBounceState();
}

class _CustomBounceState extends State<CustomBounce> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

class PaketScreen extends StatefulWidget {
  const PaketScreen({super.key});

  @override
  State<PaketScreen> createState() => _PaketScreenState();
}

class _PaketScreenState extends State<PaketScreen> {
  final TextEditingController nomorController = TextEditingController();
  final DigiflazzService _digiflazzService = DigiflazzService();
  List<dynamic> daftarPaket = [];
  bool loading = false;
  String operator = "";

  @override
  void dispose() {
    nomorController.dispose();
    super.dispose();
  }

  //==========================================
  // DETEKSI OPERATOR OTOMATIS & STYLE BRAND
  //==========================================
  void deteksiOperator(String nomor) {
    if (nomor.length < 4) {
      setState(() {
        operator = "";
        daftarPaket.clear();
      });
      return;
    }

    final prefix = nomor.substring(0, 4);

    if (["0811","0812","0813","0821","0822","0823","0851","0852","0853"].contains(prefix)) {
      operator = "TELKOMSEL";
    } else if (["0814","0815","0816","0855","0856","0857","0858"].contains(prefix)) {
      operator = "INDOSAT";
    } else if (["0817","0818","0819","0859","0877","0878"].contains(prefix)) {
      operator = "XL";
    } else if (["0831","0832","0833","0838"].contains(prefix)) {
      operator = "AXIS";
    } else if (["0895","0896","0897","0898","0899"].contains(prefix)) {
      operator = "THREE";
    } else if (["0881","0882","0883","0884","0885","0886","0887","0888","0889"].contains(prefix)) {
      operator = "SMARTFREN";
    } else {
      operator = "";
    }

    setState(() {});

    if (operator.isNotEmpty) {
      ambilProduk(operator);
    } else {
      daftarPaket.clear();
    }
  }

  Color _getOperatorColor() {
    switch (operator) {
      case "TELKOMSEL": return const Color(0xFFE52229);
      case "INDOSAT": return const Color(0xFFFFD200);
      case "XL": return const Color(0xFF0054A6);
      case "AXIS": return const Color(0xFF8338EC);
      case "THREE": return const Color(0xFF9B5DE5);
      case "SMARTFREN": return const Color(0xFFFF1493);
      default: return Colors.grey;
    }
  }

  //==========================================
  // AMBIL PRODUK DARI DIGIFLAZZ
  //==========================================
  Future<void> ambilProduk(String brand) async {
    setState(() => loading = true);
    try {
      final semuaProduk = await _digiflazzService.ambilSemuaProduk();
      daftarPaket = semuaProduk.where((item) {
        final kategori = (item["category"] ?? "").toString().toUpperCase();
        final merk = (item["brand"] ?? "").toString().toUpperCase();
        return kategori.contains("DATA") && merk.contains(brand);
      }).toList();

      daftarPaket.sort((a, b) => (int.tryParse(a["price"].toString()) ?? 0).compareTo(int.tryParse(b["price"].toString()) ?? 0));
    } catch (e) {
      daftarPaket = [];
    }
    setState(() => loading = false);
  }

  int hargaJual(int modal) {
    if (modal < 10000) return modal + 1000;
    if (modal < 50000) return modal + 1500;
    if (modal < 100000) return modal + 2000;
    return modal + 3000;
  }

  String rupiah(int angka) {
    return angka.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        title: const Text(
          "Paket Data Internet",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nomor Tujuan Pengisian",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nomorController,
                  keyboardType: TextInputType.phone,
                  onChanged: deteksiOperator,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    hintText: "Contoh: 08xxxxxxxxxx",
                    hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 0),
                    prefixIcon: Icon(Icons.phone_android_rounded, color: WarnaDesaPay.primary),
                    suffixIcon: operator.isEmpty
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getOperatorColor(),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    operator,
                                    style: TextStyle(
                                      color: operator == "INDOSAT" ? Colors.black87 : Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              "Pilih Paket Internet Tersedia",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade800),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : daftarPaket.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.signal_wifi_connected_no_internet_4_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              nomorController.text.length < 4
                                  ? "Masukkan nomor HP tujuan terlebih dahulu."
                                  : "Tidak ada produk kuota untuk operator ini.",
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        itemCount: daftarPaket.length,
                        itemBuilder: (context, index) {
                          final produk = daftarPaket[index];
                          final int modal = int.tryParse(produk["price"].toString()) ?? 0;
                          final int jual = hargaJual(modal);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              title: Text(
                                produk["product_name"] ?? "",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  produk["desc"] ?? "Produk Paket Data",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.3),
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Rp ${rupiah(jual)}",
                                    style: TextStyle(color: WarnaDesaPay.primary, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Kode: ${produk["buyer_sku_code"]}",
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                  ),
                                ],
                              ),
                              onTap: () => _prosesBottomSheetInvoice(produk, jual),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  //==========================================
  // PREMIUM BOTTOM SHEET INVOICE
  //==========================================
  void _prosesBottomSheetInvoice(dynamic produk, int jual) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Konfirmasi Pembayaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildInvoiceRow("Nama Layanan", "Paket Data Internet"),
              _buildInvoiceRow("Nama Paket", produk["product_name"] ?? ""),
              _buildInvoiceRow("Nomor Tujuan", nomorController.text),
              _buildInvoiceRow("Operator", operator),
              _buildInvoiceRow("Metode Pembayaran", "Saldo Utama DesaPay"),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Tagihan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    "Rp ${rupiah(jual)}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WarnaDesaPay.primary),
                  )
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarnaDesaPay.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _eksekusiTransaksiPusat(produk, jual);
                  },
                  child: const Text("Konfirmasi & Bayar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          // DIKOREKSI: Mengganti Alignment.centerRight menjadi TextAlign.end yang valid untuk widget Text
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  //==========================================
  // EKSEKUSI API & DIGITAL SLIP RECEIPT
  //==========================================
  void _eksekusiTransaksiPusat(dynamic produk, int jual) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final hasil = await _digiflazzService.kirimTransaksi(
      buyerSkuCode: produk["buyer_sku_code"],
      customerNo: nomorController.text,
    );

    if (mounted) Navigator.pop(context);

    String status = (hasil["status"] ?? "PENDING").toString().toUpperCase();
    String pesan = hasil["message"] ?? hasil["sn"] ?? "Transaksi sedang diproses antrean server.";

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          bool isSukses = status == "SUKSES";
          bool isGagal = status == "GAGAL";

          Color statusColor = Colors.orange;
          IconData statusIcon = Icons.access_time_rounded;

          if (isSukses) {
            statusColor = Colors.green;
            statusIcon = Icons.check_circle_rounded;
          } else if (isGagal) {
            statusColor = Colors.red;
            statusIcon = Icons.cancel_rounded;
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 72, color: statusColor),
                const SizedBox(height: 16),
                Text(
                  isSukses ? "Transaksi Sukses" : isGagal ? "Transaksi Gagal" : "Transaksi Diproses",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildInvoiceRow("Produk", produk["product_name"] ?? ""),
                      _buildInvoiceRow("Nomor Tujuan", nomorController.text),
                      _buildInvoiceRow("Total Bayar", "Rp ${rupiah(jual)}"),
                      _buildInvoiceRow("Keterangan/SN", pesan),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (!isGagal) {
                        nomorController.clear();
                        setState(() {
                          operator = "";
                          daftarPaket.clear();
                        });
                      }
                    },
                    child: const Text("Selesai", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }
}
