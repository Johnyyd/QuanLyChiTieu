import 'package:flutter/material.dart';
import '../../../core/constants/category_constants.dart';
import '../../../core/theme/app_theme.dart';

class CategorySelectionScreen extends StatelessWidget {
  final String initialType; // 'expense' or 'income'

  const CategorySelectionScreen({super.key, this.initialType = 'expense'});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: initialType == 'income' ? 1 : 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chọn nhóm'),
          backgroundColor: AppTheme.surfaceColor,
          elevation: 0,
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'KHOẢN CHI'),
              Tab(text: 'KHOẢN THU'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryList(type: 'expense'),
            _CategoryList(type: 'income'),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final String type;

  const _CategoryList({required this.type});

  @override
  Widget build(BuildContext context) {
    final categories = type == 'expense' 
        ? CategoryConstants.expenseCategories 
        : CategoryConstants.incomeCategories;

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final name = category['name'] as String;
        final icon = category['icon'] as IconData;
        final color = category['color'] as Color;

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            Navigator.pop(context, {
              'name': name,
              'type': type,
            });
          },
        );
      },
    );
  }
}
