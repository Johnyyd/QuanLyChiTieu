import 'package:cloud_firestore/cloud_firestore.dart';

class AppGroup {
  final String id;
  final String name;
  final List<String> members;
  final DateTime createdAt;
  final String createdBy;
  final double? budget;
  final bool isPersonal;

  AppGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
    required this.createdBy,
    this.budget,
    this.isPersonal = false,
  });

  factory AppGroup.fromMap(Map<String, dynamic> data, String documentId) {
    return AppGroup(
      id: documentId,
      name: data['name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      budget: data['budget'] != null ? (data['budget'] as num).toDouble() : null,
      isPersonal: data['isPersonal'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      if (budget != null) 'budget': budget,
      'isPersonal': isPersonal,
    };
  }
}
