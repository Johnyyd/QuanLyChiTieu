import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../groups/models/group_model.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../services/settlement_service.dart';
import '../../auth/providers/user_provider.dart';

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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Debtor (người nợ)
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final userAsync = ref.watch(userProfileProvider(tx.fromUserId));
                            return userAsync.when(
                              data: (user) => Text(
                                user?.name ?? 'Người dùng',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) => const Text('Lỗi'),
                            );
                          },
                        ),
                      ),
                      
                      // Mũi tên & số tiền
                      Column(
                        children: [
                          Text(
                            currencyFormat.format(tx.amount),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_outlined, color: Colors.grey),
                          const Text('cần trả cho', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      
                      // Creditor (người nhận)
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final userAsync = ref.watch(userProfileProvider(tx.toUserId));
                            return userAsync.when(
                              data: (user) => Text(
                                user?.name ?? 'Người dùng',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) => const Text('Lỗi'),
                            );
                          },
                        ),
                      ),
                    ],
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
