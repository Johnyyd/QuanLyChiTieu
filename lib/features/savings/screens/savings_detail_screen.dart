import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import '../providers/savings_provider.dart';
import '../models/savings_model.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../expenses/models/expense_model.dart';
import '../../groups/providers/groups_provider.dart';
import '../../groups/models/group_model.dart';
import '../../personal/providers/personal_provider.dart';

class SavingsDetailScreen extends ConsumerStatefulWidget {
  final SavingsGoal goal;

  const SavingsDetailScreen({super.key, required this.goal});

  @override
  ConsumerState<SavingsDetailScreen> createState() => _SavingsDetailScreenState();
}

class _SavingsDetailScreenState extends ConsumerState<SavingsDetailScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  void _showFundDialog(BuildContext context, bool isAdding) {
    final amountController = MoneyMaskedTextController(decimalSeparator: '', thousandSeparator: ',', precision: 0, rightSymbol: 'đ');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isAdding ? 'Nạp tiền vào quỹ' : 'Rút tiền từ quỹ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              if (isAdding)
                const Text('Lưu ý: Nạp tiền vào quỹ sẽ được ghi nhận là một khoản chi tiêu trong Ví Cá Nhân.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = amountController.numberValue;
                if (amount <= 0) return;
                if (!isAdding && amount > widget.goal.currentAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số dư không đủ để rút')));
                  return;
                }

                Navigator.pop(dialogContext); // Close dialog
                
                try {
                  if (isAdding) {
                    await ref.read(savingsServiceProvider).addFundToGoal(widget.goal.id, amount);
                    // Add expense to personal wallet
                    final personalGroup = await ref.read(personalGroupFutureProvider.future);
                    if (personalGroup != null) {
                      final expense = Expense(
                        id: '',
                        groupId: personalGroup.id,
                        description: 'Gửi tiền vào quỹ: ${widget.goal.title}',
                        amount: amount,
                        category: 'Tiết kiệm',
                        paidBy: widget.goal.userId,
                        date: DateTime.now(),
                      );
                      await ref.read(expenseServiceProvider).addExpense(expense);
                    }
                  } else {
                    await ref.read(savingsServiceProvider).withdrawFundFromGoal(widget.goal.id, amount);
                    // Add income to personal wallet
                    final personalGroup = await ref.read(personalGroupFutureProvider.future);
                    if (personalGroup != null) {
                      final expense = Expense(
                        id: '',
                        groupId: personalGroup.id,
                        description: 'Rút tiền từ quỹ: ${widget.goal.title}',
                        amount: amount,
                        category: 'Tiết kiệm',
                        paidBy: widget.goal.userId,
                        date: DateTime.now(),
                        type: 'income',
                      );
                      await ref.read(expenseServiceProvider).addExpense(expense);
                    }
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAdding ? 'Đã nạp tiền thành công' : 'Đã rút tiền thành công')));
                    Navigator.pop(context); // Go back to refresh stream
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa mục tiêu?'),
        content: const Text('Bạn có chắc chắn muốn xóa mục tiêu này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(savingsServiceProvider).deleteSavingsGoal(widget.goal.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa mục tiêu tiết kiệm')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final goalColor = _parseColor(widget.goal.color);
    final progress = widget.goal.progress;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Circular progress
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: goalColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 16,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: goalColor),
                      ),
                      const SizedBox(height: 8),
                      Text('Hoàn thành', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Amounts
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đã tích lũy', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(widget.goal.currentAmount),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: goalColor),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Mục tiêu', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(widget.goal.targetAmount),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            if (widget.goal.targetDate != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Thời hạn mục tiêu', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(widget.goal.targetDate!),
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (widget.goal.targetDate!.isAfter(DateTime.now()))
                      Text(
                        'Còn ${widget.goal.targetDate!.difference(DateTime.now()).inDays} ngày',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    else
                      const Text('Đã quá hạn', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showFundDialog(context, true),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Nạp tiền'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: goalColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.goal.currentAmount > 0 ? () => _showFundDialog(context, false) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Rút tiền'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: goalColor,
                      side: BorderSide(color: goalColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
