import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/warna.dart';
import '../../services/tripay_service.dart';

class InvoiceScreen extends StatelessWidget {
  final TriPayInvoiceResult tripayData;

  const InvoiceScreen({super.key, required this.tripayData});

  @override
  Widget build(BuildContext context) {
    // Memetakan data dari objek tipe-aman (Type-Safe Object)
    final String reference = tripayData.reference ?? '-';
    final String paymentName = tripayData.paymentMethod ?? 'Payment Gateway';
    final int amount = tripayData.totalAmount ?? 0;
    final String payCode = tripayData.paymentCode ?? '';
    final String qrUrl = tripayData.qrUrl ?? '';
    final String status = 'UNPAID'; // Secara default invoice baru pasti belum terbayar
    
    // Instruksi universal sebagai pengganti payload dinamis yang tidak di-mapping di service
    final List<String> defaultInstructions = [
      "Salin Nomor Virtual Account/Kode Bayar atau unduh kode QRIS di atas.",
      "Buka aplikasi Mobile Banking atau E-Wallet pilihan Anda.",
      "Pilih menu Transfer ke Virtual Account atau Pindai QR.",
      "Tempel nomor yang disalin atau arahkan kamera ke kode QR.",
      "Pastikan nominal tagihan sesuai, lalu masukkan PIN untuk konfirmasi.",
      "Simpan bukti pembayaran. Saldo DesaPay akan otomatis masuk dalam hitungan detik."
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      appBar: AppBar(
        title: const Text("Detail Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: WarnaDesaPay.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // CARD STATUS & TOTAL TAGIHAN
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(paymentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: WarnaDesaPay.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: WarnaDesaPay.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text("Total Tagihan", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                    style: const TextStyle(color: WarnaDesaPay.primary, fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text("Ref: $reference", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // CONTAINER KHUSUS RENDERING METODE BAYAR
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (qrUrl.isNotEmpty) ...[
                    const Text("Pindai Kode QRIS Di Bawah Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.network(qrUrl, width: 200, height: 200),
                    ),
                    const SizedBox(height: 12),
                    const Text("Mendukung: DANA, OVO, GoPay, LinkAja, & Mobile Banking", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ] else ...[
                    const Text("Kode Bayar / Nomor Virtual Account", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 6),
                    SelectableText(
                      payCode,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WarnaDesaPay.lightField,
                        foregroundColor: WarnaDesaPay.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: payCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Kode berhasil disalin!"),
                            backgroundColor: WarnaDesaPay.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text("Salin Kode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text("Tata Cara Pembayaran", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Merender instruksi pembayaran statis universal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: defaultInstructions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12, top: 2),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: WarnaDesaPay.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: WarnaDesaPay.primary),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            defaultInstructions[index], 
                            style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
