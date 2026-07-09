import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pulsa/pulsa_screen.dart';
import '../paket/paket_screen.dart';
import '../pln/pln_screen.dart';
import '../ewallet/ewallet_screen.dart';
import '../layanan/layanan_screen.dart';
import '../riwayat/riwayat_screen.dart';
import '../notifikasi/notifikasi_screen.dart';
import 'widgets/kotak_saldo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool saldoTerlihat = true;
  double saldo = 0;
  double cashback = 0;
  int poin = 0;

  final NumberFormat rupiah = NumberFormat.currency(
    locale: "id_ID",
    symbol: "Rp ",
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    saldo = 250000;
    cashback = 18500;
    poin = 1240;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FC),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [

              //=============================
              // HEADER
              //=============================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 55,
                  bottom: 30,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xff1565C0), Color(0xff1E88E5)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.account_circle, size: 38, color: Color(0xff1565C0)),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Selamat Datang", style: TextStyle(color: Colors.white70, fontSize: 14)),
                              SizedBox(height: 4),
                              Text("Pengguna DesaPay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.workspace_premium, color: Colors.amber, size: 18),
                                  SizedBox(width: 5),
                                  Text("Member Gold", style: TextStyle(color: Colors.amber, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifikasiScreen()));
                          },
                          icon: const Icon(Icons.notifications_none, color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const KotakSaldo(),

              const SizedBox(height: 24),

              // AKSES CEPAT
              const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Akses Cepat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(child: _quickButton(icon: Icons.send_rounded, title: "Transfer", color: const Color(0xff1976D2), onTap: () {})),
                  const SizedBox(width: 10),
                  Expanded(child: _quickButton(icon: Icons.qr_code_scanner, title: "Scan", color: const Color(0xff00897B), onTap: () {})),
                  const SizedBox(width: 10),
                  Expanded(child: _quickButton(icon: Icons.account_balance_wallet, title: "Top Up", color: const Color(0xffEF6C00), onTap: () {})),
                  const SizedBox(width: 10),
                  Expanded(child: _quickButton(icon: Icons.qr_code_2, title: "QRIS", color: const Color(0xff7B1FA2), onTap: () {})),
                ]),
              ),

              const SizedBox(height: 30),

              const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Layanan DesaPay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                  childAspectRatio: .82,
                  children: [
                    menuHome(Icons.phone_android, "Pulsa"),
                    menuHome(Icons.wifi, "Data"),
                    menuHome(Icons.flash_on, "PLN"),
                    menuHome(Icons.receipt_long, "Tagihan"),
                    menuHome(Icons.account_balance_wallet, "Top Up"),
                    menuHome(Icons.send, "Transfer"),
                    menuHome(Icons.qr_code_scanner, "Scan"),
                    menuHome(Icons.qr_code_2, "QRIS"),
                    menuHome(Icons.account_balance, "Bank"),
                    menuHome(Icons.savings, "Tabungan"),
                    menuHome(Icons.shopping_cart, "Belanja"),
                    menuHome(Icons.grid_view_rounded, "Semua"),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Info DesaPay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 15),
              SizedBox(
                height: 170,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _artikelCard(gambar: Icons.newspaper, warna: Colors.blue, judul: "DesaPay Resmi Diluncurkan", isi: "Nikmati pembayaran digital yang aman, cepat dan mudah untuk seluruh Indonesia."),
                    _artikelCard(gambar: Icons.security, warna: Colors.green, judul: "Tips Keamanan", isi: "Jangan pernah memberikan PIN maupun OTP kepada siapapun."),
                    _artikelCard(gambar: Icons.local_offer, warna: Colors.orange, judul: "Promo Cashback", isi: "Bayar Pulsa, PLN dan E-Wallet dapat cashback setiap hari."),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () async {
                    final urlWa = Uri.parse("https://wa.me/6285642131263");
                    if (await canLaunchUrl(urlWa)) {
                      await launchUrl(urlWa, mode: LaunchMode.externalApplication);
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aplikasi WhatsApp tidak ditemukan")));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.06), blurRadius: 5)]),
                    child: const Row(children: [
                      CircleAvatar(radius: 26, backgroundColor: Color(0xFF00897B), child: Icon(Icons.support_agent, color: Colors.white, size: 28)),
                      SizedBox(width: 15),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("Pusat Bantuan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF00796B))),
                        SizedBox(height: 6),
                        Text("Hubungi via WhatsApp\n085642131263", style: TextStyle(color: Color(0xFF00796B), height: 1.5)),
                      ])),
                    ]),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                  child: Row(children: [
                    const CircleAvatar(backgroundColor: Color(0xff1976D2), child: Icon(Icons.system_update, color: Colors.white)),
                    const SizedBox(width: 15),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Versi Aplikasi", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("DesaPay v1.0.0", style: TextStyle(color: Colors.grey)),
                    ])),
                    ElevatedButton(onPressed: () {}, child: const Text("Cek")),
                  ]),
                ),
              ),

              const SizedBox(height: 25),

              Center(child: Column(children: [
                const Icon(Icons.account_balance_wallet, color: Color(0xff1976D2), size: 55),
                const SizedBox(height: 10),
                const Text("DesaPay", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text("Dompet Digital Indonesia", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 15),
                Text("© 2026 DesaPay Indonesia", style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 30),
              ])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickButton({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget menuHome(IconData icon, String title) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        switch(title) {
          case "Pulsa": Navigator.push(context, MaterialPageRoute(builder: (_) => const PulsaScreen())); break;
          case "Data": Navigator.push(context, MaterialPageRoute(builder: (_) => const PaketScreen())); break;
          case "PLN": Navigator.push(context, MaterialPageRoute(builder: (_) => const PlnScreen())); break;
          case "Top Up": Navigator.push(context, MaterialPageRoute(builder: (_) => const EwalletScreen())); break;
        }
      },
      child: Column(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [Color(0xff2196F3), Color(0xff1565C0)]),
            boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(.25), blurRadius: 10, offset: const Offset(0,5))],
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }

  Widget _artikelCard({required IconData gambar, required Color warna, required String judul, required String isi}) {
    return Container(
      width: 240, margin: const EdgeInsets.only(right: 15), padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: warna.withOpacity(.15), child: Icon(gambar, color: warna)),
        const SizedBox(height: 14),
        Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(isi, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
      ]),
    );
  }
}
