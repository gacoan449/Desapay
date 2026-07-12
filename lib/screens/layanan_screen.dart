import 'package:flutter/material.dart';
import '../../config/warna.dart';

// JALUR IMPORT GLOBAL KE SCREENS LAIN
import '../paket/paket_screen.dart';
import '../pln/pln_screen.dart';
import '../ewallet/ewallet_screen.dart';
import '../pulsa/pulsa_screen.dart';
import '../pascabayar_screen.dart'; 

class LayananScreen extends StatelessWidget {
  const LayananScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: const Text("Semua Kategori", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: WarnaDesaPay.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJudul("Pulsa & Paket Data"),
            _buildGrid(context, [
              _item(Icons.phone_android_rounded, "Pulsa", Colors.orange, const PulsaScreen()),
              _item(Icons.swap_horizontal_circle_rounded, "Transfer Pulsa", Colors.deepOrange, const PulsaScreen()),
              _item(Icons.flash_on_rounded, "Token PLN", Colors.amber, const PlnScreen()),
              _item(Icons.star_rounded, "Telkomsel Spesial", Colors.red, const PaketScreen()),
              _item(Icons.bolt_rounded, "Aktivasi Tsel", Colors.redAccent, const PaketScreen()),
              _item(Icons.phone_in_talk_rounded, "Paket Nelpon", Colors.blue, null, pesan: "Paket Nelpon"),
              _item(Icons.signal_cellular_alt_rounded, "Kuota Tri", Colors.purple, const PaketScreen()),
              _item(Icons.signal_cellular_alt_rounded, "Kuota Indosat", Colors.yellow.shade700, const PaketScreen()),
              _item(Icons.signal_cellular_alt_rounded, "Kuota Smartfren", Colors.pink, const PaketScreen()),
              _item(Icons.signal_cellular_alt_rounded, "Kuota by.U", Colors.lightBlue, const PaketScreen()),
              _item(Icons.signal_cellular_alt_rounded, "Kuota XL", Colors.blue.shade900, const PaketScreen()),
              _item(Icons.signal_cellular_alt_rounded, "Kuota AXIS", Colors.purpleAccent, const PaketScreen()),
            ]),
            const SizedBox(height: 24),
            _buildJudul("E-Wallet & E-Money"),
            _buildGrid(context, [
              _item(Icons.directions_car_filled_rounded, "MAXIM", Colors.yellow.shade800, const EwalletScreen(jenisEwallet: "MAXIM")),
              _item(Icons.electric_moped_rounded, "GRAB Driver", Colors.green, const EwalletScreen(jenisEwallet: "GRAB")),
              _item(Icons.two_wheeler_rounded, "inDrive", Colors.lightGreen, const EwalletScreen(jenisEwallet: "INDRIVE")),
              _item(Icons.motorcycle_rounded, "Gojek Driver", Colors.green.shade700, const EwalletScreen(jenisEwallet: "Gojek Driver")),
              _item(Icons.shopping_bag_rounded, "ShopeePay", Colors.deepOrange, const EwalletScreen(jenisEwallet: "ShopeePay")),
              _item(Icons.account_balance_wallet_rounded, "DANA", Colors.blue, const EwalletScreen(jenisEwallet: "DANA")),
              _item(Icons.payment_rounded, "LinkAja", Colors.red, const EwalletScreen(jenisEwallet: "LinkAja")),
              _item(Icons.credit_card_rounded, "OVO", Colors.indigo, const EwalletScreen(jenisEwallet: "OVO")),
              _item(Icons.wallet_rounded, "GOPAY", Colors.teal, const EwalletScreen(jenisEwallet: "GoPay")),
            ]),
            const SizedBox(height: 24),
            _buildJudul("Tagihan Bulanan & PPOB"),
            _buildGrid(context, [
              _item(Icons.receipt_long_rounded, "Pascabayar", Colors.teal, PascabayarScreen(jenisLayanan: "PASCABAYAR")),
              _item(Icons.electric_meter_rounded, "Tagihan Listrik", Colors.blueGrey, PascabayarScreen(jenisLayanan: "LISTRIK")),
              _item(Icons.water_drop_rounded, "Air PDAM", Colors.lightBlue, PascabayarScreen(jenisLayanan: "PDAM")),
              _item(Icons.health_and_safety_rounded, "Tagihan BPJS", Colors.teal.shade700, PascabayarScreen(jenisLayanan: "BPJS")),
              _item(Icons.tv_rounded, "Paket TV", Colors.redAccent, PascabayarScreen(jenisLayanan: "TV KABEL")),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildJudul(String judul) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(judul, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildGrid(BuildContext context, List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final data = items[index];
        return InkWell(
          onTap: () {
            if (data['target'] != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => data['target']));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Layanan ${data['pesan']} otomatis tersambung ke Digiflazz"),
                backgroundColor: WarnaDesaPay.primary,
              ));
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: (data['color'] as Color).withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(data['icon'] as IconData, size: 24, color: data['color'] as Color),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  data['title'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _item(IconData icon, String title, Color color, Widget? target, {String? pesan}) {
    return {'icon': icon, 'title': title, 'color': color, 'target': target, 'pesan': pesan};
  }
}
