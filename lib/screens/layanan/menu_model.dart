import 'package:flutter/material.dart';

// Model Penampung Data Menu
class MenuModel {
  final IconData icon;
  final String title;
  final Color themeColor;
  final VoidCallback onTap;

  MenuModel(this.icon, this.title, this.themeColor, this.onTap);
}

// Komponen Desain Bunderan Soft Premium
class MenuLayananUnit extends StatelessWidget {
  final MenuModel item;

  const MenuLayananUnit({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.themeColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 24,
              color: item.themeColor,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
