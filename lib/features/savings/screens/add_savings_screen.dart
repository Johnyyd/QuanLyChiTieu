import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import '../providers/savings_provider.dart';
import '../models/savings_model.dart';
import '../../auth/providers/auth_provider.dart';

class AddSavingsScreen extends ConsumerStatefulWidget {
  const AddSavingsScreen({super.key});

  @override
  ConsumerState<AddSavingsScreen> createState() => _AddSavingsScreenState();
}

class _AddSavingsScreenState extends ConsumerState<AddSavingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late MoneyMaskedTextController _amountController;
  DateTime? _selectedDate;
  String _selectedIcon = 'savings';
  String _selectedColor = '#4CAF50';
  bool _isLoading = false;

  final List<String> _icons = ['savings', 'home', 'car', 'flight', 'laptop', 'phone', 'education', 'wedding', 'health', 'emergency'];
  final List<String> _colors = ['#4CAF50', '#2196F3', '#9C27B0', '#FF9800', '#F44336', '#009688', '#E91E63', '#3F51B5'];

  @override
  void initState() {
    super.initState();
    _amountController = MoneyMaskedTextController(decimalSeparator: '', thousandSeparator: ',', precision: 0, rightSymbol: 'đ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home': return Icons.home;
      case 'car': return Icons.directions_car;
      case 'flight': return Icons.flight_takeoff;
      case 'laptop': return Icons.laptop_mac;
      case 'phone': return Icons.smartphone;
      case 'education': return Icons.school;
      case 'wedding': return Icons.favorite;
      case 'health': return Icons.health_and_safety;
      case 'emergency': return Icons.warning_amber;
      case 'savings': 
      default: return Icons.savings;
    }
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }

  void _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;
    
    final targetAmount = _amountController.numberValue;
    if (targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số tiền mục tiêu hợp lệ')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('Vui lòng đăng nhập lại');

      final goal = SavingsGoal(
        id: '',
        userId: user.uid,
        title: _titleController.text.trim(),
        targetAmount: targetAmount,
        targetDate: _selectedDate,
        icon: _selectedIcon,
        color: _selectedColor,
      );

      await ref.read(savingsServiceProvider).addSavingsGoal(goal);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo mục tiêu tiết kiệm mới')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm mục tiêu mới'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Tên mục tiêu',
                      prefixIcon: Icon(_getIconData(_selectedIcon), color: _parseColor(_selectedColor)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Vui lòng nhập tên mục tiêu' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền mục tiêu',
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Ngày dự kiến hoàn thành (Tùy chọn)',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_selectedDate == null 
                          ? 'Chưa chọn ngày' 
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Biểu tượng', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _icons.map((icon) {
                      final isSelected = _selectedIcon == icon;
                      return InkWell(
                        onTap: () => setState(() => _selectedIcon = icon),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? _parseColor(_selectedColor).withValues(alpha: 0.2) : Colors.grey.shade100,
                            border: Border.all(color: isSelected ? _parseColor(_selectedColor) : Colors.transparent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getIconData(icon), color: isSelected ? _parseColor(_selectedColor) : Colors.grey),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Màu sắc', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _colors.map((color) {
                      final isSelected = _selectedColor == color;
                      final c = _parseColor(color);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.black54, width: 3) : null,
                            boxShadow: [
                              if (isSelected) BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)
                            ],
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveGoal,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tạo Mục Tiêu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}
