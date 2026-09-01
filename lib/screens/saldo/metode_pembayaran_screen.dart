import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import Konfigurasi & Widget Modular Utama (CTO Standard)
import '../../config/warna.dart';
import '../../services/tripay_service.dart';
import '../../models/payment_channel.dart';
import '../../widgets/menu_item.dart'; // Mengambil CustomBounce terpusat

/// Layar Pemilihan Metode Pembayaran Dinamis (Terhubung API TriPay)
class MetodePembayaranScreen extends StatelessWidget {
  final String nominal;

  const MetodePembayaranScreen({
    super.key,
    required this.nominal,
  });

  /// Standardisasi Format Mata Uang Menggunakan `intl`
  String _formatRupiah(String value) {
    // Membersihkan karakter non-angka sebelum diparsing
    final int parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(parsed);
  }

  /// Pemetaan Warna Spesifik Berdasarkan Identitas Brand (Bank/Retail)
  Color _getChannelColor(String code) {
    final c = code.toUpperCase();
    if (c.contains("BCA")) return const Color(0xFF0054A6); // Biru BCA
    if (c.contains("BRI")) return const Color(0xFF0073C6); // Biru BRI
    if (c.contains("BNI")) return const Color(0xFFFF6600); // Oranye BNI
    if (c.contains("MANDIRI")) return const Color(0xFFFFB300); // Emas Mandiri
    if (c.contains("ALFAMART")) return const Color(0xFFE52229); // Merah Alfamart
    if (c.contains("INDOMARET")) return const Color(0xFF0086FF); // Biru Indomaret
    if (c.contains("QRIS")) return const Color(0xFF9B5DE5); // Ungu QRIS
    return WarnaDesaPay.primary; // Warna Default DesaPay
  }

  @override
  Widget build(BuildContext context) {
    final TripayService tripay = TripayService();

    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Metode Pembayaran",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: WarnaDesaPay.shadow.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Pembayaran",
                  style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  "Rp ${_formatRupiah(nominal)}",
                  style: const TextStyle(color: WarnaDesaPay.primary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Pilih Channel Pembayaran",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: WarnaDesaPay.textMain),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<PaymentChannel>>(
              future: tripay.getPaymentChannels(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: WarnaDesaPay.primary),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_tethering_error_rounded, size: 54, color: WarnaDesaPay.danger.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          "Gagal memuat saluran pembayaran.\nPeriksa koneksi atau kredensial API TriPay.",
                          style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 13, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final channels = snapshot.data ?? [];

                if (channels.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment_rounded, size: 54, color: WarnaDesaPay.textSub.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          "Belum ada metode pembayaran yang aktif.",
                          style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    final Color channelColor = _getChannelColor(channel.code);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: WarnaDesaPay.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: WarnaDesaPay.lightField),
                        boxShadow: [
                          BoxShadow(
                            color: WarnaDesaPay.shadow.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: CustomBounce(
                        onTap: () {
                          Navigator.pop(context, channel.code);
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: channelColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              channel.code.length >= 3
                                  ? channel.code.substring(0, 3).toUpperCase()
                                  : channel.code.toUpperCase(),
                              style: TextStyle(color: channelColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                            ),
                          ),
                          title: Text(
                            channel.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: WarnaDesaPay.textMain),
                          ),
                          subtitle: const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              "Verifikasi otomatis instan",
                              style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: WarnaDesaPay.textSub),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
