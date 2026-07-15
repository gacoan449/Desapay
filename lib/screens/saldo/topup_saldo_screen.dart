import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart';
import 'payment_screen.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium saat Chip / Tombol Ditekan
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

class TopupSaldoScreen extends StatefulWidget {
  const TopupSaldoScreen({super.key});

  @override
  State<TopupSaldoScreen> createState() => _TopupSaldoScreenState();
}

class _TopupSaldoScreenState extends State<TopupSaldoScreen> {
  final DigiflazzService _digiflazzService = DigiflazzService();
  final TextEditingController _nominalController = TextEditingController();
  int _saldo = 0;
  bool _loadingSaldo = true;

  @override
  void initState() {
    super.initState();
    _ambilSaldo();
  }

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _ambilSaldo() async {
    try {
      final saldo = await _digiflazzService.cekSaldoModal();
      if (!mounted) return;
      setState(() {
        _saldo = saldo;
        _loadingSaldo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSaldo = false);
    }
  }

  String rupiah(int angka) {
    String hasil = angka.toString();
    final reg = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return "Rp ${hasil.replaceAllMapped(reg, (m) => "${m[1]}.")}";
  }

  void _setNominalPintas(String value) {
    setState(() {
      _nominalController.text = value;
    });
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
          "Isi Saldo Akun",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. PREMIUM BLUE GRADIENT WALLET CARD
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [WarnaDesaPay.primary, const Color(0xFF007BE6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: WarnaDesaPay.primary.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, color: Colors.white.withOpacity(0.7), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "Saldo Agen / Modal Saat Ini",
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _loadingSaldo
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          rupiah(_saldo),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                        ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Saldo Digiflazz otomatis dicadangkan aman untuk jalur PPOB.",
                            // DIKOREKSI: Mengganti token non-standar Colors.whiteEE dengan standard SDK safety opacity
                            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11, height: 1.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text("Masukkan Nominal Pengisian", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 12),

            // ==========================================
            // 3. MODERN FLOATING INPUT FIELD
            // ==========================================
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixText: "Rp ",
                prefixStyle: TextStyle(color: WarnaDesaPay.primary, fontWeight: FontWeight.bold, fontSize: 20),
                hintText: "0",
                hintStyle: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.normal),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: WarnaDesaPay.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text("* Batas minimal deposit nominal adalah Rp10.000", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // 2. INSTANT NOMINAL SHORTCUT CHIPS
            // ==========================================
            Row(
              children: [
                Expanded(child: _buildShortcutChip("50.000", "50000")),
                const SizedBox(width: 10),
                Expanded(child: _buildShortcutChip("100.000", "100000")),
                const SizedBox(width: 10),
                Expanded(child: _buildShortcutChip("200.000", "200000")),
                const SizedBox(width: 10),
                Expanded(child: _buildShortcutChip("500.000", "500000")),
              ],
            ),

            const SizedBox(height: 36),

            // ACTION BUTTON CONTROLLER DENGAN CUSTOM BOUNCE
            CustomBounce(
              onTap: () {
                final nominal = int.tryParse(_nominalController.text.replaceAll(".", "").replaceAll(" ", ""));
                if (nominal == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mohon input nominal pengisian saldo!"), behavior: SnackBarBehavior.floating),
                  );
                  return;
                }
                if (nominal < 10000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Batas pengisian saldo minimal Rp10.000"), behavior: SnackBarBehavior.floating),
                  );
                  return;
                }
                _prosesBottomSheetInvoice(nominal);
              },
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: WarnaDesaPay.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: WarnaDesaPay.primary.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  "BUAT TIKET DEPOSIT",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // PETUNJUK DOKUMENTASI STRUKTUR CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 18),
                      const SizedBox(width: 8),
                      Text("Panduan Prosedur Pengisian Saldo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "1. Sistem input nominal bersifat bebas kelipatan terhitung di atas batas minimum.\n"
                    "2. After kode invoice tiket berhasil diterbitkan, silakan lakukan proses transfer dana sesuai angka nominal presisi.\n"
                    "3. Saldo akun DesaPay akan otomatis disinkronisasi bertambah secara otomatis setelah jaringan bank Digiflazz mengonfirmasi data pembayaran.",
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutChip(String label, String rawValue) {
    return CustomBounce(
      onTap: () => _setNominalPintas(rawValue),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WarnaDesaPay.primary),
        ),
      ),
    );
  }

  // ==========================================
  // 4. PREMIUM BOTTOM SHEET INVOICE
  // ==========================================
  void _prosesBottomSheetInvoice(int nominal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              const Text("Konfirmasi Tiket Deposit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildInvoiceRow("Jenis Layanan", "Top Up Saldo Akun"),
              _buildInvoiceRow("Jalur Gateway", "API Digiflazz Otomatis"),
              _buildInvoiceRow("Status Permintaan", "PENDING VERIFIKASI"),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Pengisian", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    rupiah(nominal),
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
                    _prosesMintaTiket(nominal);
                  },
                  child: const Text("Konfirmasi & Minta Tiket", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Future<void> _prosesMintaTiket(int nominal) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final hasil = await _digiflazzService.mintaTiketDeposit(jumlahNominal: nominal);

    if (mounted) Navigator.pop(context);

    if (hasil.isNotEmpty && hasil["rc"] == "00") {
      final dataPembayaran = {
        "data": {
          "payment_name": "Transfer Bank ${hasil["bank"] ?? "BCA"}",
          "amount": hasil["amount"] ?? nominal,
          "reference": hasil["deposit_id"] ?? "DEP-${DateTime.now().millisecondsSinceEpoch}",
          "status": hasil["status"] ?? "UNPAID",
          "pay_code": hasil["pay_code"] ?? hasil["owner_name"] ?? "-",
          "qr_url": hasil["qr_url"],
        }
      };

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(data: dataPembayaran),
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        content: Text(hasil["message"] ?? "Gagal memproses tiket deposit sistem pusat."),
      ),
    );
  }
}
