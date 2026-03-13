import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import './groups_repository.dart';
import './auth_service.dart';

final userGroupsProvider = StreamProvider.autoDispose<List<GroupModel>>((ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return const Stream.empty();

  final repo = ref.watch(groupsRepositoryProvider);
  return repo.watchUserGroups();
});

final groupMemberCountProvider = StreamProvider.autoDispose.family<int, String>((ref, groupId) {
  return FirebaseFirestore.instance
      .collection('group_members')
      .where('group_id', isEqualTo: groupId)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

final groupMembersProvider = StreamProvider.autoDispose.family<List<UserModel>, String>((ref, groupId) {
  final repo = ref.watch(groupsRepositoryProvider);
  return repo.watchGroupMemberIds(groupId).asyncMap((userIds) async {
    if (userIds.isEmpty) return [];
    
    // Fetch user details for each ID
    final users = <UserModel>[];
    for (var i = 0; i < userIds.length; i += 10) {
      final chunk = userIds.sublist(i, i + 10 > userIds.length ? userIds.length : i + 10);
      final res = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      users.addAll(res.docs.map((doc) => UserModel.fromJson(doc.data())));
    }
    return users;
  });
});
