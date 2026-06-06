import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/expense_model.dart';
import '../providers/expenses_provider.dart';
import '../../../core/constants/category_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../categories/screens/category_selection_screen.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AddExpenseScreen({super.key, required this.groupId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Ăn uống';
  bool _isLoading = false;
  String _transactionType = 'expense';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm khoản chi tiêu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Chi tiền'), icon: Icon(Icons.arrow_upward)),
                  ButtonSegment(value: 'income', label: Text('Thu tiền'), icon: Icon(Icons.arrow_downward)),
                ],
                selected: {_transactionType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _transactionType = newSelection.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(fontSize: 48, color: Colors.grey.shade400),
                suffixText: 'đ',
                suffixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              style: TextStyle(
                fontSize: 48, 
                fontWeight: FontWeight.bold, 
                color: _transactionType == 'expense' ? Colors.red.shade700 : AppTheme.successColor,
              ),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.calendar_today)),
              title: const Text('Ngày giao dịch'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: CategoryConstants.getColor(_selectedCategory).withOpacity(0.2),
                child: Icon(
                  CategoryConstants.getIcon(_selectedCategory),
                  color: CategoryConstants.getColor(_selectedCategory),
                ),
              ),
              title: const Text('Danh mục'),
              subtitle: Text(_selectedCategory, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategorySelectionScreen(initialType: _transactionType),
                  ),
                );
                
                if (result != null) {
                  setState(() {
                    _selectedCategory = result['name'] as String;
                    _transactionType = result['type'] as String;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                final description = _descriptionController.text.trim();
                final amountText = _amountController.text.trim();
                if (description.isEmpty || amountText.isEmpty) return;

                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Số tiền không hợp lệ')),
                  );
                  return;
                }

                final user = ref.read(authStateProvider).value;
                if (user != null) {
                  setState(() => _isLoading = true);
                  try {
                    final expense = Expense(
                      id: '', // Will be generated by Firestore
                      groupId: widget.groupId,
                      description: description,
                      amount: amount,
                      category: _selectedCategory,
                      paidBy: user.uid,
                      date: _selectedDate,
                      type: _transactionType,
                    );
                    
                    await ref.read(expenseServiceProvider).addExpense(expense);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Thêm', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
