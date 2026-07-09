import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/warna.dart';
import '../../widgets/kotak_saldo.dart';

import '../layanan/layanan_screen.dart';
import '../pulsa/pulsa_screen.dart';
import '../paket/paket_screen.dart';
import '../pln/pln_screen.dart';
import '../ewallet/ewallet_screen.dart';
import '../pascabayar_screen.dart';
import '../saldo/topup_saldo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Future<void> _bukaWhatsApp() async {

    const nomor = "6285642131263";

    final Uri url = Uri.parse(
      "https://wa.me/$nomor?text=${Uri.encodeComponent("Halo CS DesaPay, saya mengalami kendala transaksi.")}",
    );

    if (await canLaunchUrl(url)) {

      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

    } else {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("WhatsApp tidak tersedia"),
        ),
      );

    }
  }

  void _qrisBelumAktif() {

    showDialog(
      context: context,
      builder: (_) {

        return AlertDialog(

          title: const Text("QRIS DesaPay"),

          content: const Text(
            "Fitur QRIS akan aktif setelah akun merchant selesai diverifikasi.",
          ),

          actions: [

            TextButton(

              onPressed: (){
                Navigator.pop(context);
              },

              child: const Text("Tutup"),

            )

          ],

        );

      },
    );

  }

  void _notifikasi() {

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(
          "Belum ada notifikasi.",
        ),

      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xffF5F9FC),

      appBar: AppBar(

        elevation: 0,

        backgroundColor: WarnaDesaPay.primary,

        title: Row(

          children: [

            Image.asset(
              "assets/logo.png",
              height: 34,
              errorBuilder: (_,__,___){

                return const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                );

              },
            ),

            const SizedBox(width:8),

            const Text(

              "DesaPay",

              style: TextStyle(

                color: Colors.white,

                fontWeight: FontWeight.bold,

                fontSize:22,

              ),

            )

          ],

        ),

        actions: [

          IconButton(

            onPressed: _qrisBelumAktif,

            icon: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
            ),

          ),

          IconButton(

            onPressed: _notifikasi,

            icon: const Icon(
              Icons.notifications_none,
              color: Colors.white,
            ),

          ),

        ],

      ),

      body: SingleChildScrollView(

        physics: const BouncingScrollPhysics(),

        child: Column(

          children: [

            Stack(

              children: [

                Container(

                  height: 60,

                  decoration: BoxDecoration(

                    color: WarnaDesaPay.primary,

                    borderRadius: const BorderRadius.only(

                      bottomLeft: Radius.circular(22),

                      bottomRight: Radius.circular(22),

                    ),

                  ),

                ),

                Padding(

                  padding: const EdgeInsets.symmetric(
                    horizontal:16,
                  ),

                  child: Column(

                    children: [

                      const KotakSaldo(),

                      const SizedBox(height:12),

                      SizedBox(

                        width: double.infinity,

                        height: 52,

                        child: ElevatedButton.icon(

                          style: ElevatedButton.styleFrom(

                            backgroundColor: Colors.orange,

                            foregroundColor: Colors.white,

                            elevation: 0,

                            shape: RoundedRectangleBorder(

                              borderRadius:
                                  BorderRadius.circular(14),

                            ),

                          ),

                          icon: const Icon(
                            Icons.account_balance_wallet,
                          ),

                          label: const Text(

                            "ISI SALDO / TOP UP",

                            style: TextStyle(

                              fontWeight: FontWeight.bold,

                              fontSize:16,

                            ),

                          ),

                          onPressed: (){

                            Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder: (_)=>const TopupSaldoScreen(),

                              ),

                            );

                          },

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),

            const SizedBox(height:22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 22,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.86,
                  children: [

                    _menuItem(
                      Icons.phone_android_rounded,
                      "Pulsa",
                      Colors.orange,
                      const PulsaScreen(),
                    ),

                    _menuItem(
                      Icons.wifi_rounded,
                      "Data",
                      Colors.blue,
                      const PaketScreen(),
                    ),

                    _menuItem(
                      Icons.flash_on_rounded,
                      "Listrik",
                      Colors.amber.shade700,
                      const PlnScreen(),
                    ),

                    _menuItem(
                      Icons.account_balance_wallet_rounded,
                      "E-Wallet",
                      Colors.purple,
                      const EwalletScreen(),
                    ),

                    _menuItem(
                      Icons.health_and_safety_rounded,
                      "BPJS",
                      Colors.teal,
                      const PascabayarScreen(
                        jenisLayanan: "BPJS",
                      ),
                    ),

                    _menuItem(
                      Icons.water_drop_rounded,
                      "PDAM",
                      Colors.lightBlue,
                      const PascabayarScreen(
                        jenisLayanan: "PDAM",
                      ),
                    ),

                    _menuItem(
                      Icons.tv_rounded,
                      "TV Kabel",
                      Colors.redAccent,
                      const PascabayarScreen(
                        jenisLayanan: "TV KABEL",
                      ),
                    ),

                    _menuItem(
                      Icons.grid_view_rounded,
                      "Lainnya",
                      Colors.grey,
                      const LayananScreen(),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade700,
                      Colors.lightBlue.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [

                    Icon(
                      Icons.local_offer,
                      color: Colors.white,
                      size: 30,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        "Promo Pulsa • Paket Data • Token PLN • QRIS segera hadir",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: _bukaWhatsApp,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade600,
                        Colors.green.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.20),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [

                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white24,
                        child: const Icon(
                          Icons.support_agent,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 15),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text(
                              "Pusat Bantuan DesaPay",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              "Hubungi Customer Service WhatsApp 24 jam apabila mengalami kendala transaksi.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),

                          ],
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),

                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
            Column(
              children: [

                Icon(
                  Icons.widgets_outlined,
                  size: 38,
                  color: WarnaDesaPay.primary.withOpacity(0.30),
                ),

                const SizedBox(height: 8),

                Text(
                  "Aplikasi PPOB Modern Indonesia",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "© 2026 DesaPay Indonesia",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 30),

              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    Color warna,
    Widget tujuan,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),

      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => tujuan,
          ),
        );

      },

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),

            padding: const EdgeInsets.all(13),

            decoration: BoxDecoration(
              color: warna.withOpacity(0.10),
              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: warna,
              size: 28,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

        ],
      ),
    );
  }
}
