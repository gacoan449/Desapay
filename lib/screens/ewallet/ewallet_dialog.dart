import 'package:flutter/material.dart';
import '../../services/digiflazz_service.dart';

// Komponen Dialog Transaksi Terpisah Agar Kode Tidak Terpotong di HP
void prosesKonfirmasiBayar({
  required BuildContext context,
  required dynamic produk,
  required TextEditingController nomorController,
  required DigiflazzService digiflazzService,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text("Konfirmasi Pembelian"),
      content: Text(
          "Apakah Anda yakin ingin mengisi ${produk['product_name']} ke nomor ${nomorController.text} seharga Rp ${produk['price']}?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context); // Tutup dialog konfirmasi

            // Tampilkan Loading Animator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );

            // Eksekusi API Digiflazz
            Map<String, dynamic> hasil = await digiflazzService.kirimTransaksi(
              buyerSkuCode: produk['buyer_sku_code'],
              customerNo: nomorController.text,
            );

            if (context.mounted) Navigator.pop(context); // Tutup loading animator

            String statusTransaksi = hasil['status'] ?? 'Gagal';
            String pesanServer = hasil['sn'] ?? hasil['message'] ?? 'Tidak ada pesan';

            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    statusTransaksi == 'Gagal' ? "❌ Transaksi Gagal" : "⏳ Transaksi Diproses",
                    style: TextStyle(
                      color: statusTransaksi == 'Gagal' ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    "Produk: ${produk['product_name']}\n"
                    "Tujuan: ${nomorController.text}\n"
                    "Status Server: $statusTransaksi\n\n"
                    "Keterangan/SN:\n$pesanServer",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (statusTransaksi != 'Gagal') {
                          nomorController.clear();
                        }
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            }
          },
          child: const Text("Bayar Sekarang"),
        ),
      ],
    ),
  );
}
