import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../groups/models/group_model.dart';
import '../../groups/providers/groups_provider.dart';

final personalGroupFutureProvider = FutureProvider<AppGroup?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  final groupService = ref.read(groupServiceProvider);
  return await groupService.getOrCreatePersonalGroup(user.uid);
});
