import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../../../core/services/widget_service.dart';

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
    
    // Update Widget
    await _updateWidgetForGroup(expense.groupId);
  }

  Future<void> updateExpense(Expense expense) async {
    final docRef = _firestore
        .collection('groups')
        .doc(expense.groupId)
        .collection('expenses')
        .doc(expense.id);
        
    await docRef.update(expense.toMap());
    
    // Update Widget
    await _updateWidgetForGroup(expense.groupId);
  }

  Future<void> deleteExpense(String groupId, String expenseId) async {
    final docRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(expenseId);
        
    await docRef.delete();
    
    // Update Widget
    await _updateWidgetForGroup(groupId);
  }

  Future<void> _updateWidgetForGroup(String groupId) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return;
      
      final members = List<String>.from(groupDoc.data()?['members'] ?? []);
      if (members.isNotEmpty) {
        await WidgetService.updateWidgetFromUid(members.first);
      }
    } catch (e) {
      // Ignore widget update errors
    }
  }
}
