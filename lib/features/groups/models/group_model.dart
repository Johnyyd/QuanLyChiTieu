import 'package:cloud_firestore/cloud_firestore.dart';

class AppGroup {
  final String id;
  final String name;
  final List<String> members;
  final DateTime createdAt;
  final String createdBy;

  AppGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
    required this.createdBy,
  });

  factory AppGroup.fromMap(Map<String, dynamic> data, String documentId) {
    return AppGroup(
      id: documentId,
      name: data['name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}
