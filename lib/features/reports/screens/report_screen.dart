import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/category_constants.dart';
import '../../groups/providers/groups_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../expenses/models/expense_model.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String? selectedGroupId;
  String _timeRange = 'Tháng này';

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo phân tích'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(child: Text('Bạn chưa tham gia nhóm nào.'));
          }

          if (selectedGroupId == null || !groups.any((g) => g.id == selectedGroupId)) {
            selectedGroupId = groups.first.id;
          }

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Ví / Nhóm',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: groups.map((g) {
                          return DropdownMenuItem<String>(
                            value: g.id,
                            child: Text(g.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (groupId) {
                          setState(() => selectedGroupId = groupId);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _timeRange,
                        decoration: const InputDecoration(
                          labelText: 'Thời gian',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Tháng này', child: Text('Tháng này')),
                          DropdownMenuItem(value: 'Tháng trước', child: Text('Tháng trước')),
                          DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _timeRange = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: selectedGroupId == null
                  ? const SizedBox()
                  : _AdvancedReportChart(groupId: selectedGroupId!, timeRange: _timeRange),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}

class _AdvancedReportChart extends ConsumerWidget {
  final String groupId;
  final String timeRange;

  const _AdvancedReportChart({required this.groupId, required this.timeRange});

  List<Expense> _filterExpenses(List<Expense> expenses) {
    final now = DateTime.now();
    return expenses.where((e) {
      if (e.type == 'settlement') return false; // Ignore settlements in reports
      
      if (timeRange == 'Tháng này') {
        return e.date.year == now.year && e.date.month == now.month;
      } else if (timeRange == 'Tháng trước') {
        final lastMonth = DateTime(now.year, now.month - 1);
        return e.date.year == lastMonth.year && e.date.month == lastMonth.month;
      }
      return true; // Tất cả
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(groupId));

    return expensesAsync.when(
      data: (allExpenses) {
        final expenses = _filterExpenses(allExpenses);
        
        if (expenses.isEmpty) {
          return const Center(child: Text('Không có dữ liệu trong khoảng thời gian này.'));
        }

        double totalIncome = 0;
        double totalExpense = 0;
        final Map<String, double> categoryTotals = {};

        for (var e in expenses) {
          if (e.type == 'income') {
            totalIncome += e.amount;
          } else if (e.type == 'expense') {
            totalExpense += e.amount;
            categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
          }
        }

        final balance = totalIncome - totalExpense;
        final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

        // Sắp xếp danh mục theo số tiền giảm dần
        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tổng quan
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('TỔNG QUAN', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng thu'),
                          Text(currencyFormat.format(totalIncome), style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng chi'),
                          Text(currencyFormat.format(totalExpense), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Số dư', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            currencyFormat.format(balance), 
                            style: TextStyle(
                              color: balance >= 0 ? AppTheme.primaryColor : Colors.red, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 18
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Biểu đồ tròn (Cơ cấu chi tiêu)
              if (totalExpense > 0) ...[
                const Text('Cơ cấu chi tiêu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: sortedCategories.map((entry) {
                        final percentage = (entry.value / totalExpense) * 100;
                        final color = CategoryConstants.getColor(entry.key);
                        return PieChartSectionData(
                          color: color,
                          value: entry.value,
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Danh sách chi tiết từng danh mục
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedCategories.length,
                  itemBuilder: (context, index) {
                    final entry = sortedCategories[index];
                    final color = CategoryConstants.getColor(entry.key);
                    final icon = CategoryConstants.getIcon(entry.key);
                    final percentage = (entry.value / totalExpense) * 100;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(entry.key),
                      subtitle: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: color,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currencyFormat.format(entry.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Lỗi: $e')),
    );
  }
}
