import 'package:cloud_firestore/cloud_firestore.dart';

enum Frequency { daily, weekly, monthly, yearly }

class RecurringExpense {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String category;
  final String paidBy;
  final Frequency frequency;
  final DateTime nextRunDate;
  final bool isActive;

  RecurringExpense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.category,
    required this.paidBy,
    required this.frequency,
    required this.nextRunDate,
    this.isActive = true,
  });

  RecurringExpense copyWith({
    String? id,
    String? groupId,
    String? description,
    double? amount,
    String? category,
    String? paidBy,
    Frequency? frequency,
    DateTime? nextRunDate,
    bool? isActive,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paidBy: paidBy ?? this.paidBy,
      frequency: frequency ?? this.frequency,
      nextRunDate: nextRunDate ?? this.nextRunDate,
      isActive: isActive ?? this.isActive,
    );
  }

  factory RecurringExpense.fromMap(Map<String, dynamic> data, String documentId) {
    return RecurringExpense(
      id: documentId,
      groupId: data['groupId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'Khác',
      paidBy: data['paidBy'] ?? '',
      frequency: Frequency.values.firstWhere((e) => e.toString() == 'Frequency.${data['frequency']}', orElse: () => Frequency.monthly),
      nextRunDate: data['nextRunDate'] != null ? (data['nextRunDate'] as Timestamp).toDate() : DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'category': category,
      'paidBy': paidBy,
      'frequency': frequency.toString().split('.').last,
      'nextRunDate': Timestamp.fromDate(nextRunDate),
      'isActive': isActive,
    };
  }
}
