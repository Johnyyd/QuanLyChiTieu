import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/personal_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../expenses/models/expense_model.dart';
import '../../expenses/screens/add_expense_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/category_constants.dart';
import '../../../core/widgets/transaction_list.dart';

class PersonalScreen extends ConsumerWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalGroupAsync = ref.watch(personalGroupFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví Cá Nhân'),
      ),
      body: personalGroupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Vui lòng đăng nhập'));
          }

          final expensesAsync = ref.watch(expensesProvider(group.id));

          return expensesAsync.when(
            data: (expenses) {
              double totalIncome = 0;
              double totalExpense = 0;

              for (var e in expenses) {
                if (e.type == 'income') {
                  totalIncome += e.amount;
                } else {
                  totalExpense += e.amount;
                }
              }

              final balance = totalIncome - totalExpense;
              final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDashboardCard(totalIncome, totalExpense, balance, formatter),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TransactionList(expenses: expenses, isPersonal: true),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, trace) => Center(child: Text('Lỗi: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, trace) => Center(child: Text('Lỗi: $e')),
      ),
      floatingActionButton: personalGroupAsync.hasValue && personalGroupAsync.value != null
          ? FloatingActionButton.extended(
              heroTag: 'personal_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddExpenseScreen(groupId: personalGroupAsync.value!.id),
                  ),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thêm giao dịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDashboardCard(double income, double expense, double balance, NumberFormat formatter) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('SỐ DƯ HIỆN TẠI', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            formatter.format(balance),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('THU NHẬP', income, AppTheme.successColor, formatter),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem('CHI TIÊU', expense, Colors.redAccent, formatter),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color, NumberFormat formatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          formatter.format(amount),
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
