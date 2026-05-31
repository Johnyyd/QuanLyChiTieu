import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../groups/models/group_model.dart';
import '../../expenses/models/expense_model.dart';

class SettlementTransaction {
  final String fromUserId;
  final String toUserId;
  final double amount;

  SettlementTransaction({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}

class SettlementService {
  final FirebaseFirestore _firestore;

  SettlementService(this._firestore);

  // Tính toán các giao dịch thanh toán
  List<SettlementTransaction> calculateSettlements(AppGroup group, List<Expense> expenses) {
    if (group.members.isEmpty || expenses.isEmpty) return [];

    // 1. Tính tổng số tiền mỗi người đã trả
    final Map<String, double> paidAmounts = {
      for (var member in group.members) member: 0.0
    };

    double totalExpense = 0;
    for (var expense in expenses) {
      if (paidAmounts.containsKey(expense.paidBy)) {
        paidAmounts[expense.paidBy] = paidAmounts[expense.paidBy]! + expense.amount;
        totalExpense += expense.amount;
      }
    }

    // 2. Tính số tiền trung bình mỗi người phải trả
    final double averageExpense = totalExpense / group.members.length;

    // 3. Tính số dư của mỗi người (Số tiền đã trả - Số tiền phải trả)
    // Nếu dương: Người này nhận lại tiền
    // Nếu âm: Người này nợ tiền
    final Map<String, double> balances = {};
    for (var entry in paidAmounts.entries) {
      balances[entry.key] = entry.value - averageExpense;
    }

    // 4. Chia ra danh sách người nợ (debtors) và người cho nợ (creditors)
    final creditors = balances.entries.where((e) => e.value > 0.01).toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sắp xếp giảm dần
    final debtors = balances.entries.where((e) => e.value < -0.01).toList()
      ..sort((a, b) => a.value.compareTo(b.value)); // Sắp xếp tăng dần (số âm nhiều nhất lên đầu)

    final List<SettlementTransaction> transactions = [];
    int i = 0; // index cho debtors
    int j = 0; // index cho creditors

    // 5. Thuật toán Greedy để tối giản số lượng giao dịch
    while (i < debtors.length && j < creditors.length) {
      final debtorId = debtors[i].key;
      final debtorAmount = -debtors[i].value;

      final creditorId = creditors[j].key;
      final creditorAmount = creditors[j].value;

      final minAmount = debtorAmount < creditorAmount ? debtorAmount : creditorAmount;

      transactions.add(SettlementTransaction(
        fromUserId: debtorId,
        toUserId: creditorId,
        amount: minAmount,
      ));

      // Cập nhật số dư
      debtors[i] = MapEntry(debtorId, -(debtorAmount - minAmount));
      creditors[j] = MapEntry(creditorId, creditorAmount - minAmount);

      // Nếu debtor đã trả hết nợ, chuyển sang debtor tiếp theo
      if (-debtors[i].value < 0.01) i++;
      // Nếu creditor đã nhận đủ tiền, chuyển sang creditor tiếp theo
      if (creditors[j].value < 0.01) j++;
    }

    return transactions;
  }
}

final settlementServiceProvider = Provider<SettlementService>((ref) {
  return SettlementService(FirebaseFirestore.instance);
});
