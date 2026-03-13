import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import './friends_repository.dart';
import './auth_service.dart';

final friendsProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return const Stream.empty();
  
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.watchFriends();
});

final pendingRequestsProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return const Stream.empty();
  
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.watchPendingRequests();
});

/// Derived count provider — used for red dot badge
final pendingRequestsCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(pendingRequestsProvider).maybeWhen(
    data: (list) => list.length,
    orElse: () => 0,
  );
});

final friendStatusProvider = StreamProvider.family.autoDispose<String, String>((ref, otherUserId) {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return Stream.value('none');
  
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.watchFriendStatus(otherUserId);
});

