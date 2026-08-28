// lib/screens/saldo/invoice_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../config/warna.dart';
import '../../services/tripay_service.dart';

class InvoiceScreen extends StatelessWidget {
  final TriPayInvoiceResult tripayData;

  const InvoiceScreen({
    super.key,
    required this.tripayData,
  });

  String _rupiah(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final reference = tripayData.reference ?? '-';
    final paymentName =
        tripayData.paymentMethod ?? 'Payment Gateway';
    final amount = tripayData.totalAmount ?? 0;
    final payCode = tripayData.paymentCode ?? '';
    final qrUrl = tripayData.qrUrl ?? '';
    final qrString = tripayData.qrString ?? '';

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      appBar: AppBar(
        title: const Text(
          'Detail Pembayaran',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: WarnaDesaPay.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInvoiceCard(
              paymentName: paymentName,
              amount: amount,
              reference: reference,
            ),
            const SizedBox(height: 20),
            _buildPaymentCode(
              context,
              payCode: payCode,
              qrUrl: qrUrl,
              qrString: qrString,
            ),
            const SizedBox(height: 24),
            _buildInstructions(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard({
    required String paymentName,
    required int amount,
    required String reference,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  paymentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: WarnaDesaPay.warning
                      .withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(100),
                ),
                child: const Text(
                  'UNPAID',
                  style: TextStyle(
                    color: WarnaDesaPay.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text(
            'Total Tagihan',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _rupiah(amount),
            style: const TextStyle(
              color: WarnaDesaPay.primary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            'Ref: $reference',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCode(
    BuildContext context, {
    required String payCode,
    required String qrUrl,
    required String qrString,
  }) {
    if (qrUrl.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text(
              'Pindai Kode QRIS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 2,
                ),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Image.network(
                qrUrl,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) => const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (qrString.isNotEmpty)
              SelectableText(
                qrString,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'Kode Bayar / Nomor Virtual Account',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            payCode.isEmpty ? '-' : payCode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.black87,
            ),
          ),
          if (payCode.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    WarnaDesaPay.lightField,
                foregroundColor:
                    WarnaDesaPay.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: payCode),
                );

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Kode berhasil disalin!',
                    ),
                    backgroundColor:
                        WarnaDesaPay.primary,
                    behavior:
                        SnackBarBehavior.floating,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.copy_rounded,
                size: 16,
              ),
              label: const Text(
                'Salin Kode',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    const instructions = [
      'Salin nomor Virtual Account atau kode pembayaran.',
      'Buka aplikasi Mobile Banking atau E-Wallet Anda.',
      'Pilih menu pembayaran atau Virtual Account.',
      'Masukkan nomor/kode pembayaran.',
      'Pastikan nominal pembayaran sesuai tagihan.',
      'Selesaikan pembayaran dan simpan bukti transaksi.',
      'Setelah pembayaran terkonfirmasi, saldo DesaPay akan dikreditkan otomatis.',
    ];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Tata Cara Pembayaran',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: instructions.length,
            itemBuilder: (context, index) {
              return Padding(
                padding:
                    const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin:
                          const EdgeInsets.only(
                        right: 12,
                        top: 2,
                      ),
                      padding:
                          const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: WarnaDesaPay.primary
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w900,
                          color:
                              WarnaDesaPay.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        instructions[index],
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
