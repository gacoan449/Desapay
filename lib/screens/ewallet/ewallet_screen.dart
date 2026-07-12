import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/digiflazz_service.dart'; 

class EwalletScreen extends StatefulWidget {
  final String? jenisEwallet;
  const EwalletScreen({this.jenisEwallet, super.key});

  @override
  State<EwalletScreen> createState() => _EwalletScreenState();
}

class _EwalletScreenState extends State<EwalletScreen> {
  bool _isMenuDetailAktif = false;
  String _ewalletTerpilih = "";
  final TextEditingController _nomorController = TextEditingController();
  final DigiflazzService _digiflazzService = DigiflazzService();
  List<dynamic> _daftarProdukEwallet = [];
  bool _sedangMemuat = false;

  @override
  void initState() {
    super.initState();
    if (widget.jenisEwallet != null) {
      _ewalletTerpilih = widget.jenisEwallet!;
      _isMenuDetailAktif = true;
      _panggilProdukEwallet(widget.jenisEwallet!);
    }
  }

  Future<void> _panggilProdukEwallet(String brand) async {
    setState(() => _sedangMemuat = true);
    List<dynamic> semuaProduk = await _digiflazzService.ambilSemuaProduk();
    String kataKunciBrand = brand.toUpperCase();
    
    if (kataKunciBrand.contains("GOJEK") || kataKunciBrand.contains("GOPAY")) {
      kataKunciBrand = "GO-PAY"; 
    } else if (kataKunciBrand.contains("GRAB")) {
      kataKunciBrand = "GRAB";
    } else if (kataKunciBrand.contains("MAXIM")) {
      kataKunciBrand = "MAXIM";
    } else if (kataKunciBrand.contains("INDRIVE")) {
      kataKunciBrand = "INDRIVE";
    }

    List<dynamic> produkDisaring = semuaProduk.where((produk) {
      String kategori = (produk['category'] ?? '').toString().toUpperCase();
      String namaBrand = (produk['brand'] ?? '').toString().toUpperCase();
      return (kategori.contains('E-MONEY') || kategori.contains('VOUCHER') || kategori.contains('GAME')) && 
             (namaBrand.contains(kataKunciBrand) || kataKunciBrand.contains(namaBrand));
    }).toList();

    produkDisaring.sort((a, b) => (int.tryParse(a['price'].toString()) ?? 0).compareTo(int.tryParse(b['price'].toString()) ?? 0));
    setState(() {
      _daftarProdukEwallet = produkDisaring;
      _sedangMemuat = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,
      appBar: AppBar(
        title: Text(_isMenuDetailAktif ? "Top Up $_ewalletTerpilih" : "Top Up E-Wallet"),
        leading: _isMenuDetailAktif ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => widget.jenisEwallet != null ? Navigator.pop(context) : setState(() { _isMenuDetailAktif = false; _nomorController.clear(); })) : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isMenuDetailAktif ? _tampilanFormEwallet() : _tampilanMenuUtama(),
      ),
    );
  }

  Widget _tampilanMenuUtama() {
    return ListView(
      children: [
        _menu(Icons.account_balance_wallet, "DANA", "Top Up Saldo DANA"),
        _menu(Icons.account_balance_wallet, "OVO", "Top Up Saldo OVO"),
        _menu(Icons.account_balance_wallet, "GoPay", "Top Up Saldo GoPay"),
        _menu(Icons.account_balance_wallet, "ShopeePay", "Top Up Saldo ShopeePay"),
        _menu(Icons.account_balance_wallet, "LinkAja", "Top Up Saldo LinkAja"),
        _menu(Icons.local_taxi, "MAXIM", "Top Up Saldo Driver/Customer Maxim"),
        _menu(Icons.directions_car, "GRAB", "Top Up Saldo Driver/Customer Grab"),
      ],
    );
  }

  Widget _menu(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: WarnaDesaPay.primary.withOpacity(0.1), child: Icon(icon, color: WarnaDesaPay.primary)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () { setState(() { _ewalletTerpilih = title; _isMenuDetailAktif = true; }); _panggilProdukEwallet(title); },
      ),
    );
  }

  Widget _tampilanFormEwallet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Nomor Handphone / ID Akun", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _nomorController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(border: const OutlineInputBorder(), hintText: "Contoh: 081234567890", prefixIcon: const Icon(Icons.phone_android), labelText: "Nomor $_ewalletTerpilih"),
        ),
        const SizedBox(height: 20),
        Text("Pilih Nominal Saldo $_ewalletTerpilih", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Expanded(
          child: _sedangMemuat
              ? const Center(child: CircularProgressIndicator())
              : _daftarProdukEwallet.isEmpty
                  ? const Center(child: Text("Produk tidak ditemukan.\nPastikan IP didaftarkan & saldo terisi.", textAlign: TextAlign.center))
                  : ListView.builder(
                      itemCount: _daftarProdukEwallet.length,
                      itemBuilder: (context, index) {
                        final produk = _daftarProdukEwallet[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(produk['product_name'] ?? '-'),
                            subtitle: Text("Kode: ${produk['buyer_sku_code']}"),
                            trailing: Text("Rp ${produk['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                            onTap: () {
                              if (_nomorController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Isi nomor HP $_ewalletTerpilih terlebih dahulu!")));
                                return;
                              }
                              _eksekusiBayar(produk);
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _eksekusiBayar(dynamic produk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: Text("Beli ${produk['product_name']} ke ${_nomorController.text}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
              Map<String, dynamic> hasil = await _digiflazzService.kirimTransaksi(buyerSkuCode: produk['buyer_sku_code'], customerNo: _nomorController.text);
              if (mounted) Navigator.pop(context);
              
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(hasil['status'] == 'Gagal' ? "❌ Gagal" : "⏳ Diproses"),
                    content: Text("Status: ${hasil['status'] ?? 'Gagal'}\nSN: ${hasil['sn'] ?? hasil['message'] ?? '-'}"),
                    actions: [TextButton(onPressed: () { Navigator.pop(context); if(hasil['status'] != 'Gagal') _nomorController.clear(); }, child: const Text("OK"))],
                  ),
                );
              }
            },
            child: const Text("Bayar"),
          ),
        ],
      ),
    );
  }
}
