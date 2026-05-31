import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  final String uid;
  final String email;
  final String name;

  UserProfile({required this.uid, required this.email, required this.name});

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Không rõ',
    );
  }
}

final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, uid) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (doc.exists) {
    return UserProfile.fromMap(doc.data()!, doc.id);
  }
  return null;
});
