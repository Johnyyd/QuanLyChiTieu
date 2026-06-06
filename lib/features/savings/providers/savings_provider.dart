import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/savings_model.dart';

// Service Provider
final savingsServiceProvider = Provider<SavingsService>((ref) {
  return SavingsService(FirebaseFirestore.instance);
});

// Stream Provider for current user's savings goals
final savingsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  
  final service = ref.watch(savingsServiceProvider);
  return service.getSavingsGoals(user.uid);
});

class SavingsService {
  final FirebaseFirestore _firestore;

  SavingsService(this._firestore);

  Stream<List<SavingsGoal>> getSavingsGoals(String userId) {
    return _firestore
        .collection('savings_goals')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SavingsGoal.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => (a.targetDate ?? DateTime(2100)).compareTo(b.targetDate ?? DateTime(2100)));
    });
  }

  Future<String> addSavingsGoal(SavingsGoal goal) async {
    final docRef = await _firestore.collection('savings_goals').add(goal.toMap());
    return docRef.id;
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await _firestore.collection('savings_goals').doc(goal.id).update(goal.toMap());
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    await _firestore.collection('savings_goals').doc(goalId).delete();
  }

  Future<void> addFundToGoal(String goalId, double amountToAdd) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('savings_goals').doc(goalId);
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        final currentAmount = (snapshot.data()?['currentAmount'] ?? 0).toDouble();
        transaction.update(docRef, {'currentAmount': currentAmount + amountToAdd});
      }
    });
  }

  Future<void> withdrawFundFromGoal(String goalId, double amountToWithdraw) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('savings_goals').doc(goalId);
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        final currentAmount = (snapshot.data()?['currentAmount'] ?? 0).toDouble();
        final newAmount = currentAmount - amountToWithdraw;
        transaction.update(docRef, {'currentAmount': newAmount < 0 ? 0 : newAmount});
      }
    });
  }
}
