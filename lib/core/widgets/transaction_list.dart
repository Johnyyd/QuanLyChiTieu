import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/expenses/providers/expenses_provider.dart';
import '../../features/expenses/screens/edit_expense_screen.dart';
import '../../features/auth/providers/user_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../constants/category_constants.dart';

class TransactionList extends ConsumerWidget {
  final List<Expense> expenses;
  final bool isPersonal;

  const TransactionList({
    super.key,
    required this.expenses,
    this.isPersonal = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;

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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isIncome ? '+${formatter.format(expense.amount)}' : '-${formatter.format(expense.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isIncome ? AppTheme.successColor : Theme.of(context).colorScheme.error,
                        ),
                      ),
                      if (currentUser != null && expense.paidBy == currentUser.uid)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditExpenseScreen(expense: expense),
                                ),
                              );
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Xóa giao dịch'),
                                  content: const Text('Bạn có chắc chắn muốn xóa giao dịch này không?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, false),
                                      child: const Text('Hủy'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, true),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Xóa'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                try {
                                  await ref.read(expenseServiceProvider).deleteExpense(expense.groupId, expense.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã xóa giao dịch')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e')),
                                    );
                                  }
                                }
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Sửa'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Xóa', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  onLongPress: () {
                    final currentUser = ref.read(authStateProvider).value;
                    if (currentUser == null) return;
                    
                    if (expense.paidBy != currentUser.uid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bạn chỉ có thể sửa/xóa giao dịch do chính bạn tạo')),
                      );
                      return;
                    }

                    showModalBottomSheet(
                      context: context,
                      builder: (bottomSheetContext) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit, color: Colors.blue),
                              title: const Text('Sửa giao dịch'),
                              onTap: () {
                                Navigator.pop(bottomSheetContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditExpenseScreen(expense: expense),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: const Text('Xóa giao dịch'),
                              onTap: () async {
                                Navigator.pop(bottomSheetContext);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Xóa giao dịch'),
                                    content: const Text('Bạn có chắc chắn muốn xóa giao dịch này không?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext, false),
                                        child: const Text('Hủy'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext, true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true) {
                                  try {
                                    await ref.read(expenseServiceProvider).deleteExpense(expense.groupId, expense.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã xóa giao dịch')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Lỗi: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
