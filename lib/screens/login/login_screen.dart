import 'package:flutter/material.dart';

import '../../config/warna.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [

              const SizedBox(height: 40),

              const Icon(
                Icons.account_balance_wallet,
                color: WarnaDesaPay.primary,
                size: 90,
              ),

              const SizedBox(height: 20),

              const Text(
                "DesaPay",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Text(
                "Top Up & Pembayaran",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Nomor HP",
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "PIN",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("MASUK"),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text("DAFTAR AKUN"),
                ),
              ),

              const SizedBox(height: 40),

              const Divider(),

              const SizedBox(height: 10),

              const Text(
                "Pusat Bantuan",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text("WhatsApp"),
              const Text("085642131263"),

              const SizedBox(height: 10),

              const Text("Email"),
              const Text("gacoan449@gmail.com"),

            ],
          ),
        ),
      ),
    );
  }
}
