import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../groups/models/group_model.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../expenses/screens/add_expense_screen.dart';
import '../../settlement/screens/settlement_screen.dart';
import '../../auth/providers/user_provider.dart';

class GroupDetailScreen extends ConsumerWidget {
  final AppGroup group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(group.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettlementScreen(group: group),
                ),
              );
            },
            tooltip: 'Tổng kết',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Thông tin nhóm'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tên nhóm: ${group.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Số thành viên: ${group.members.length}'),
                      const SizedBox(height: 16),
                      const Text('Mã nhóm để mời bạn bè:', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4, right: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                group.id,
                                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.teal),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: group.id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã sao chép mã nhóm!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Hãy gửi mã này cho bạn bè để họ nhập ở màn hình Tham gia nhóm.',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Thông tin nhóm',
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.teal.shade200),
                  const SizedBox(height: 16),
                  const Text('Chưa có khoản chi tiêu nào'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade50,
                  child: Icon(Icons.category, color: Colors.teal.shade700),
                ),
                title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${expense.category} • ${DateFormat('dd/MM/yyyy').format(expense.date)}'),
                    Consumer(
                      builder: (context, ref, _) {
                        final userAsync = ref.watch(userProfileProvider(expense.paidBy));
                        return userAsync.when(
                          data: (user) => Text(
                            'Trả bởi: ${user?.name ?? 'Không rõ'}',
                            style: const TextStyle(fontSize: 12, color: Colors.teal),
                          ),
                          loading: () => const Text('Đang tải...', style: TextStyle(fontSize: 12)),
                          error: (_, __) => const Text('Lỗi', style: TextStyle(fontSize: 12)),
                        );
                      },
                    ),
                  ],
                ),
                trailing: Text(
                  currencyFormat.format(expense.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                isThreeLine: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, trace) => Center(child: Text('Lỗi: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(groupId: group.id),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
