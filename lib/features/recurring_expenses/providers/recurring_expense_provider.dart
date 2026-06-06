import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recurring_expense_model.dart';
import '../../expenses/models/expense_model.dart';

final recurringExpenseServiceProvider = Provider<RecurringExpenseService>((ref) {
  return RecurringExpenseService(FirebaseFirestore.instance);
});

final recurringExpensesProvider = StreamProvider.family<List<RecurringExpense>, String>((ref, groupId) {
  final service = ref.watch(recurringExpenseServiceProvider);
  return service.getRecurringExpenses(groupId);
});

class RecurringExpenseService {
  final FirebaseFirestore _firestore;

  RecurringExpenseService(this._firestore);

  Stream<List<RecurringExpense>> getRecurringExpenses(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('recurring_expenses')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecurringExpense.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addRecurringExpense(RecurringExpense expense) async {
    await _firestore
        .collection('groups')
        .doc(expense.groupId)
        .collection('recurring_expenses')
        .add(expense.toMap());
  }

  Future<void> updateRecurringExpense(RecurringExpense expense) async {
    await _firestore
        .collection('groups')
        .doc(expense.groupId)
        .collection('recurring_expenses')
        .doc(expense.id)
        .update(expense.toMap());
  }

  Future<void> deleteRecurringExpense(String groupId, String expenseId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('recurring_expenses')
        .doc(expenseId)
        .delete();
  }

  /// Khởi chạy kiểm tra các giao dịch định kỳ đến hạn
  Future<void> checkAndProcessRecurringExpenses(String groupId) async {
    final snapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('recurring_expenses')
        .where('isActive', isEqualTo: true)
        .get();

    final now = DateTime.now();

    for (var doc in snapshot.docs) {
      final recurring = RecurringExpense.fromMap(doc.data(), doc.id);
      
      // Nếu đã đến hạn hoặc quá hạn
      if (recurring.nextRunDate.isBefore(now) || recurring.nextRunDate.isAtSameMomentAs(now)) {
        // 1. Tạo Expense mới
        final newExpense = Expense(
          id: '',
          groupId: recurring.groupId,
          description: recurring.description,
          amount: recurring.amount,
          category: recurring.category,
          paidBy: recurring.paidBy,
          date: recurring.nextRunDate,
          isConfirmed: true, // Tự động duyệt
        );

        await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('expenses')
            .add(newExpense.toMap());

        // 2. Tính toán ngày chạy tiếp theo
        DateTime nextDate = recurring.nextRunDate;
        switch (recurring.frequency) {
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

        // Cập nhật lại bản ghi định kỳ
        await updateRecurringExpense(recurring.copyWith(nextRunDate: nextDate));
      }
    }
  }
}
