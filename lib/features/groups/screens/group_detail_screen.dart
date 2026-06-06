import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../groups/models/group_model.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../expenses/screens/add_expense_screen.dart';
import '../../settlement/screens/settlement_screen.dart';
import '../../expenses/models/expense_model.dart';
import '../../auth/providers/user_provider.dart';
import '../providers/groups_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settlement/services/settlement_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/category_constants.dart';
import '../../../core/widgets/transaction_list.dart';
import '../../recurring_expenses/providers/recurring_expense_provider.dart';
import '../../recurring_expenses/screens/recurring_expenses_screen.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final AppGroup group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Check and process recurring expenses when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recurringExpenseServiceProvider).checkAndProcessRecurringExpenses(widget.group.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final expensesAsync = ref.watch(expensesProvider(group.id));
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      body: expensesAsync.when(
        data: (expenses) {
          final settlementService = ref.read(settlementServiceProvider);
          final transactions = settlementService.calculateSettlements(group, expenses);
          
          double youOwe = 0;
          double youAreOwed = 0;
          double totalExpense = expenses.where((e) => e.type != 'settlement').fold(0.0, (sum, e) {
            return e.type == 'income' ? sum - e.amount : sum + e.amount;
          });
          
          if (currentUser != null) {
            for (var tx in transactions) {
              if (tx.fromUserId == currentUser.uid) {
                youOwe += tx.amount;
              } else if (tx.toUserId == currentUser.uid) {
                youAreOwed += tx.amount;
              }
            }
          }

          final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: group.budget != null ? 300.0 : 240.0,
                floating: false,
                pinned: true,
                title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                centerTitle: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                iconTheme: const IconThemeData(color: Colors.white),

                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2), // Glassmorphism
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Bạn cần trả', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        currencyFormat.format(youOwe),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Bạn sẽ nhận', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        currencyFormat.format(youAreOwed),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (group.budget != null) ...[
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Ngân sách nhóm:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      Text(
                                        '${currencyFormat.format(totalExpense)} / ${currencyFormat.format(group.budget)}',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: (totalExpense / group.budget!).clamp(0.0, 1.0),
                                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        totalExpense > group.budget! ? Theme.of(context).colorScheme.error : Colors.greenAccent,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                  if (totalExpense > group.budget!)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Đã vượt ngân sách!',
                                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'recurring') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecurringExpensesScreen(groupId: group.id),
                          ),
                        );
                      } else if (value == 'leave_group') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Rời nhóm'),
                            content: const Text('Bạn có chắc chắn muốn rời nhóm này không? Mọi dữ liệu chi tiêu của bạn trong nhóm vẫn sẽ được giữ lại.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Rời nhóm'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && currentUser != null) {
                          try {
                            await ref.read(groupServiceProvider).leaveGroup(group.id, currentUser.uid);
                            if (context.mounted) {
                              Navigator.pop(context); // Go back to groups list
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã rời nhóm thành công')),
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
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'recurring',
                        child: Text('Chi tiêu định kỳ'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'leave_group',
                        child: Text('Rời nhóm', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettlementScreen(group: group),
                        ),
                      );
                    },
                    tooltip: 'Tổng kết',
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Thông tin nhóm'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Text('Tên nhóm: ${group.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('Số thành viên: ${group.members.length}'),
                              const SizedBox(height: 16),
                              Center(
                                child: QrImageView(
                                  data: group.id,
                                  version: QrVersions.auto,
                                  size: 150.0,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Mã nhóm để mời bạn bè:', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4, right: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        group.id,
                                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                        icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.primary),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: group.id));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Đã sao chép mã nhóm!')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (expenses.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('Chưa có khoản chi tiêu nào', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: _buildPieChart(context, expenses),
                ),
                SliverToBoxAdapter(
                  child: _buildMemberStats(context, expenses),
                ),
                SliverToBoxAdapter(
                  child: TransactionList(expenses: expenses, isPersonal: false),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80), // Tạo khoảng trống ở dưới cùng để không bị che bởi FAB
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, trace) => Center(child: Text('Lỗi: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'group_detail_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(groupId: group.id),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm chi tiêu'),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, List<Expense> expenses) {
    // Chỉ lấy các expense thực sự, không lấy settlement
    final realExpenses = expenses.where((e) => e.type != 'settlement').toList();
    if (realExpenses.isEmpty) return const SizedBox.shrink();

    final Map<String, double> categoryTotals = {};
    for (var e in realExpenses) {
      if (e.type == 'income') {
        // Có thể không hiển thị thu nhập trong biểu đồ chi tiêu, hoặc gom vào 1 mục riêng.
        // Tạm thời loại bỏ thu nhập khỏi biểu đồ tròn phân bổ chi tiêu.
      } else {
        categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
      }
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final List<PieChartSectionData> sections = [];
    final List<Widget> legendItems = [];

    categoryTotals.forEach((category, total) {
      final color = CategoryConstants.getColor(category);
      sections.add(
        PieChartSectionData(
          color: color,
          value: total,
          title: '', // Ẩn text bên trong biểu đồ để tránh đè chữ
          radius: 40,
        ),
      );
      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(category, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface), overflow: TextOverflow.ellipsis),
              ),
              Text(currencyFormat.format(total), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    });

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thống kê danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: legendItems,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberStats(BuildContext context, List<Expense> expenses) {
    final Map<String, double> userTotalSpent = {
      for (var member in widget.group.members) member: 0.0
    };
    for (var e in expenses) {
      if (e.type != 'settlement') {
        userTotalSpent[e.paidBy] = (userTotalSpent[e.paidBy] ?? 0) + e.amount;
      }
    }

    if (widget.group.members.isEmpty) return const SizedBox.shrink();

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final sortedUsers = userTotalSpent.keys.toList()..sort((a, b) => userTotalSpent[b]!.compareTo(userTotalSpent[a]!));

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi tiêu theo thành viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            ...sortedUsers.map((userId) {
              final total = userTotalSpent[userId]!;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.person, size: 20, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final userAsync = ref.watch(userProfileProvider(userId));
                          return userAsync.when(
                            data: (user) => Text(user?.name ?? 'Không rõ', style: const TextStyle(fontWeight: FontWeight.w500)),
                            loading: () => const Text('Đang tải...'),
                            error: (_, __) => const Text('Lỗi'),
                          );
                        },
                      ),
                    ),
                    Text(
                      currencyFormat.format(total),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
