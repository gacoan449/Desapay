import 'package:flutter/material.dart';
import '../../config/warna.dart';

class InvoiceScreen extends StatelessWidget {
  final Map<String, dynamic> tripayData;

  const InvoiceScreen({super.key, required this.tripayData});

  @override
  Widget build(BuildContext context) {
    final String reference = tripayData['reference'] ?? '-';
    final String paymentName = tripayData['payment_name'] ?? 'Payment Gateway';
    final int amount = tripayData['amount'] ?? 0;
    final String payCode = tripayData['pay_code'] ?? '';
    final String qrUrl = tripayData['qr_url'] ?? '';
    final String status = tripayData['status'] ?? 'UNPAID';
    final List<dynamic> instructions = tripayData['instructions'] ?? [];

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
                          color: status == 'UNPAID' ? WarnaDesaPay.warning.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'UNPAID' ? WarnaDesaPay.warning : Colors.green,
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
                    style: TextStyle(color: WarnaDesaPay.primary, fontSize: 26, fontWeight: FontWeight.w900),
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
                crossAxisAlignment: CrossAxisAlignment.center, // DIKOREKSI: Menggunakan standar bawaan framework
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
                    const SizedBox(height: 8),
                    const Text("Ketuk nomor di atas untuk menyalin", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text("Tata Cara Pembayaran", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: instructions.length,
              itemBuilder: (context, index) {
                final item = instructions[index];
                final String titleStep = item['title'] ?? 'Langkah';
                final List<dynamic> steps = item['steps'] ?? [];

                return ExpansionTile(
                  title: Text(titleStep, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  children: steps.map((step) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${steps.indexOf(step) + 1}. ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(step.toString().replaceAll(RegExp(r'<[^>]*>'), ''), style: const TextStyle(fontSize: 12, height: 1.4))),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
