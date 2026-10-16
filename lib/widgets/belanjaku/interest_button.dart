import 'package:flutter/material.dart';

class BelanjakuInterestButton extends StatelessWidget {
  const BelanjakuInterestButton({super.key, required this.onPressed, this.busy = false});
  final VoidCallback? onPressed;
  final bool busy;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.notifications_active_outlined),
      label: Text(busy ? 'Menyimpan minat...' : 'Saya Berminat — Beri Tahu Saat Tersedia'),
      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0866D9), side: const BorderSide(color: Color(0xFF0866D9)), padding: const EdgeInsets.symmetric(vertical: 14)),
    ),
  );
}
