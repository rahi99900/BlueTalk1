import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voice_room_model.dart';
import './rooms_repository.dart';

// Provide a way to get streams of rooms per group ID
final roomsProvider = StreamProvider.family<List<VoiceRoomModel>, String>((ref, groupId) {
  final repo = ref.watch(roomsRepositoryProvider);
  return repo.watchRoomsForGroup(groupId);
});
