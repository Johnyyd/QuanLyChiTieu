import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/category_constants.dart';
import '../../groups/providers/groups_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../expenses/models/expense_model.dart';
import '../../auth/providers/user_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String? selectedGroupId;
  String _timeRange = 'Tháng này';

  Future<void> _exportToCSV(BuildContext context, WidgetRef ref) async {
    if (selectedGroupId == null) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang xuất dữ liệu...')),
      );

      final expenses = await ref.read(expensesProvider(selectedGroupId!).future);
      
      final now = DateTime.now();
      final filtered = expenses.where((e) {
        if (e.type == 'settlement') return false;
        if (_timeRange == 'Tháng này') {
          return e.date.year == now.year && e.date.month == now.month;
        } else if (_timeRange == 'Tháng trước') {
          final lastMonth = DateTime(now.year, now.month - 1);
          return e.date.year == lastMonth.year && e.date.month == lastMonth.month;
        }
        return true;
      }).toList();

      if (filtered.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có dữ liệu để xuất')),
          );
        }
        return;
      }

      StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln("Ngày,Loại,Danh mục,Số tiền,Người tạo,Ghi chú");
      
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      for (var e in filtered) {
        String date = dateFormat.format(e.date);
        String type = e.type == 'income' ? 'Thu' : 'Chi';
        String category = '"${e.category.replaceAll('"', '""')}"';
        String amount = e.amount.toString();
        String paidBy = '"${e.paidBy.replaceAll('"', '""')}"';
        String note = '"${e.description.replaceAll('"', '""')}"';
        
        csvBuffer.writeln("$date,$type,$category,$amount,$paidBy,$note");
      }

      String csv = csvBuffer.toString();
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/bao_cao_chi_tieu_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      if (context.mounted) {
        final xfile = XFile(file.path);
        await Share.shareXFiles([xfile], text: 'Báo cáo chi tiêu');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo phân tích'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Xuất CSV',
            onPressed: () => _exportToCSV(context, ref),
          ),
        ],
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
                      child: DropdownButtonHideUnderline(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ví / Nhóm',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedGroupId,
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonHideUnderline(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Thời gian',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _timeRange,
                            items: const [
                              DropdownMenuItem(value: 'Tháng này', child: Text('Tháng này')),
                              DropdownMenuItem(value: 'Tháng trước', child: Text('Tháng trước')),
                              DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _timeRange = val);
                              }
                            },
                          ),
                        ),
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
        final Map<String, double> userTotals = {};

        for (var e in expenses) {
          if (e.type == 'income') {
            totalIncome += e.amount;
          } else if (e.type == 'expense') {
            totalExpense += e.amount;
            categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
            userTotals[e.paidBy] = (userTotals[e.paidBy] ?? 0) + e.amount;
          }
        }

        final balance = totalIncome - totalExpense;
        final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

        // Sắp xếp danh mục theo số tiền giảm dần
        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Sắp xếp người dùng theo số tiền giảm dần
        final sortedUsers = userTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tổng quan
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('TỔNG QUAN', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng thu', style: TextStyle(color: Colors.white)),
                          Text(currencyFormat.format(totalIncome), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng chi', style: TextStyle(color: Colors.white)),
                          Text(currencyFormat.format(totalExpense), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Colors.white24),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Số dư', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          Text(
                            currencyFormat.format(balance), 
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 22
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Biểu đồ đường (Xu hướng chi tiêu)
              if (totalExpense > 0) ...[
                const Text('Xu hướng chi tiêu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: _buildLineChart(expenses, timeRange, context),
                ),
                const SizedBox(height: 32),

                // 3. Biểu đồ tròn (Cơ cấu chi tiêu)
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

                // 4. Danh sách chi tiết từng danh mục
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
                        backgroundColor: color.withValues(alpha: 0.2),
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

                // 5. Danh sách chi tiết từng người dùng
                if (sortedUsers.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Text('Chi tiêu theo thành viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedUsers.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = sortedUsers[index];
                        final userId = entry.key;
                        final amount = entry.value;
                        final percentage = (amount / totalExpense) * 100;
                        
                        return Consumer(
                          builder: (context, ref, _) {
                            final userAsync = ref.watch(userProfileProvider(userId));
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                              ),
                              title: userAsync.when(
                                data: (user) => Text(user?.name ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.bold)),
                                loading: () => const Text('Đang tải...', style: TextStyle(fontSize: 14)),
                                error: (_, __) => const Text('Lỗi', style: TextStyle(fontSize: 14)),
                              ),
                              subtitle: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey.shade200,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(currencyFormat.format(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildLineChart(List<Expense> expenses, String timeRange, BuildContext context) {
    final Map<int, double> groupedExpenses = {};
    final now = DateTime.now();
    final isAllTime = timeRange == 'Tất cả';
    int maxX = isAllTime ? 12 : 31;
    
    if (!isAllTime) {
      if (timeRange == 'Tháng trước') {
         maxX = DateTime(now.year, now.month, 0).day;
      } else if (timeRange == 'Tháng này') {
         maxX = DateTime(now.year, now.month + 1, 0).day;
      }
    }

    for (var e in expenses) {
      if (e.type == 'expense') {
        int key = isAllTime ? e.date.month : e.date.day;
        groupedExpenses[key] = (groupedExpenses[key] ?? 0) + e.amount;
      }
    }
    
    final List<FlSpot> spots = [];
    double maxExpense = 0;
    for (int i = 1; i <= maxX; i++) {
      double val = groupedExpenses[i] ?? 0;
      if (val > maxExpense) maxExpense = val;
      spots.add(FlSpot(i.toDouble(), val));
    }

    if (maxExpense == 0) maxExpense = 100000;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxExpense > 0 ? (maxExpense / 4) : 100000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: isAllTime ? 1 : 3,
              getTitlesWidget: (value, meta) {
                if (value.toInt() == 0 || value.toInt() > maxX) return const SizedBox();
                return Text(
                  isAllTime ? 'T${value.toInt()}' : value.toInt().toString(), 
                  style: const TextStyle(fontSize: 10, color: Colors.grey)
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 1,
        maxX: maxX.toDouble(),
        minY: 0,
        maxY: maxExpense * 1.2,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.primaryContainer,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
                final dateStr = isAllTime ? 'Tháng ${spot.x.toInt()}' : 'Ngày ${spot.x.toInt()}';
                return LineTooltipItem(
                  '$dateStr\n${format.format(spot.y)}',
                  TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
