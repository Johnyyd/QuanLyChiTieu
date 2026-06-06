import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/personal_provider.dart';
import '../../savings/providers/savings_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../expenses/models/expense_model.dart';
import '../../expenses/screens/add_expense_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/category_constants.dart';
import '../../../core/widgets/transaction_list.dart';
import '../../groups/models/group_model.dart';
import '../../groups/providers/groups_provider.dart';
import 'package:shimmer/shimmer.dart';

class PersonalScreen extends ConsumerWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalGroupAsync = ref.watch(personalGroupFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví Cá Nhân'),
        actions: [
          if (personalGroupAsync.value != null)
            IconButton(
              icon: const Icon(Icons.account_balance_wallet),
              tooltip: 'Thiết lập ngân sách',
              onPressed: () => _showBudgetDialog(context, ref, personalGroupAsync.value!),
            ),
        ],
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
                    _buildDashboardCard(context, group, ref, totalIncome, totalExpense, balance, formatter),
                    _buildSavingsPreview(context, ref, formatter),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TransactionList(expenses: expenses, isPersonal: true),
                    ),
                  ],
                ),
              );
            },
            loading: () => _buildShimmerLoading(),
            error: (e, trace) => Center(child: Text('Lỗi: $e')),
          );
        },
        loading: () => _buildShimmerLoading(),
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
              label: Text('Thêm giao dịch', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref, AppGroup group) {
    final controller = TextEditingController(text: group.budget?.toStringAsFixed(0) ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thiết lập ngân sách'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Ngân sách chi tiêu hàng tháng',
            suffixText: 'đ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final budgetText = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
              final budget = budgetText.isNotEmpty ? double.tryParse(budgetText) : null;
              
              await ref.read(groupServiceProvider).updateGroupBudget(group.id, budget);
              ref.invalidate(personalGroupFutureProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, AppGroup group, WidgetRef ref, double income, double expense, double balance, NumberFormat formatter) {
    final budget = group.budget;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('SỐ DƯ HIỆN TẠI', style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            formatter.format(balance),
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('THU NHẬP', income, AppTheme.successColor, formatter),
              Container(width: 1, height: 40, color: colorScheme.onPrimary.withValues(alpha: 0.24)),
              _buildStatItem('CHI TIÊU', expense, Colors.redAccent, formatter),
            ],
          ),
          if (budget != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ngân sách:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  '${formatter.format(expense)} / ${formatter.format(budget)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (expense / budget).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  expense > budget ? Colors.redAccent : AppTheme.successColor,
                ),
                minHeight: 8,
              ),
            ),
            if (expense > budget)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Cảnh báo: Đã vượt quá ngân sách!',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ] else ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ngân sách:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                GestureDetector(
                  onTap: () => _showBudgetDialog(context, ref, group),
                  child: const Text(
                    'Chưa thiết lập (Chạm để thêm)',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, decorationColor: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 0,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.5)),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSavingsPreview(BuildContext context, WidgetRef ref, NumberFormat formatter) {
    final savingsAsync = ref.watch(savingsProvider);

    return savingsAsync.when(
      data: (goals) {
        if (goals.isEmpty) return const SizedBox.shrink();
        
        // Show up to 2 active goals
        final activeGoals = goals.where((g) => !g.isCompleted).take(2).toList();
        if (activeGoals.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mục tiêu tiết kiệm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              ...activeGoals.map((goal) {
                final progress = goal.progress;
                final goalColor = Color(int.parse(goal.color.replaceFirst('#', 'FF'), radix: 16));

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(color: goalColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: goalColor.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatter.format(goal.currentAmount), style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                          Text(formatter.format(goal.targetAmount), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(5, (index) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
