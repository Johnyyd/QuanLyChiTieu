import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String category;
  final String paidBy; // Người trả tiền (hoặc người trả nợ trong Settle Up)
  final String? toUserId; // Người nhận nợ (chỉ dùng cho Settle Up)
  final DateTime date;
  final String type; // 'expense' hoặc 'settlement'

  Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.category,
    required this.paidBy,
    this.toUserId,
    required this.date,
    this.type = 'expense',
  });

  factory Expense.fromMap(Map<String, dynamic> data, String documentId) {
    return Expense(
      id: documentId,
      groupId: data['groupId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'Khác',
      paidBy: data['paidBy'] ?? '',
      toUserId: data['toUserId'],
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : DateTime.now(),
      type: data['type'] ?? 'expense',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'category': category,
      'paidBy': paidBy,
      'toUserId': toUserId,
      'date': Timestamp.fromDate(date),
      'type': type,
    };
  }
}
