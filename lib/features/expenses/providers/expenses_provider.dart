import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';

final expensesProvider = StreamProvider.family<List<Expense>, String>((ref, groupId) {
  return FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('expenses')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Expense.fromMap(doc.data(), doc.id)).toList();
  });
});

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService(FirebaseFirestore.instance);
});

class ExpenseService {
  final FirebaseFirestore _firestore;

  ExpenseService(this._firestore);

  Future<void> addExpense(Expense expense) async {
    final docRef = _firestore
        .collection('groups')
        .doc(expense.groupId)
        .collection('expenses')
        .doc();

    final newExpense = Expense(
      id: docRef.id,
      groupId: expense.groupId,
      description: expense.description,
      amount: expense.amount,
      category: expense.category,
      paidBy: expense.paidBy,
      toUserId: expense.toUserId,
      date: expense.date,
      type: expense.type,
    );

    await docRef.set(newExpense.toMap());
  }
}
