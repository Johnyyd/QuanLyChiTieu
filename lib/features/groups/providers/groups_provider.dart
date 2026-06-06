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
    final allGroups = snapshot.docs.map((doc) => AppGroup.fromMap(doc.data(), doc.id)).toList();
    // Lọc ra các nhóm KHÔNG phải nhóm cá nhân
    return allGroups.where((g) => !g.isPersonal).toList();
  });
});

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService(FirebaseFirestore.instance);
});

class GroupService {
  final FirebaseFirestore _firestore;

  GroupService(this._firestore);

  Future<void> createGroup(String name, String userId, {double? budget}) async {
    final docRef = _firestore.collection('groups').doc();
    final group = AppGroup(
      id: docRef.id,
      name: name,
      members: [userId],
      createdAt: DateTime.now(),
      createdBy: userId,
      budget: budget,
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

  Future<void> leaveGroup(String groupId, String userId) async {
    final docRef = _firestore.collection('groups').doc(groupId);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      throw Exception('Không tìm thấy nhóm với ID này.');
    }

    final groupData = docSnap.data()!;
    List<String> members = List<String>.from(groupData['members'] ?? []);
    
    if (members.contains(userId)) {
      members.remove(userId);
      if (members.isEmpty) {
        // Xóa nhóm nếu không còn thành viên nào
        await docRef.delete();
      } else {
        await docRef.update({'members': members});
      }
    }
  }

  Future<AppGroup> getOrCreatePersonalGroup(String userId) async {
    final snapshot = await _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .where('isPersonal', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return AppGroup.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    }

    // Tạo ví cá nhân nếu chưa có
    final docRef = _firestore.collection('groups').doc();
    final group = AppGroup(
      id: docRef.id,
      name: 'Ví Cá Nhân',
      members: [userId],
      createdAt: DateTime.now(),
      createdBy: userId,
      isPersonal: true,
    );

    await docRef.set(group.toMap());
    return group;
  }
}
