import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium saat Produk Pulsa Dipilih
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
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
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

class PulsaScreen extends StatefulWidget {
  const PulsaScreen({super.key});

  @override
  State<PulsaScreen> createState() => _PulsaScreenState();
}

class _PulsaScreenState extends State<PulsaScreen> {
  final TextEditingController nomorController = TextEditingController();
  final DigiflazzService _digiflazzService = DigiflazzService();
  List<dynamic> _daftarPulsaReguler = [];
  bool _sedangMemuat = false;
  String _operatorTerdeteksi = "";

  @override
  void dispose() {
    nomorController.dispose();
    super.dispose();
  }

  //==================================================
  // DETEKSI OPERATOR OTOMATIS
  //==================================================
  void _deteksiOperatorOtomatis(String nomor) {
    if (nomor.length < 4) {
      setState(() {
        _operatorTerdeteksi = "";
        _daftarPulsaReguler = [];
      });
      return;
    }

    String prefix = nomor.substring(0, 4);
    String operator = "";

    if (["0811", "0812", "0813", "0821", "0822", "0823", "0851", "0852", "0853"].contains(prefix)) {
      operator = "TELKOMSEL";
    } else if (["0814", "0815", "0816", "0855", "0856", "0857", "0858"].contains(prefix)) {
      operator = "INDOSAT";
    } else if (["0817", "0818", "0819", "0877", "0878", "0859"].contains(prefix)) {
      operator = "XL";
    } else if (["0831", "0832", "0833", "0838"].contains(prefix)) {
      operator = "AXIS";
    } else if (["0895", "0896", "0897", "0898", "0899"].contains(prefix)) {
      operator = "THREE";
    } else if (["0881", "0882", "0883", "0884", "0885", "0886", "0887", "0888", "0889"].contains(prefix)) {
      operator = "SMARTFREN";
    }

    if (operator != _operatorTerdeteksi && operator.isNotEmpty) {
      setState(() {
        _operatorTerdeteksi = operator;
      });
      _ambilProdukPulsa(operator);
    }
  }

  Color _getOperatorColor() {
    switch (_operatorTerdeteksi) {
      case "TELKOMSEL": return const Color(0xFFE52229);
      case "INDOSAT": return const Color(0xFFFFD200);
      case "XL": return const Color(0xFF0054A6);
      case "AXIS": return const Color(0xFF8338EC);
      case "THREE": return const Color(0xFF9B5DE5);
      case "SMARTFREN": return const Color(0xFFFF1493);
      default: return Colors.grey;
    }
  }

  //==================================================
  // AMBIL PRODUK DIGIFLAZZ
  //==================================================
  Future<void> _ambilProdukPulsa(String operator) async {
    setState(() => _sedangMemuat = true);
    try {
      List<dynamic> semuaProduk = await _digiflazzService.ambilSemuaProduk();
      List<dynamic> hasil = semuaProduk.where((item) {
        String kategori = (item["category"] ?? "").toString().toUpperCase();
        String brand = (item["brand"] ?? "").toString().toUpperCase();
        return kategori == "PULSA" && brand.contains(operator);
      }).toList();

      hasil.sort((a, b) => (int.tryParse(a["price"].toString()) ?? 0).compareTo(int.tryParse(b["price"].toString()) ?? 0));
      setState(() => _daftarPulsaReguler = hasil);
    } catch (_) {
      setState(() => _daftarPulsaReguler = []);
    }
    setState(() => _sedangMemuat = false);
  }

  String rupiah(dynamic angka) {
    int value = int.tryParse(angka.toString()) ?? 0;
    return value.toString().replaceAllMapped(
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
          "Isi Ulang Pulsa",
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
          // CONTAINER INPUT FIELD NOMOR HP PREMIUM
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nomor Handphone Tujuan",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nomorController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  onChanged: (value) {
                    setState(() {});
                    _deteksiOperatorOtomatis(value);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    hintText: "Contoh: 08xxxxxxxxxx",
                    hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 0),
                    prefixIcon: Icon(Icons.phone_android_rounded, color: WarnaDesaPay.primary),
                    suffixIcon: _operatorTerdeteksi.isEmpty
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
                                    _operatorTerdeteksi,
                                    style: TextStyle(
                                      color: _operatorTerdeteksi == "INDOSAT" ? Colors.black87 : Colors.white,
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
          if (_operatorTerdeteksi.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                "Pilih Nominal Pulsa Reguler",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade800),
              ),
            ),
          // GRID NOMINAL DENGAN CUSTOM BOUNCE MICRO-INTERACTION
          Expanded(
            child: _sedangMemuat
                ? const Center(child: CircularProgressIndicator())
                : nomorController.text.length < 4
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.contact_phone_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text("Masukkan nomor HP untuk memuat katalog pulsa.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      )
                    : _daftarPulsaReguler.isEmpty
                        ? const Center(child: Text("Produk pulsa tidak tersedia untuk operator ini.", style: TextStyle(color: Colors.grey)))
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            itemCount: _daftarPulsaReguler.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.3,
                            ),
                            itemBuilder: (context, index) {
                              final produk = _daftarPulsaReguler[index];
                              return CustomBounce(
                                onTap: () => _prosesBottomSheetInvoice(produk),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        produk["product_name"] ?? "-",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "Rp ${rupiah(produk["price"])}",
                                        style: TextStyle(color: WarnaDesaPay.primary, fontWeight: FontWeight.w900, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  //==================================================
  // PREMIUM BOTTOM SHEET INVOICE
  //==================================================
  void _prosesBottomSheetInvoice(dynamic produk) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24, left: 24, right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text("Konfirmasi Pembayaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildInvoiceRow("Jenis Layanan", "Isi Ulang Pulsa Reguler"),
              _buildInvoiceRow("Produk Kategori", produk["product_name"] ?? "-"),
              _buildInvoiceRow("Nomor Tujuan", nomorController.text),
              _buildInvoiceRow("Operator Seluler", _operatorTerdeteksi),
              _buildInvoiceRow("Sumber Pembayaran", "Saldo Utama DesaPay"),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Pembayaran", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    "Rp ${rupiah(produk["price"])}",
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
                    _eksekusiTransaksiAPI(produk);
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
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  //==================================================
  // EKSEKUSI API & DIGITAL RESI SLIP SHEET
  //==================================================
  void _eksekusiTransaksiAPI(dynamic produk) async {
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
    String pesanServer = hasil["sn"] ?? hasil["message"] ?? "Transaksi sedang diproses antrean server pusat.";

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
                      _buildInvoiceRow("Produk", produk["product_name"] ?? "-"),
                      _buildInvoiceRow("Nomor HP", nomorController.text),
                      _buildInvoiceRow("Total Bayar", "Rp ${rupiah(produk["price"])}"),
                      _buildInvoiceRow("Serial Number / Ref", pesanServer),
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
                          _operatorTerdeteksi = "";
                          _daftarPulsaReguler.clear();
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
