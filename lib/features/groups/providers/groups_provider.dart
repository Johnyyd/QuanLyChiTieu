import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/group_model.dart';

final groupsProvider = StreamProvider<List<AppGroup>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('groups')
      .where('members', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => AppGroup.fromMap(doc.data(), doc.id)).toList();
  });
});

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService(FirebaseFirestore.instance);
});

class GroupService {
  final FirebaseFirestore _firestore;

  GroupService(this._firestore);

  Future<void> createGroup(String name, String userId) async {
    final docRef = _firestore.collection('groups').doc();
    final group = AppGroup(
      id: docRef.id,
      name: name,
      members: [userId],
      createdAt: DateTime.now(),
      createdBy: userId,
    );

    await docRef.set(group.toMap());
  }

  Future<void> joinGroup(String groupId, String userId) async {
    final docRef = _firestore.collection('groups').doc(groupId);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      throw Exception('Không tìm thấy nhóm với ID này.');
    }

    final groupData = docSnap.data()!;
    List<String> members = List<String>.from(groupData['members'] ?? []);
    
    if (members.contains(userId)) {
      throw Exception('Bạn đã là thành viên của nhóm này.');
    }

    members.add(userId);
    await docRef.update({'members': members});
  }
}
