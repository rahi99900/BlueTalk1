
import './auth_service.dart';

class OnlineStatusService {
  OnlineStatusService._();
  static final OnlineStatusService instance = OnlineStatusService._();

  String? _currentUserId;

  void initialize() {
    // Listen to our internal Auth Stream
    AuthService.instance.userStream.listen((user) async {
      if (user != null) {
        if (_currentUserId != user.id) {
          _currentUserId = user.id;
          await AuthService.instance.setOnlineStatus(true);
        }
      } else {
        // User logged out
        _currentUserId = null;
      }
    });

    // In a full Firebase app with Realtime Database, we would use `.onDisconnect()`
    // For now, since we only set up Firestore, we rely solely on AppLifecycle bindings 
    // which are handled in main.dart.
  }

  Future<void> disconnect() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      await AuthService.instance.setOnlineStatus(false);
    }
  }

  Future<void> reconnect() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      await AuthService.instance.setOnlineStatus(true);
    }
  }
}
