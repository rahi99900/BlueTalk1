import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import './notification_service.dart';

final authUserProvider = StreamProvider<UserModel?>((ref) async* {
  yield AuthService.instance.currentUser;
  yield* AuthService.instance.userStream;
});

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Web Client ID from Firebase Console > Authentication > Sign-in method > Google
  final String _webClientId = '276991854191-vf4nrp04i8clc2aajihvco7sll7t4ntb.apps.googleusercontent.com';

  UserModel? _currentUser;
  final _userController = StreamController<UserModel?>.broadcast();
  
  UserModel? get currentUser => _currentUser;
  Stream<UserModel?> get userStream => _userController.stream;
  bool get isLoggedIn => _auth.currentUser != null;

  // Listen to auth state changes to keep our internal user state updated
  void initialize() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _fetchUserProfile(user.uid);
      } else {
        _currentUser = null;
        _userController.add(null);
      }
    });
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson(doc.data()!);
      } else {
        // Fallback user if record doesn't exist yet
        _currentUser = UserModel(
          id: uid, 
          email: _auth.currentUser!.email ?? '',
        );
      }
      _userController.add(_currentUser);
      await setOnlineStatus(true);
      await NotificationService.instance.initialize();
    } catch (_) {}
  }

  Future<void> refreshUser() async {
    if (_auth.currentUser != null) {
      await _fetchUserProfile(_auth.currentUser!.uid);
    }
  }

  Future<AuthResult> signUp({required String email, required String password}) async {
    try {
      final res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (res.user != null) {
        await _fetchUserProfile(res.user!.uid);
        final u = _currentUser ?? UserModel(id: res.user!.uid, email: email);
        return AuthResult.success(u);
      }
      return AuthResult.error('Failed to create account.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(e.message ?? 'Authentication error');
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (res.user != null) {
        await _fetchUserProfile(res.user!.uid);
        return AuthResult.success(_currentUser ?? UserModel(id: res.user!.uid, email: email));
      }
      return AuthResult.error('Failed to sign in.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(e.message ?? 'Authentication error');
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        final res = await _auth.signInWithPopup(authProvider);

        if (res.user != null) {
          await _fetchUserProfile(res.user!.uid);
          
          if (_currentUser == null || _currentUser!.displayName == null) {
            final newUser = UserModel(
              id: res.user!.uid,
              email: res.user!.email ?? '',
              displayName: res.user!.displayName,
              avatarUrl: res.user!.photoURL,
              isProfileComplete: false,
            );
            await _upsertUserProfile(newUser);
          }
          return AuthResult.success(_currentUser!);
        }
        return AuthResult.error('Failed to authenticate via Web OAuth.');
      } else {
        // Native Android/iOS Flow using google_sign_in
        final googleSignIn = GoogleSignIn(
          serverClientId: _webClientId,
          scopes: ['email', 'profile'],
        );
        
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return AuthResult.error('Sign in aborted by user.');
        
        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (idToken == null && accessToken == null) {
          return AuthResult.error('No ID Token or Access Token found. Please check Google Console configuration.');
        }

        final credential = GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: accessToken,
        );

        final res = await _auth.signInWithCredential(credential);
        
        if (res.user != null) {
          await _fetchUserProfile(res.user!.uid);
          
          if (_currentUser == null || _currentUser!.displayName == null) {
            final newUser = UserModel(
              id: res.user!.uid,
              email: res.user!.email ?? '',
              displayName: googleUser.displayName,
              avatarUrl: googleUser.photoUrl,
              isProfileComplete: false,
            );
            await _upsertUserProfile(newUser);
          }
          
          return AuthResult.success(_currentUser!);
        }
        return AuthResult.error('Failed to authenticate with Firebase.');
      }
    } catch (e) {
      return AuthResult.error('Google Sign-In failed: $e');
    }
  }

  Future<AuthResult> linkGoogleAccount() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        await _auth.currentUser?.linkWithPopup(authProvider);
        return AuthResult.success(_currentUser!);
      } else {
        // Native linking
        final googleSignIn = GoogleSignIn(
          serverClientId: _webClientId,
          scopes: ['email', 'profile'],
        );
        
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return AuthResult.error('Linking aborted by user.');
        
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );

        try {
           await _auth.currentUser?.linkWithCredential(credential);
           return AuthResult.success(_currentUser!);
        } on FirebaseAuthException catch (e) {
           if (e.code == 'credential-already-in-use') {
             return AuthResult.error('This Google account is already linked to another user.');
           }
           return AuthResult.error(e.message ?? 'Linking failed.');
        } catch (e) {
           return AuthResult.error(e.toString());
        }
      }
    } catch (e) {
       return AuthResult.error(e.toString());
    }
  }

  Future<void> _upsertUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson(), SetOptions(merge: true));
      _currentUser = user;
      _userController.add(user);
    } catch (_) {}
  }

  Future<void> setOnlineStatus(bool isOnline) async {
    if (_currentUser == null) return;
    if (_currentUser!.isOnline == isOnline) return;
    try {
      await _firestore.collection('users').doc(_currentUser!.id).update({'is_online': isOnline});
      _currentUser = _currentUser!.copyWith(isOnline: isOnline);
      _userController.add(_currentUser);
    } catch (_) {}
  }

  Future<void> updateProfile({
    required String displayName,
    required String username,
    String? bio,
    String? gender,
    DateTime? dob,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;
    
    final updated = _currentUser!.copyWith(
      displayName: displayName,
      username: username,
      bio: bio,
      gender: gender,
      dob: dob,
      isProfileComplete: true,
      avatarUrl: avatarUrl,
    );
    
    await _upsertUserProfile(updated);
    _currentUser = updated;
    _userController.add(_currentUser);
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final res = await _firestore.collection('users').where('username', isEqualTo: username).limit(1).get();
      return res.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking username: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await setOnlineStatus(false);
    await _auth.signOut();
    final googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }
    _currentUser = null;
    _userController.add(null);
  }
}

class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserModel? user;

  const AuthResult._({required this.success, this.errorMessage, this.user});

  factory AuthResult.success(UserModel user) => AuthResult._(success: true, user: user);
  factory AuthResult.error(String message) => AuthResult._(success: false, errorMessage: message);
}
