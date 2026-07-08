import 'package:flutter/material.dart';

class PilihNominalScreen extends StatelessWidget {
  final String nomor;

  const PilihNominalScreen({
    super.key,
    required this.nomor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Nominal"),
      ),
      body: ListView(
        children: [

          ListTile(
            title: const Text("Pulsa 5.000"),
            subtitle: const Text("Rp6.500"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),

          ListTile(
            title: const Text("Pulsa 10.000"),
            subtitle: const Text("Rp11.500"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),

          ListTile(
            title: const Text("Pulsa 20.000"),
            subtitle: const Text("Rp21.500"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),

          ListTile(
            title: const Text("Pulsa 50.000"),
            subtitle: const Text("Rp51.000"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),

          ListTile(
            title: const Text("Pulsa 100.000"),
            subtitle: const Text("Rp100.500"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),

        ],
      ),
    );
  }
}
