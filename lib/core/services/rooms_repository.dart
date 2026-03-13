import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voice_room_model.dart';
import './auth_service.dart';

final roomsRepositoryProvider = Provider<RoomsRepository>((ref) {
  return RoomsRepository();
});

class RoomsRepository {
  final _firestore = FirebaseFirestore.instance;

  // Stream all voice rooms for a specific group
  Stream<List<VoiceRoomModel>> watchRoomsForGroup(String groupId) {
    return _firestore
        .collection('voice_rooms')
        .where('group_id', isEqualTo: groupId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) {
           return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return VoiceRoomModel.fromJson(data);
           }).toList();
        });
  }

  // Create a new voice room
  Future<VoiceRoomModel> createRoom({
    required String groupId,
    required String name,
    String? description,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    final ref = await _firestore.collection('voice_rooms').add({
      'group_id': groupId,
      'name': name,
      'description': description,
      'created_by': userId,
      'created_at': FieldValue.serverTimestamp(),
    });

    final doc = await ref.get();
    final data = doc.data()!;
    data['id'] = doc.id;

    return VoiceRoomModel.fromJson(data);
  }
  
  // Delete a room
  Future<void> deleteRoom(String roomId) async {
    await _firestore.collection('voice_rooms').doc(roomId).delete();
  }
}
