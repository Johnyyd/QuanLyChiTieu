import 'package:flutter/material.dart';

class CategoryConstants {
  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Ăn uống', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Di chuyển', 'icon': Icons.directions_car, 'color': Colors.blue},
    {'name': 'Mua sắm', 'icon': Icons.shopping_cart, 'color': Colors.purple},
    {'name': 'Giải trí', 'icon': Icons.movie, 'color': Colors.redAccent},
    {'name': 'Hóa đơn', 'icon': Icons.receipt, 'color': Colors.teal},
    {'name': 'Sức khỏe', 'icon': Icons.favorite, 'color': Colors.pink},
    {'name': 'Du lịch', 'icon': Icons.flight, 'color': Colors.indigo},
    {'name': 'Khác', 'icon': Icons.category, 'color': Colors.grey},
  ];

  static const List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Tiền lương', 'icon': Icons.work, 'color': Colors.green},
    {'name': 'Thưởng', 'icon': Icons.card_giftcard, 'color': Colors.greenAccent},
    {'name': 'Đầu tư', 'icon': Icons.trending_up, 'color': Colors.lightGreen},
    {'name': 'Khác', 'icon': Icons.add_circle, 'color': Colors.grey},
  ];

  static List<Map<String, dynamic>> get categories => [...expenseCategories, ...incomeCategories];

  static IconData getIcon(String categoryName) {
    final category = categories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => categories.last,
    );
    return category['icon'] as IconData;
  }

  static Color getColor(String categoryName) {
    final category = categories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => categories.last,
    );
    return category['color'] as Color;
  }
}
