import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String groupId;
  final String description;
  final double amount; // Số tiền thực tế (VND)
  final String category;
  final String paidBy; // Người trả tiền (hoặc người trả nợ trong Settle Up)
  final String? toUserId; // Người nhận nợ (chỉ dùng cho Settle Up)
  final DateTime date;
  final String type; // 'expense' hoặc 'settlement'
  final bool isConfirmed;
  
  // Đa tiền tệ
  final String currency; // 'VND', 'USD', 'EUR', 'JPY'...
  final double? originalAmount; // Số tiền nguyên tệ
  final double exchangeRate; // Tỉ giá so với VND

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
    this.isConfirmed = true,
    this.currency = 'VND',
    this.originalAmount,
    this.exchangeRate = 1.0,
  });

  Expense copyWith({
    String? id,
    String? groupId,
    String? description,
    double? amount,
    String? category,
    String? paidBy,
    String? toUserId,
    DateTime? date,
    String? type,
    bool? isConfirmed,
    String? currency,
    double? originalAmount,
    double? exchangeRate,
  }) {
    return Expense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paidBy: paidBy ?? this.paidBy,
      toUserId: toUserId ?? this.toUserId,
      date: date ?? this.date,
      type: type ?? this.type,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      currency: currency ?? this.currency,
      originalAmount: originalAmount ?? this.originalAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
    );
  }

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
      isConfirmed: data['isConfirmed'] ?? true,
      currency: data['currency'] ?? 'VND',
      originalAmount: data['originalAmount'] != null ? (data['originalAmount']).toDouble() : null,
      exchangeRate: data['exchangeRate'] != null ? (data['exchangeRate']).toDouble() : 1.0,
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
      'isConfirmed': isConfirmed,
      'currency': currency,
      'originalAmount': originalAmount,
      'exchangeRate': exchangeRate,
    };
  }
}
