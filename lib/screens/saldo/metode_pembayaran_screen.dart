import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/tripay_service.dart';
import '../../models/payment_channel.dart';

// Pembungkus Animasi Memantul (Micro-interaction) Premium saat Channel Dipilih
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
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
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

class MetodePembayaranScreen extends StatelessWidget {
  final String nominal;

  const MetodePembayaranScreen({
    super.key,
    required this.nominal,
  });

  String _formatCurrency(String value) {
    int parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return parsed.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Color _getChannelColor(String code) {
    final c = code.toUpperCase();
    if (c.contains("BCA")) return const Color(0xFF0054A6);
    if (c.contains("BRI")) return const Color(0xFF0073C6);
    if (c.contains("BNI")) return const Color(0xFFFF6600);
    if (c.contains("MANDIRI")) return const Color(0xFFFFB300);
    if (c.contains("ALFAMART")) return const Color(0xFFE52229);
    if (c.contains("INDOMARET")) return const Color(0xFF0086FF);
    if (c.contains("QRIS")) return const Color(0xFF9B5DE5);
    return WarnaDesaPay.primary;
  }

  @override
  Widget build(BuildContext context) {
    final TripayService tripay = TripayService();

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        title: const Text(
          "Pilih Metode Pembayaran",
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
          // RINGKASAN NOMINAL TOP UP PREMIUM
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Nominal Top Up",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  "Rp ${_formatCurrency(nominal)}",
                  style: TextStyle(color: WarnaDesaPay.primary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text(
              "Metode Pembayaran Tripay Tersedia",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800),
            ),
          ),
          // DAFTAR PAYMENT CHANNEL LOADER REAL-TIME
          Expanded(
            child: FutureBuilder<List<PaymentChannel>>(
              future: tripay.getPaymentChannels(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gpp_bad_rounded, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          "Gagal memuat sistem pembayaran.\nPastikan signature API Tripay terkonfigurasi.",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
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
                        Icon(Icons.payment_off_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text("Tidak ada metode pembayaran aktif saat ini.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    final Color channelColor = _getChannelColor(channel.code);

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
                      child: CustomBounce(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Metode ${channel.name} berhasil dipilih. Memproses invoice..."),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: WarnaDesaPay.primary,
                            ),
                          );
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          // ICON AVATAR BRAND DENGAN WARNA REPRESENTATIF DYNAMIC
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: channelColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              channel.code.substring(0, index + 3 <= channel.code.length ? 3 : channel.code.length).toUpperCase(),
                              style: TextStyle(color: channelColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                            ),
                          ),
                          title: Text(
                            channel.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                          ),
                          subtitle: const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              "Proses verifikasi otomatis 24 Jam",
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
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
