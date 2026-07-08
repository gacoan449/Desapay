import 'package:flutter/material.dart';

import '../../config/warna.dart';
import '../../services/tripay_service.dart';
import '../../models/payment_channel.dart';

class MetodePembayaranScreen extends StatelessWidget {
  final String nominal;

  const MetodePembayaranScreen({
    super.key,
    required this.nominal,
  });

  @override
  Widget build(BuildContext context) {
    final TripayService tripay = TripayService();

    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: const Text("Metode Pembayaran"),
      ),
      body: FutureBuilder<List<PaymentChannel>>(
        future: tripay.getPaymentChannels(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Gagal memuat metode pembayaran"));
          }

          final channels = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.payment),
                  title: Text(channel.name),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "${channel.name} dipilih untuk top up $nominal",
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
