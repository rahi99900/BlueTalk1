import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import './auth_service.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository();
});

class FriendsRepository {
  final _firestore = FirebaseFirestore.instance;

  // Search users by username or display_name
  Future<List<UserModel>> searchUsers(String query) async {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null || query.isEmpty) return [];

    // Firestore doesn't have a direct 'ilike' equivalent or generic text search on multiple fields.
    // For a simple adaptation, we'll fetch users and filter client-side, or use array-contains if available.
    // Given the constraints of Firestore, client-side filtering after a simple query is easiest if db is small.
    // A better approach in prod is using Algolia or Typesense.
    final res = await _firestore.collection('users').get();
    
    final allUsers = res.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .where((user) => user.id != currentUserId)
        .toList();

    final lowerQuery = query.toLowerCase();
    final matchedUsers = allUsers.where((user) {
      final matchUsername = user.username?.toLowerCase().contains(lowerQuery) ?? false;
      final matchDisplayName = user.displayName?.toLowerCase().contains(lowerQuery) ?? false;
      return matchUsername || matchDisplayName;
    }).take(20).toList();

    return matchedUsers;
  }

  // Get suggested users (random active users we aren't friends with yet)
  Future<List<UserModel>> getSuggestedUsers() async {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) return [];

    final res = await _firestore.collection('users').limit(10).get();
    
    return res.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .where((user) => user.id != currentUserId)
        .toList();
  }
  
  // Get user by ID
  Future<UserModel?> getUserById(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!);
  }

  /// Watches the friendship/request status with another user in realtime.
  /// Returns a stream of: 'friend', 'sent', 'received', or 'none'
  Stream<String> watchFriendStatus(String otherUserId) {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) return Stream.value('none');

    return _firestore.collection('friend_requests')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.where((doc) {
            final from = doc.data()['from_user_id'];
            final to = doc.data()['to_user_id'];
            return (from == currentUserId && to == otherUserId) || 
                   (from == otherUserId && to == currentUserId);
          }).toList();

          if (docs.isEmpty) return 'none';
          
          final doc = docs.first;
          final status = doc.data()['status'] as String;
          
          if (status == 'accepted') return 'friend';
          if (status == 'pending') {
            return doc.data()['from_user_id'] == currentUserId ? 'sent' : 'received';
          }
          return 'none';
        });
  }

  // Send a friend request (using set/merge so rejected requests can be re-sent)
  Future<void> sendFriendRequest(String toUserId) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) throw Exception('Not logged in');

    // Check if one exists to grab its ID, else create new
    final req1 = await _firestore.collection('friend_requests')
        .where('from_user_id', isEqualTo: currentUser.id)
        .where('to_user_id', isEqualTo: toUserId)
        .get();

    final req2 = await _firestore.collection('friend_requests')
        .where('from_user_id', isEqualTo: toUserId)
        .where('to_user_id', isEqualTo: currentUser.id)
        .get();

    final docs = [...req1.docs, ...req2.docs];

    final docId = docs.isEmpty ? _firestore.collection('friend_requests').doc().id : docs.first.id;

    await _firestore.collection('friend_requests').doc(docId).set({
      'from_user_id': currentUser.id,
      'to_user_id': toUserId,
      'status': 'pending',
    }, SetOptions(merge: true));

    // After successfully saving the request in Firestore, trigger the push notification
    try {
      final senderName = (currentUser.displayName?.trim().isNotEmpty == true) 
          ? currentUser.displayName 
          : currentUser.username;
          
      final uri = Uri.parse('https://apibluetalk.vercel.app/api/send-friend-request-notification'); // Set to production domain
      
      // We will perform a fire-and-forget HTTP request to avoid blocking the UI
      http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderName': senderName ?? 'Someone',
          'receiverUid': toUserId,
        }),
      ).then((response) {
        if (response.statusCode != 200) {
          debugPrint('Failed to send notification. Backend responded with: ${response.body}');
        }
      }).catchError((e) {
        debugPrint('HTTP request failed while sending push notification: $e');
      });
    } catch (e) {
      debugPrint('Failed to trigger push notification API: $e');
    }
  }

  // Reject an incoming friend request (DELETE it so it can be re-sent later)
  Future<void> rejectRequest(String fromUserId) async {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) return;
    
    final query = await _firestore.collection('friend_requests')
        .where('from_user_id', isEqualTo: fromUserId)
        .where('to_user_id', isEqualTo: currentUserId)
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // Watch pending incoming friend requests (with realtime)
  Stream<List<UserModel>> watchPendingRequests() {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) return const Stream.empty();

    return _firestore.collection('friend_requests')
        .where('to_user_id', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return [];
          
          final userIds = snapshot.docs.map((doc) => doc.data()['from_user_id'] as String).toList();
          
          // Firestore 'whereIn' limits to 10 items. Chunking if necessary.
          List<UserModel> users = [];
          for (var i = 0; i < userIds.length; i += 10) {
            final chunk = userIds.sublist(i, i + 10 > userIds.length ? userIds.length : i + 10);
            final userQuery = await _firestore.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
            users.addAll(userQuery.docs.map((d) => UserModel.fromJson(d.data())));
          }
          return users;
        });
  }

  // Watch accepted friends
  Stream<List<UserModel>> watchFriends() {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) return const Stream.empty();

    // First stream friend request relationships
    final requestsStream = _firestore.collection('friend_requests')
        .where('status', isEqualTo: 'accepted')
        .snapshots();

    // Map those relationships into live user documents using asyncMap and nested listening
    // Since Riverpod autoDispose StreamProvider handles the outer stream, using switchMap behavior is easiest via flatMap or custom broadcast.
    // For simplicity without rxdart, we can yield a merged stream of user documents, but asyncMap already works if we trigger whenever ANY tracked friend updates.
    // The issue was asyncMap only ran when the *relationship* changed, not when the *user* changed (like going online/offline).
    // Let's use a query that isn't ideal for large lists, but works well for UI:
    // Query `users` collection directly via a realtime snapshot based on active friend IDs.

    return requestsStream.asyncMap((snapshot) async {
      final requests = snapshot.docs
          .map((doc) => doc.data())
          .where((r) => r['from_user_id'] == currentUserId || r['to_user_id'] == currentUserId)
          .toList();

      if (requests.isEmpty) return <String>[];

      return requests.map((r) {
        final fromId = r['from_user_id'] as String;
        final toId = r['to_user_id'] as String;
        return fromId == currentUserId ? toId : fromId;
      }).toList();
    }).asyncExpand((friendIds) {
      if (friendIds.isEmpty) return Stream.value(<UserModel>[]);
      
      // Because Firestore whereIn is limited to 10 items, if the user has >10 friends, streaming them all natively is tricky
      // without splitting streams. For now, since it's a small scale app, we will use whereIn on the first 10.
      // A more robust app uses a cloud function to sync friend statuses to a user's local document.
      final idsToWatch = friendIds.take(10).toList(); // Firestore whereIn limit is 10

      return _firestore.collection('users')
          .where(FieldPath.documentId, whereIn: idsToWatch)
          .snapshots()
          .map((userSnap) => userSnap.docs.map((d) => UserModel.fromJson(d.data())).toList());
    });
  }

  // Accept a friend request
  Future<void> acceptRequest(String fromUserId) async {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) return;

    final query = await _firestore.collection('friend_requests')
        .where('from_user_id', isEqualTo: fromUserId)
        .where('to_user_id', isEqualTo: currentUserId)
        .get();

    for (var doc in query.docs) {
      await doc.reference.update({'status': 'accepted'});
    }
  }
}
