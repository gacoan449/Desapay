import 'package:flutter/material.dart';

import '../../config/warna.dart';

class PaymentScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const PaymentScreen({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final trx = data["data"];

    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      appBar: AppBar(
        title: const Text("Pembayaran"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [

                  const Icon(
                    Icons.account_balance_wallet,
                    size: 70,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 15),

                  Text(
                    trx["payment_name"] ?? "",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _item(
                    "Nominal",
                    "Rp ${trx["amount"]}",
                  ),

                  _item(
                    "Reference",
                    trx["reference"] ?? "-",
                  ),

                  _item(
                    "Status",
                    trx["status"] ?? "UNPAID",
                  ),

                  if (trx["pay_code"] != null)

                    _item(
                      "Kode Bayar",
                      trx["pay_code"],
                    ),

                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (trx["qr_url"] != null)

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  children: [

                    const Text(
                      "Scan QRIS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Image.network(
                      trx["qr_url"],
                      height: 250,
                    ),

                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("CEK STATUS"),

              onPressed: () {

              },
            ),
          ),

        ],
      ),
    );
  }

  Widget _item(
    String title,
    String value,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: SelectableText(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
