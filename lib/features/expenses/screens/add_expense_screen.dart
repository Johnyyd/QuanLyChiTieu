import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/expense_model.dart';
import '../providers/expenses_provider.dart';
import '../../../core/constants/category_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../categories/screens/category_selection_screen.dart';
import '../../recurring_expenses/models/recurring_expense_model.dart';
import '../../recurring_expenses/providers/recurring_expense_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/ocr_service.dart';

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
  bool _isRecurring = false;
  Frequency _frequency = Frequency.monthly;

  String _selectedCurrency = 'VND';
  static const Map<String, double> _exchangeRates = {
    'VND': 1.0,
    'USD': 25400.0,
    'EUR': 27500.0,
    'JPY': 165.0,
  };

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(fontSize: 48, color: Colors.grey.shade400),
                    ),
                    style: TextStyle(
                      fontSize: 48, 
                      fontWeight: FontWeight.bold, 
                      color: _transactionType == 'expense' ? Colors.red.shade700 : AppTheme.successColor,
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState(() {}),
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedCurrency,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  items: _exchangeRates.keys.map((String currency) {
                    return DropdownMenuItem<String>(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCurrency = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            if (_selectedCurrency != 'VND')
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '≈ ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VND').format((double.tryParse(_amountController.text) ?? 0) * _exchangeRates[_selectedCurrency]!)}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            Center(
              child: TextButton.icon(
                onPressed: _isLoading ? null : _scanReceipt,
                icon: const Icon(Icons.document_scanner),
                label: const Text('Quét Hóa Đơn'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lặp lại định kỳ', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tự động tạo khoản này vào các kỳ tiếp theo'),
              value: _isRecurring,
              onChanged: (val) {
                setState(() => _isRecurring = val);
              },
              secondary: const CircleAvatar(child: Icon(Icons.repeat)),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<Frequency>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Chu kỳ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.update),
                ),
                items: const [
                  DropdownMenuItem(value: Frequency.daily, child: Text('Hàng ngày')),
                  DropdownMenuItem(value: Frequency.weekly, child: Text('Hàng tuần')),
                  DropdownMenuItem(value: Frequency.monthly, child: Text('Hàng tháng')),
                  DropdownMenuItem(value: Frequency.yearly, child: Text('Hàng năm')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _frequency = val);
                },
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                final description = _descriptionController.text.trim();
                final amountText = _amountController.text.trim();
                if (description.isEmpty || amountText.isEmpty) return;

                final inputAmount = double.tryParse(amountText);
                if (inputAmount == null || inputAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Số tiền không hợp lệ')),
                  );
                  return;
                }
                
                final exchangeRate = _exchangeRates[_selectedCurrency] ?? 1.0;
                final amountInVND = inputAmount * exchangeRate;

                final user = ref.read(authStateProvider).value;
                if (user != null) {
                  setState(() => _isLoading = true);
                  try {
                    if (_isRecurring) {
                      // Tính toán nextRunDate thực sự cho chu kỳ tiếp theo
                      DateTime nextDate = _selectedDate;
                      switch (_frequency) {
                        case Frequency.daily:
                          nextDate = nextDate.add(const Duration(days: 1));
                          break;
                        case Frequency.weekly:
                          nextDate = nextDate.add(const Duration(days: 7));
                          break;
                        case Frequency.monthly:
                          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
                          break;
                        case Frequency.yearly:
                          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
                          break;
                      }

                      final recurring = RecurringExpense(
                        id: '',
                        groupId: widget.groupId,
                        description: description,
                        amount: amountInVND,
                        category: _selectedCategory,
                        paidBy: user.uid,
                        frequency: _frequency,
                        nextRunDate: nextDate,
                      );
                      
                      // 1. Add recurring expense setting
                      await ref.read(recurringExpenseServiceProvider).addRecurringExpense(recurring);
                      // 2. Add the actual expense for today
                      final expense = Expense(
                        id: '',
                        groupId: widget.groupId,
                        description: description,
                        amount: amountInVND,
                        category: _selectedCategory,
                        paidBy: user.uid,
                        date: _selectedDate,
                        type: _transactionType,
                        currency: _selectedCurrency,
                        originalAmount: _selectedCurrency != 'VND' ? inputAmount : null,
                        exchangeRate: exchangeRate,
                      );
                      await ref.read(expenseServiceProvider).addExpense(expense);
                      
                    } else {
                      final expense = Expense(
                        id: '', // Will be generated by Firestore
                        groupId: widget.groupId,
                        description: description,
                        amount: amountInVND,
                        category: _selectedCategory,
                        paidBy: user.uid,
                        date: _selectedDate,
                        type: _transactionType,
                        currency: _selectedCurrency,
                        originalAmount: _selectedCurrency != 'VND' ? inputAmount : null,
                        exchangeRate: exchangeRate,
                      );
                      await ref.read(expenseServiceProvider).addExpense(expense);
                    }
                    
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

  Future<void> _scanReceipt() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ảnh hóa đơn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      setState(() => _isLoading = true);
      try {
        final ocrService = ref.read(ocrServiceProvider);
        final file = await ocrService.pickImage(source);
        if (file != null) {
          final amount = await ocrService.extractAmountFromImage(file);
          if (amount != null) {
            setState(() {
              _amountController.text = amount.toStringAsFixed(0);
            });
            if (mounted) {
              final formattedAmount = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã nhận diện số tiền: $formattedAmount'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không tìm thấy tổng tiền hợp lệ trong ảnh'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi quét hóa đơn: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
