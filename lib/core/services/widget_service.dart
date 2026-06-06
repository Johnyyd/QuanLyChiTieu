import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../../features/groups/models/group_model.dart';
import '../../features/expenses/models/expense_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WidgetService {
  static const String appGroupId = 'home_widget';
  static const String androidWidgetName = 'HomeWidgetProvider';

  static Future<void> updateWidget(AppGroup? group, List<Expense> expenses) async {
    if (group == null) return;

    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Tính toán lại vì group có thể chưa cập nhật kịp state, hoặc dùng luôn hàm của provider
    // Để cho an toàn, ta dùng danh sách expense
    double income = 0;
    double expenseTotal = 0;
    
    for (var exp in expenses) {
      if (exp.type == 'income') {
        income += exp.amount;
      } else if (exp.type == 'expense') {
        expenseTotal += exp.amount;
      }
    }

    final balance = income - expenseTotal;

    await HomeWidget.saveWidgetData<String>('balance', formatCurrency.format(balance));
    await HomeWidget.saveWidgetData<String>('income', formatCurrency.format(income));
    await HomeWidget.saveWidgetData<String>('expense', formatCurrency.format(expenseTotal));

    await HomeWidget.updateWidget(
      name: androidWidgetName,
      androidName: androidWidgetName,
    );
  }

  static Future<void> updateWidgetFromUid(String uid) async {
    final groupsSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: uid)
        .where('isPersonal', isEqualTo: true)
        .limit(1)
        .get();

    if (groupsSnapshot.docs.isEmpty) return;
    
    final doc = groupsSnapshot.docs.first;
    final group = AppGroup.fromMap(doc.data(), doc.id);
    
    final expensesSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(group.id)
        .collection('expenses')
        .get();
        
    final expenses = expensesSnapshot.docs
        .map((e) => Expense.fromMap(e.data(), e.id))
        .toList();
        
    await updateWidget(group, expenses);
  }
}
