import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/expenses/providers/expenses_provider.dart';
import '../../features/expenses/screens/edit_expense_screen.dart';
import '../../features/auth/providers/user_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../constants/category_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TransactionList extends ConsumerStatefulWidget {
  final List<Expense> expenses;
  final bool isPersonal;

  const TransactionList({
    super.key,
    required this.expenses,
    this.isPersonal = false,
  });

  @override
  ConsumerState<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends ConsumerState<TransactionList> {
  String _searchQuery = '';
  String _filterType = 'all';
  String? _filterCategory;
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;

    if (widget.expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Chưa có giao dịch nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      );
    }

    // Lọc dữ liệu
    var filteredExpenses = widget.expenses.where((expense) {
      bool matchesSearch = expense.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           expense.category.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesType = _filterType == 'all' || expense.type == _filterType;
      bool matchesCategory = _filterCategory == null || expense.category == _filterCategory;
      return matchesSearch && matchesType && matchesCategory;
    }).toList();

    // Group expenses by date
    final Map<String, List<Expense>> groupedExpenses = {};
    for (var expense in filteredExpenses) {
      final dateStr = DateFormat('yyyy-MM-dd').format(expense.date);
      if (!groupedExpenses.containsKey(dateStr)) {
        groupedExpenses[dateStr] = [];
      }
      groupedExpenses[dateStr]!.add(expense);
    }

    final sortedDates = groupedExpenses.keys.toList()..sort((a, b) => b.compareTo(a));
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Get unique categories for filter dropdown
    final allCategories = widget.expenses.map((e) => e.category).toSet().toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Thanh tìm kiếm và nút lọc
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm giao dịch...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                icon: Icon(
                  _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: _showFilters ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
                tooltip: 'Bộ lọc',
                style: IconButton.styleFrom(
                  backgroundColor: _showFilters ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),

        // Các tùy chọn bộ lọc (hiển thị khi _showFilters = true)
        if (_showFilters) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Loại giao dịch:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'all', _filterType, (val) => setState(() => _filterType = val)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tiền thu', 'income', _filterType, (val) => setState(() => _filterType = val)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tiền chi', 'expense', _filterType, (val) => setState(() => _filterType = val)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Danh mục:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('Tất cả', null, _filterCategory, (val) => setState(() => _filterCategory = val)),
                      ...allCategories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _buildCategoryChip(cat, cat, _filterCategory, (val) => setState(() => _filterCategory = val)),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        if (filteredExpenses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text('Không tìm thấy giao dịch nào', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ListView.builder(
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

                      final bool canEdit = currentUser != null && expense.paidBy == currentUser.uid;
                      final bool needsConfirmation = !expense.isConfirmed && canEdit;

                      return Slidable(
                        key: ValueKey(expense.id),
                        startActionPane: needsConfirmation ? ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) async {
                                try {
                                  await ref.read(expenseServiceProvider).updateExpense(
                                    expense.copyWith(isConfirmed: true),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã xác nhận giao dịch')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e')),
                                    );
                                  }
                                }
                              },
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                              icon: Icons.check,
                              label: 'Xác nhận',
                            ),
                          ],
                        ) : null,
                        endActionPane: canEdit ? ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditExpenseScreen(expense: expense),
                                  ),
                                );
                              },
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: 'Sửa',
                            ),
                            SlidableAction(
                              onPressed: (context) async {
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
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Xóa',
                            ),
                          ],
                        ) : null,
                        child: ListTile(
                          tileColor: expense.isConfirmed ? null : Colors.orange.shade50,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: displayColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(displayIcon, color: displayColor),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w500))),
                              if (!expense.isConfirmed)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Chờ duyệt', style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                            ],
                          ),
                          subtitle: widget.isPersonal ? Text(expense.category) : Column(
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
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isIncome ? '+${formatter.format(expense.amount)}' : '-${formatter.format(expense.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isIncome ? AppTheme.successColor : Theme.of(context).colorScheme.error,
                                ),
                              ),
                              if (expense.currency != 'VND' && expense.originalAmount != null)
                                Text(
                                  '${expense.originalAmount} ${expense.currency}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms);
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, String groupValue, Function(String) onSelected) {
    final isSelected = value == groupValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value, String? groupValue, Function(String?) onSelected) {
    final isSelected = value == groupValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey.shade300,
      ),
    );
  }
}
