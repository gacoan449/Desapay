import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium saat Tombol Ditekan
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

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const PaymentScreen({
    super.key,
    required this.data,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final DigiflazzService _digiflazzService = DigiflazzService();
  late Map<String, dynamic> _currentTxData;

  @override
  void initState() {
    super.initState();
    _currentTxData = widget.data["data"] ?? {};
  }

  Future<void> _periksaStatusPembayaran() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int nominalAngka = int.tryParse(_currentTxData["amount"].toString()) ?? 0;

    Map<String, dynamic> hasilTerbaru = await _digiflazzService.cekStatusDeposit(
      jumlahNominal: nominalAngka,
    );

    if (mounted) Navigator.pop(context);

    setState(() {
      if (hasilTerbaru.isNotEmpty && hasilTerbaru['rc'] == '00') {
        _currentTxData["status"] = "PAID / BERHASIL";
      } else {
        _currentTxData["status"] = hasilTerbaru["message"] ?? "UNPAID / BELUM BAYAR";
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status Terbaru: ${_currentTxData["status"]}"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: WarnaDesaPay.primary,
        ),
      );
    }
  }

  String rupiah(dynamic angka) {
    int value = int.tryParse(angka.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Color _getStatusColor() {
    String status = (_currentTxData["status"] ?? "UNPAID").toString().toUpperCase();
    if (status.contains("PAID") || status.contains("BERHASIL") || status.contains("SUKSES")) {
      return Colors.green.shade600;
    } else if (status.contains("FAIL") || status.contains("GAGAL")) {
      return Colors.red.shade600;
    }
    return Colors.orange.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor();
    final String statusText = (_currentTxData["status"] ?? "UNPAID").toString().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        title: const Text(
          "Invoice Pembayaran",
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
          children: [
            // ==========================================
            // 1. PREMIUM INVOICE TICKET HEADER LAYOUT
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusText.contains("PAID") || statusText.contains("BERHASIL")
                          ? Icons.check_circle_rounded
                          : Icons.receipt_long_rounded,
                      size: 42,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentTxData["payment_name"] ?? "Deposit Saldo DesaPay",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Detail instruksi invoice pengisian saldo akun",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  _buildInvoiceRow("Total Pembayaran", "Rp ${rupiah(_currentTxData["amount"])}", isHighlight: true),
                  _buildInvoiceRow("Nomor Referensi", _currentTxData["reference"] ?? "REF-AUTOMATIC"),
                  _buildInvoiceRow("Status Tiket", statusText, valueColor: statusColor, isStatus: true),
                  if (_currentTxData["pay_code"] != null)
                    _buildInvoiceRow("Kode Bayar / Pemilik", _currentTxData["pay_code"].toString()),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // ==========================================
            // 2. INTERACTIVE QRIS DISPLAY BOX
            // ==========================================
            if (_currentTxData["qr_url"] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 18, color: Colors.black87),
                        SizedBox(width: 8),
                        Text(
                          "Metode Pembayaran QRIS",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Simpan atau screenshot kode QRIS di bawah ini",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _currentTxData["qr_url"],
                          height: 230,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return const SizedBox(
                              height: 230,
                              child: Center(
                                child: Text("Gagal memuat gambar QRIS dari server.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // ==========================================
            // 3. CUSTOMBOUNCE ON REFRESH ACTION
            // ==========================================
            CustomBounce(
              onTap: _periksaStatusPembayaran,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: WarnaDesaPay.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: WarnaDesaPay.primary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "CEK STATUS TRANSAKSI",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {bool isHighlight = false, Color? valueColor, bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isHighlight || isStatus ? FontWeight.bold : FontWeight.w600,
                fontSize: isHighlight ? 16 : 13,
                color: valueColor ?? (isHighlight ? WarnaDesaPay.primary : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
