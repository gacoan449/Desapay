import 'package:flutter/material.dart';
class BelanjakuAvailabilityBadge extends StatelessWidget {
  const BelanjakuAvailabilityBadge({super.key, required this.status});
  final String status;
  @override Widget build(BuildContext context) {
    final available = status == 'available'; final coming = status == 'coming_soon';
    final color = available ? const Color(0xFF16A765) : coming ? const Color(0xFFF59E0B) : const Color(0xFF64748B);
    final label = available ? 'Stok tersedia' : coming ? 'Segera hadir' : 'Stok habis';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)));
  }
}
