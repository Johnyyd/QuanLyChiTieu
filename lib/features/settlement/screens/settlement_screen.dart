import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../groups/models/group_model.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../services/settlement_service.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/models/expense_model.dart';
import '../../../core/theme/app_theme.dart';

class SettlementScreen extends ConsumerWidget {
  final AppGroup group;

  const SettlementScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(group.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng kết số dư'),
      ),
      body: expensesAsync.when(
        data: (expenses) {
          final settlementService = ref.read(settlementServiceProvider);
          final transactions = settlementService.calculateSettlements(group, expenses);

          if (transactions.isEmpty) {
            return const Center(
              child: Text('Chưa có chi tiêu nào hoặc mọi người đã thanh toán xong.'),
            );
          }

          final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  onTap: () async {
                    final currentUser = ref.read(authStateProvider).value;
                    if (currentUser == null) return;
                    
                    // Chỉ cho phép người nợ (fromUserId) hoặc người nhận (toUserId) xác nhận
                    if (currentUser.uid != tx.fromUserId && currentUser.uid != tx.toUserId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chỉ người có liên quan mới có thể xác nhận thanh toán')),
                      );
                      return;
                    }

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận thanh toán'),
                        content: Text('Đánh dấu khoản nợ ${currencyFormat.format(tx.amount)} đã được thanh toán?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Xác nhận'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        final expense = Expense(
                          id: '',
                          groupId: group.id,
                          description: 'Thanh toán nợ',
                          amount: tx.amount,
                          category: 'Settle Up',
                          paidBy: tx.fromUserId,
                          toUserId: tx.toUserId,
                          date: DateTime.now(),
                          type: 'settlement',
                        );
                        await ref.read(expenseServiceProvider).addExpense(expense);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã ghi nhận thanh toán')),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.sync_alt, color: Colors.orange),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Người cần trả', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final userAsync = ref.watch(userProfileProvider(tx.fromUserId));
                                      return userAsync.when(
                                        data: (user) => Text(
                                          user?.name ?? 'Ẩn danh',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        loading: () => const SizedBox(width: 50, height: 10, child: LinearProgressIndicator()),
                                        error: (_, __) => const Text('Lỗi'),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Người nhận', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final userAsync = ref.watch(userProfileProvider(tx.toUserId));
                                      return userAsync.when(
                                        data: (user) => Text(
                                          user?.name ?? 'Ẩn danh',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        loading: () => const SizedBox(width: 50, height: 10, child: LinearProgressIndicator()),
                                        error: (_, __) => const Text('Lỗi'),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(thickness: 1, color: Colors.grey),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Số tiền nợ:', style: TextStyle(color: Colors.grey)),
                            Text(
                              currencyFormat.format(tx.amount),
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: null, // Logic handled by InkWell or outer onTap, but we want button visual
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Xác nhận đã thanh toán'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade100, // Make it look clickable inside card
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
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
}
