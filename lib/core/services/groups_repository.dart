import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import './auth_service.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository();
});

class GroupsRepository {
  final _firestore = FirebaseFirestore.instance;

  // Stream all groups the current user is a member of
  Stream<List<GroupModel>> watchUserGroups() {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('group_members')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return [];

          final groupIds = snapshot.docs.map((doc) => doc.data()['group_id'] as String).toList();

          List<GroupModel> groups = [];
          for (var i = 0; i < groupIds.length; i += 10) {
            final chunk = groupIds.sublist(i, i + 10 > groupIds.length ? groupIds.length : i + 10);
            final res = await _firestore.collection('groups').where(FieldPath.documentId, whereIn: chunk).get();
            groups.addAll(res.docs.map((doc) => GroupModel.fromJson(doc.data(), id: doc.id)));
          }

          groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return groups;
        });
  }

  // Fetch all groups matching a search query (for suggesting/joining) - all groups are public
  Future<List<GroupModel>> searchGroups(String query) async {
    final res = await _firestore.collection('groups').get();
    final lowerQuery = query.toLowerCase();

    return res.docs
        .map((doc) => GroupModel.fromJson(doc.data(), id: doc.id))
        .where((group) => lowerQuery.isEmpty || group.name.toLowerCase().contains(lowerQuery))
        .take(20)
        .toList();
  }

  // Create a new group and automatically add the creator as admin
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    String? profilePicUrl,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    try {
      final groupRef = await _firestore.collection('groups').add({
        'name': name,
        'subtitle': description,
        'profile_pic_url': profilePicUrl,
        'created_by': userId,      // Track creator
        'admin_id': userId,        // Track admin (can be changed)
        'created_at': FieldValue.serverTimestamp(),
      });

      final doc = await groupRef.get();
      final group = GroupModel.fromJson(doc.data()!, id: doc.id);

      try {
        await _firestore.collection('group_members').add({
          'group_id': group.id,
          'user_id': userId,
          'role': 'admin',
        });
      } catch (e) {
        debugPrint('MEMBER ERROR: $e');
      }

      return group;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  // Update group name and/or profile picture
  Future<void> updateGroupDetails(String groupId, {String? name, String? profilePicUrl}) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // Verify caller is admin
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) throw Exception('Group not found');
    final adminId = groupDoc.data()?['admin_id'] as String?;
    final createdBy = groupDoc.data()?['created_by'] as String?;
    if (adminId != userId && createdBy != userId) {
      throw Exception('Only the group admin can edit the group.');
    }

    final updates = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) updates['name'] = name.trim();
    if (profilePicUrl != null) updates['profile_pic_url'] = profilePicUrl;

    if (updates.isNotEmpty) {
      await _firestore.collection('groups').doc(groupId).update(updates);
    }
  }

  // Check if the current user is admin of a group
  Future<bool> isCurrentUserAdmin(String groupId) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return false;

    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) return false;

    final data = groupDoc.data()!;
    return data['admin_id'] == userId || data['created_by'] == userId;
  }

  // Join an existing group
  Future<void> joinGroup(String groupId) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // Check if already a member
    final existing = await _firestore.collection('group_members')
        .where('group_id', isEqualTo: groupId)
        .where('user_id', isEqualTo: userId)
        .get();

    if (existing.docs.isEmpty) {
      await _firestore.collection('group_members').add({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
      });
    }
  }

  // Add an arbitrary user to a group (for direct friend invites)
  Future<void> addMember(String groupId, String userId) async {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) throw Exception('Not logged in');

    try {
      final existing = await _firestore.collection('group_members')
          .where('group_id', isEqualTo: groupId)
          .where('user_id', isEqualTo: userId)
          .get();

      if (existing.docs.isEmpty) {
        await _firestore.collection('group_members').add({
          'group_id': groupId,
          'user_id': userId,
          'role': 'member',
        });
      }
    } catch (e) {
      debugPrint('addMember error: $e');
    }
  }

  // Kick a member from the group (Admin only)
  Future<void> kickMember(String groupId, String userIdToKick) async {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) throw Exception('Not logged in');

    // 1. Verify caller is admin
    final isAdmin = await isCurrentUserAdmin(groupId);
    if (!isAdmin) throw Exception('Only the group admin can kick members.');

    // 2. Cannot kick yourself
    if (currentUserId == userIdToKick) throw Exception('You cannot kick yourself.');

    // 3. Delete from group_members
    final snapshot = await _firestore.collection('group_members')
        .where('group_id', isEqualTo: groupId)
        .where('user_id', isEqualTo: userIdToKick)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Get member user IDs for a group
  Stream<List<String>> watchGroupMemberIds(String groupId) {
    return _firestore.collection('group_members')
        .where('group_id', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()['user_id'] as String).toList());
  }
}
