import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String category;
  final String paidBy;
  final DateTime date;

  Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.category,
    required this.paidBy,
    required this.date,
  });

  factory Expense.fromMap(Map<String, dynamic> data, String documentId) {
    return Expense(
      id: documentId,
      groupId: data['groupId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'Khác',
      paidBy: data['paidBy'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'category': category,
      'paidBy': paidBy,
      'date': Timestamp.fromDate(date),
    };
  }
}
