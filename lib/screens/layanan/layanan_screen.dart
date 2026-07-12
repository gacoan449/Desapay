import 'package:flutter/material.dart';
import '../../config/warna.dart';

// JALUR IMPORT GLOBAL
import '../paket/paket_screen.dart';
import '../pln/pln_screen.dart';
import '../ewallet/ewallet_screen.dart';
import '../pulsa/pulsa_screen.dart';
import '../pascabayar_screen.dart'; 

// IMPORT FILE PEMBANTU BARU YANG KITA BUAT DI LANGKAH 1
import 'menu_model.dart';

class LayananScreen extends StatelessWidget {
  const LayananScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: const Text(
          "Semua Kategori",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: WarnaDesaPay.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KATEGORI 1: PULSA & DATA OPERATOR
            _buildJudulSubKategori("Pulsa & Paket Data"),
            _buildGridMenu([
              MenuModel(Icons.phone_android_rounded, "Pulsa", Colors.orange, () => _pindahHalaman(context, const PulsaScreen())),
              MenuModel(Icons.swap_horizontal_circle_rounded, "Transfer Pulsa", Colors.deepOrange, () => _pindahHalaman(context, const PulsaScreen())),
              MenuModel(Icons.flash_on_rounded, "Token PLN", Colors.amber, () => _pindahHalaman(context, const PlnScreen())),
              MenuModel(Icons.star_rounded, "Telkomsel Spesial", Colors.red, () => _pindahHalaman(context, const PaketScreen())),
              MenuModel(Icons.bolt_rounded, "Aktivasi Tsel", Colors.redAccent, () => _pindahHalaman(context, const PaketScreen())),
              MenuModel(Icons.phone_in_talk_rounded, "Paket Nelpon", Colors.blue, () => _tampilkanPesan(context, "Paket Nelpon")),
              MenuModel(Icons.signal_cellular_alt_rounded, "Kuota Tri", Colors.purple, () => _pindahHalaman(context, const PaketScreen())),
              MenuModel(Icons.signal_cellular_alt_rounded, "Kuota Indosat", Colors.yellow.shade700, () => _pindahHalaman(context, const PaketScreen())),
              MenuModel(Icons.signal_cellular_alt_rounded, "Kuota Smartfren", Colors.pink, () => _pindahHalaman(context, const PaketScreen())),
              MenuModel(Icons.signal_cellular_alt_rounded, "Kuota by.U", Colors.lightBlue, () => _pindahHalaman(context, const PaketScreen())),
              MenuModel(Icons.signal_cellular_alt_rounded, "Kuota XL", Colors.blue.shade900, () => _pindahHalaman(context, const PaketScreen())),
              MenuModel(Icons.signal_cellular_alt_rounded, "Kuota AXIS", Colors.purpleAccent, () => _pindahHalaman(context, const PaketScreen())),
              MenuModel(Icons.card_membership_rounded, "Voucher Tsel", Colors.red, () => _tampilkanPesan(context, "Voucher Telkomsel")),
              MenuModel(Icons.add_to_home_screen_rounded, "XL AXIS CuanKu", Colors.blueAccent, () => _tampilkanPesan(context, "XL AXIS CuanKu")),
              MenuModel(Icons.verified_rounded, "Aktivasi XL", Colors.blue, () => _tampilkanPesan(context, "Aktivasi XL")),
              MenuModel(Icons.trending_up_rounded, "Tri CuanMAX", Colors.deepPurple, () => _tampilkanPesan(context, "Tri CuanMAX")),
              MenuModel(Icons.check_circle_rounded, "Aktivasi Tri", Colors.purple, () => _tampilkanPesan(context, "Aktivasi Tri")),
              MenuModel(Icons.stars_rounded, "Aktivasi Indosat", Colors.orangeAccent, () => _tampilkanPesan(context, "Aktivasi Indosat")),
              MenuModel(Icons.workspace_premium_rounded, "Indosat Only4u", Colors.redAccent, () => _tampilkanPesan(context, "Indosat Only4u")),
            ]),

            const SizedBox(height: 24),

            // KATEGORI 2: E-WALLET & OJEK ONLINE
            _buildJudulSubKategori("E-Wallet & E-Money"),
            _buildGridMenu([
              MenuModel(Icons.directions_car_filled_rounded, "MAXIM", Colors.yellow.shade800, () => _pindahHalaman(context, const EwalletScreen(jenisEwallet: "MAXIM"))),
              MenuModel(Icons.electric_moped_rounded, "GRAB Driver", Colors.green, () => _pindahHalaman(context, const EwalletScreen(jenisEwallet: "GRAB"))),
              MenuModel(Icons.two_wheeler_rounded, "inDrive", Colors.lightGreen, () => _pindahHalaman(context, const EwalletScreen(jenisEwallet: "INDRIVE"))),
              MenuModel(Icons.motorcycle_rounded, "Gojek Driver", Colors.green.shade700, () => _pindahHalaman(context, const EwalletScreen(jenisEwallet: "Gojek Driver"))),
              MenuModel(Icons.shopping_bag_rounded, "ShopeePay", Colors.deepOrange, () => _pindahHalaman(context, const EwalletScreen(jenisEwallet: "ShopeePay"))),
              MenuModel(Icons.account_balance_wallet_rounded, "DANA", Colors.blue, () => _pindahHalaman(context, const EwalletScreen(jenisEwallet: "DANA"))),
              MenuModel(Icons.payment_rounded, "LinkAja", Colors.red, () => _pindahHalaman(context, const EwalletScreen(jenisEwallet: "LinkAja"))),
              MenuModel(Icons.credit_card_rounded, "OVO", Colors.indigo, () => _pindahHalaman(context, const EwalletScreen(jenisEwallet: "OVO"))),
              MenuModel(Icons.account_box_rounded, "KASPRO", Colors.purple, () => _tampilkanPesan(context, "KASPRO")),
              MenuModel(Icons.wallet_rounded, "GOPAY", Colors.teal, () => _pindahHalaman(context, const EwalletScreen(jenisEwallet: "GoPay"))),
              MenuModel(Icons.store_rounded, "i.saku Indomaret", Colors.orange, () => _tampilkanPesan(context, "i.saku")),
              MenuModel(Icons.subway_rounded, "e-Toll", Colors.cyan, () => _tampilkanPesan(context, "e-Toll")),
            ]),

            const SizedBox(height: 24),

            // KATEGORI 3: TAGIHAN BULANAN / PASCABAYAR
            _buildJudulSubKategori("Tagihan Bulanan & PPOB"),
            _buildGridMenu([
              MenuModel(Icons.receipt_long_rounded, "Pascabayar", Colors.teal, () => _pindahHalaman(context, PascabayarScreen(jenisLayanan: "PASCABAYAR"))),
              MenuModel(Icons.calendar_month_rounded, "Cicilan Bulanan", Colors.orange, () => _tampilkanPesan(context, "Cicilan Bulanan")),
              MenuModel(Icons.router_rounded, "Tagihan Internet", Colors.cyan, () => _tampilkanPesan(context, "Tagihan Internet")),
              MenuModel(Icons.electric_meter_rounded, "Tagihan Listrik", Colors.blueGrey, () => _pindahHalaman(context, PascabayarScreen(jenisLayanan: "LISTRIK"))),
              MenuModel(Icons.gavel_rounded, "Pajak PBB", Colors.green, () => _tampilkanPesan(context, "Pajak PBB")),
              MenuModel(Icons.water_drop_rounded, "Air PDAM", Colors.lightBlue, () => _pindahHalaman(context, PascabayarScreen(jenisLayanan: "PDAM"))),
              MenuModel(Icons.health_and_safety_rounded, "Tagihan BPJS", Colors.teal.shade700, () => _pindahHalaman(context, PascabayarScreen(jenisLayanan: "BPJS"))),
              MenuModel(Icons.tv_rounded, "Paket TV", Colors.redAccent, () => _pindahHalaman(context, PascabayarScreen(jenisLayanan: "TV KABEL"))),
            ]),

            const SizedBox(height: 24),

            // KATEGORI 4: VOUCHER GAME
            _buildJudulSubKategori("Voucher & Mobile Game"),
            _buildGridMenu([
              MenuModel(Icons.sports_esports_rounded, "Game Lainnya", Colors.amber, () => _tampilkanPesan(context, "Game Lainnya")),
              MenuModel(Icons.confirmation_number_rounded, "Voucher Game", Colors.indigo, () => _tampilkanPesan(context, "Voucher Game")),
              MenuModel(Icons.videogame_asset_rounded, "Mobile Legends", Colors.orangeAccent, () => _tampilkanPesan(context, "Mobile Legends")),
              MenuModel(Icons.local_fire_department_rounded, "Free Fire", Colors.red, () => _tampilkanPesan(context, "Free Fire")),
              MenuModel(Icons.shield_rounded, "PUBG Mobile", Colors.green, () => _tampilkanPesan(context, "PUBG Mobile")),
              MenuModel(Icons.colorize_rounded, "Genshin Impact", Colors.deepPurple, () => _tampilkanPesan(context, "Genshin Impact")),
              MenuModel(Icons.print_rounded, "Cetak Voucher", Colors.grey, () => _tampilkanPesan(context, "Cetak Voucher")),
              MenuModel(Icons.layers_rounded, "Cetak Massal", Colors.blueGrey, () => _tampilkanPesan(context, "Cetak Massal")),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildJudulSubKategori(String judul) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        judul,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildGridMenu(List<MenuModel> itemMenus) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: itemMenus.length,
      itemBuilder: (context, index) {
        return MenuLayananUnit(item: itemMenus[index]);
      },
    );
  }

  void _pindahHalaman(BuildContext context, Widget targetHalaman) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => targetHalaman));
  }

  void _tampilkanPesan(BuildContext context, String namaLayanan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Layanan $namaLayanan otomatis tersambung ke Digiflazz"),
        backgroundColor: WarnaDesaPay.primary,
      ),
    );
  }
}
