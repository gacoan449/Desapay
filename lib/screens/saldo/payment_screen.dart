import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import Konfigurasi & Widget Modular Utama (CTO Standard)
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart';
import '../../widgets/menu_item.dart'; // Memuat CustomBounce dari sumber tunggal

/// Layar Instruksi dan Tagihan Pembayaran (Invoice) DesaPay
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
    // Mengamankan data injeksi awal agar tidak null
    _currentTxData = widget.data["data"] ?? {};
  }

  /// Memanggil API untuk memverifikasi status pembayaran mutakhir secara Real-time
  Future<void> _periksaStatusPembayaran() async {
    // Menampilkan loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: WarnaDesaPay.primary),
      ),
    );

    final int nominalAngka = int.tryParse(_currentTxData["amount"].toString()) ?? 0;

    // Memanggil servis core
    final Map<String, dynamic> hasilTerbaru = await _digiflazzService.cekStatusDeposit(
      jumlahNominal: nominalAngka,
    );

    // Menutup loading overlay dengan aman
    if (!mounted) return;
    Navigator.pop(context);

    // Memperbarui UI State
    setState(() {
      if (hasilTerbaru.isNotEmpty && hasilTerbaru['rc'] == '00') {
        _currentTxData["status"] = "PAID / BERHASIL";
      } else {
        _currentTxData["status"] = hasilTerbaru["message"] ?? "UNPAID / BELUM BAYAR";
      }
    });

    _tampilkanNotifikasi("Status Terbaru: ${_currentTxData["status"]}");
  }

  /// Helper Notifikasi Moduler
  void _tampilkanNotifikasi(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pesan, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: WarnaDesaPay.primary,
      ),
    );
  }

  /// Standardisasi Format Mata Uang Menggunakan Package `intl`
  String _formatRupiah(dynamic angka) {
    final int value = int.tryParse(angka.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  /// Helper cerdas penentu warna indikator transaksi
  Color _getStatusColor(String status) {
    final String safeStatus = status.toUpperCase();
    if (safeStatus.contains("PAID") || safeStatus.contains("BERHASIL") || safeStatus.contains("SUKSES")) {
      return WarnaDesaPay.success;
    } else if (safeStatus.contains("FAIL") || safeStatus.contains("GAGAL")) {
      return WarnaDesaPay.danger;
    }
    return WarnaDesaPay.warning; // Default untuk UNPAID / PENDING
  }

  @override
  Widget build(BuildContext context) {
    final String statusText = (_currentTxData["status"] ?? "UNPAID").toString().toUpperCase();
    final Color statusColor = _getStatusColor(statusText);
    final bool isSukses = statusText.contains("PAID") || statusText.contains("BERHASIL");

    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Invoice Pembayaran",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3),
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
            // 1. KARTU TIKET INVOICE (PREMIUM RECEIPT LAYOUT)
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: WarnaDesaPay.lightCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: WarnaDesaPay.shadow.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSukses ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                      size: 46,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentTxData["payment_name"] ?? "Deposit Saldo DesaPay",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: WarnaDesaPay.textMain),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Detail instruksi invoice pengisian saldo akun",
                    style: TextStyle(fontSize: 12, color: WarnaDesaPay.textSub, fontWeight: FontWeight.w500),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(height: 1, color: WarnaDesaPay.lightField),
                  ),
                  
                  _buildInvoiceRow("Total Pembayaran", _formatRupiah(_currentTxData["amount"]), isHighlight: true),
                  _buildInvoiceRow("Nomor Referensi", _currentTxData["reference"] ?? "REF-AUTOMATIC"),
                  _buildInvoiceRow("Status Tiket", statusText, valueColor: statusColor, isStatus: true),
                  if (_currentTxData["pay_code"] != null)
                    _buildInvoiceRow("Kode Bayar / Virtual", _currentTxData["pay_code"].toString()),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // ==========================================
            // 2. KOTAK TAMPILAN QRIS INTERAKTIF
            // ==========================================
            if (_currentTxData["qr_url"] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: WarnaDesaPay.lightCard,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: WarnaDesaPay.shadow.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 20, color: WarnaDesaPay.textMain),
                        SizedBox(width: 8),
                        Text(
                          "Metode Pembayaran QRIS",
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: WarnaDesaPay.textMain),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Simpan atau screenshot kode QRIS di bawah ini",
                      style: TextStyle(fontSize: 12, color: WarnaDesaPay.textSub, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WarnaDesaPay.lightField, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _currentTxData["qr_url"],
                          height: 240,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return SizedBox(
                              height: 240,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, size: 48, color: WarnaDesaPay.textSub.withOpacity(0.3)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Gagal memuat gambar QRIS.\nPeriksa koneksi internet Anda.", 
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 12)
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 36),

            // ==========================================
            // 3. TOMBOL AKSI UTAMA (CUSTOM BOUNCE)
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
                      color: WarnaDesaPay.primary.withOpacity(0.24),
                      blurRadius: 14,
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
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Pembangun Baris Data Invoice dengan Fitur Selectable Text
  Widget _buildInvoiceRow(String label, String value, {bool isHighlight = false, Color? valueColor, bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 13, fontWeight: FontWeight.w600)
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SelectableText( // Memungkinkan pengguna menyorot & menyalin teks (seperti No. Referensi)
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isHighlight || isStatus ? FontWeight.w900 : FontWeight.w700,
                fontSize: isHighlight ? 16 : 13,
                color: valueColor ?? (isHighlight ? WarnaDesaPay.primary : WarnaDesaPay.textMain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
