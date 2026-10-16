import 'package:flutter/material.dart';
class BelanjakuCategoryTile extends StatelessWidget {
  const BelanjakuCategoryTile({super.key, required this.label, required this.icon, required this.onTap});
  final String label; final IconData icon; final VoidCallback onTap;
  @override Widget build(BuildContext context) => InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: SizedBox(width: 78, child: Column(children: [Container(width: 54, height: 54, decoration: BoxDecoration(color: const Color(0xFFEAF3FF), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: const Color(0xFF0866D9), size: 27)), const SizedBox(height: 7), Text(label, maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))])));
}
