import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quanlychitieu/core/services/sql_server_helper.dart';

class UserProfile {
  final String uid;
  final String email;
  final String name;

  UserProfile({required this.uid, required this.email, required this.name});

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    // Collect all keys to see what SQL Server actually returned
    String availableKeys = data.keys.join(', ');
    
    return UserProfile(
      uid: uid,
      email: data['Email'] ?? data['email'] ?? '',
      name: data['DisplayName'] ?? data['displayName'] ?? data['name'] ?? 'Không rõ (Keys: \$availableKeys)',
    );
  }
}

final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, uid) async {
  try {
    final query = "SELECT Id, DisplayName, Email FROM Users WHERE Id = '\$uid'";
    final resultStr = await SqlServerHelper.instance.executeQuery(query);
    
    final List<dynamic> resultList = jsonDecode(resultStr);
    if (resultList.isNotEmpty) {
      final data = resultList.first as Map<String, dynamic>;
      return UserProfile.fromMap(data, uid);
    }
  } catch (e) {
    print('Lỗi khi lấy thông tin user từ SQL Server: $e');
  }
  
  // Fallback to Firestore and FirebaseAuth
  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return UserProfile(
        uid: uid,
        email: data['email'] ?? '',
        name: data['displayName'] ?? 'Chưa cập nhật tên',
      );
    }
  } catch (e) {
    print('Lỗi khi lấy thông tin user từ Firestore: $e');
  }
  
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null && currentUser.uid == uid) {
    return UserProfile(
      uid: uid,
      email: currentUser.email ?? '',
      name: currentUser.displayName ?? 'Chưa cập nhật tên',
    );
  }
  
  return null;
});
