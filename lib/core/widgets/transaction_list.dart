import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/auth/providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../constants/category_constants.dart';

class TransactionList extends StatelessWidget {
  final List<Expense> expenses;
  final bool isPersonal;

  const TransactionList({
    super.key,
    required this.expenses,
    this.isPersonal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Chưa có giao dịch nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      );
    }

    // Group expenses by date
    final Map<String, List<Expense>> groupedExpenses = {};
    for (var expense in expenses) {
      final dateStr = DateFormat('yyyy-MM-dd').format(expense.date);
      if (!groupedExpenses.containsKey(dateStr)) {
        groupedExpenses[dateStr] = [];
      }
      groupedExpenses[dateStr]!.add(expense);
    }

    final sortedDates = groupedExpenses.keys.toList()..sort((a, b) => b.compareTo(a));
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateStr = sortedDates[index];
        final dayExpenses = groupedExpenses[dateStr]!;
        
        double dailyTotal = 0;
        for (var e in dayExpenses) {
          if (e.type == 'income') {
            dailyTotal += e.amount;
          } else {
            dailyTotal -= e.amount;
          }
        }

        final parsedDate = DateTime.parse(dateStr);
        String dateDisplay;
        final now = DateTime.now();
        if (parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day) {
          dateDisplay = 'Hôm nay';
        } else if (parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day - 1) {
          dateDisplay = 'Hôm qua';
        } else {
          dateDisplay = DateFormat('dd/MM/yyyy').format(parsedDate);
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateDisplay,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      formatter.format(dailyTotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: dailyTotal >= 0 ? AppTheme.successColor : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              ...dayExpenses.map((expense) {
                final isIncome = expense.type == 'income';
                final isSettlement = expense.type == 'settlement';
                
                IconData displayIcon = CategoryConstants.getIcon(expense.category);
                Color displayColor = CategoryConstants.getColor(expense.category);

                if (isIncome) {
                  displayIcon = Icons.monetization_on;
                  displayColor = AppTheme.successColor;
                } else if (isSettlement) {
                  displayIcon = Icons.handshake;
                  displayColor = Colors.orange;
                }

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: displayColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(displayIcon, color: displayColor),
                  ),
                  title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: isPersonal ? Text(expense.category) : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.category),
                      Consumer(
                        builder: (context, ref, _) {
                          final userAsync = ref.watch(userProfileProvider(expense.paidBy));
                          return userAsync.when(
                            data: (user) {
                              final label = isIncome ? 'Người thu' : 'Người chi';
                              return Text(
                                '$label: ${user?.name ?? 'Không rõ'}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.secondaryColor),
                              );
                            },
                            loading: () => const Text('Đang tải...', style: TextStyle(fontSize: 12)),
                            error: (_, __) => const Text('Lỗi', style: TextStyle(fontSize: 12)),
                          );
                        },
                      ),
                    ],
                  ),
                  trailing: Text(
                    isIncome ? '+${formatter.format(expense.amount)}' : '-${formatter.format(expense.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isIncome ? AppTheme.successColor : Colors.red.shade700,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
