import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/recurring_expense_provider.dart';
import '../models/recurring_expense_model.dart';
import '../../../core/constants/category_constants.dart';

class RecurringExpensesScreen extends ConsumerWidget {
  final String groupId;

  const RecurringExpensesScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringExpensesProvider(groupId));
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khoản chi định kỳ'),
      ),
      body: recurringAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(
              child: Text('Chưa có khoản chi định kỳ nào.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: CategoryConstants.getColor(expense.category).withValues(alpha: 0.2),
                    child: Icon(
                      CategoryConstants.getIcon(expense.category),
                      color: CategoryConstants.getColor(expense.category),
                    ),
                  ),
                  title: Text(
                    expense.description,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Số tiền: ${currencyFormat.format(expense.amount)}',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Tần suất: ${_getFrequencyText(expense.frequency)}'),
                      const SizedBox(height: 4),
                      Text('Lần tiếp theo: ${dateFormat.format(expense.nextRunDate)}'),
                    ],
                  ),
                  trailing: Switch(
                    value: expense.isActive,
                    onChanged: (val) {
                      ref.read(recurringExpenseServiceProvider).updateRecurringExpense(
                        expense.copyWith(isActive: val),
                      );
                    },
                  ),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xóa khoản chi định kỳ?'),
                        content: const Text('Bạn có chắc chắn muốn xóa khoản chi này? Các giao dịch đã sinh ra sẽ không bị ảnh hưởng.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(recurringExpenseServiceProvider).deleteRecurringExpense(groupId, expense.id);
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, trace) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  String _getFrequencyText(Frequency frequency) {
    switch (frequency) {
      case Frequency.daily: return 'Hàng ngày';
      case Frequency.weekly: return 'Hàng tuần';
      case Frequency.monthly: return 'Hàng tháng';
      case Frequency.yearly: return 'Hàng năm';
    }
  }
}
