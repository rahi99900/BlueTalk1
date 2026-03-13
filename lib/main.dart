import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/online_status_service.dart';
import 'core/services/connectivity_provider.dart';
import 'shared/widgets/offline_overlay.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Request permission for iOS/Android 13+
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  

  
  AuthService.instance.initialize();
  OnlineStatusService.instance.initialize();
  
  runApp(const ProviderScope(child: BlueTalkApp()));
}

class BlueTalkApp extends ConsumerStatefulWidget {
  const BlueTalkApp({super.key});

  @override
  ConsumerState<BlueTalkApp> createState() => _BlueTalkAppState();
}

class _BlueTalkAppState extends ConsumerState<BlueTalkApp> with WidgetsBindingObserver {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    
    // Handle link when app is in warm state (front or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
    
    // Handle link when app is in cold state (terminated)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        // slight delay to let router & auth initialize
        Future.delayed(const Duration(milliseconds: 1500), () {
          _handleDeepLink(initialUri);
        });
      }
    } catch (_) {}
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'bluetalk') {
      if (uri.host == 'group' && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'join') {
        if (uri.pathSegments.length > 1) {
          final groupId = uri.pathSegments[1];
          appRouter.push('/join-group-preview/$groupId');
        }
      } else if (uri.host == 'user' && uri.pathSegments.isNotEmpty) {
        // Navigation logic for visiting another user's profile can go here when ready
        // final userId = uri.pathSegments.first;
        // appRouter.push('/user/$userId');
      }
    } else if (uri.scheme == 'https' && uri.host == 'invite.bluetalk.site') {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'i') {
        if (uri.pathSegments.length > 1) {
          final groupId = uri.pathSegments[1];
          appRouter.push('/join-group-preview/$groupId');
        }
      }
    }
  }
  
  @override
  void dispose() {
    _linkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground
      OnlineStatusService.instance.reconnect();
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.detached || 
               state == AppLifecycleState.inactive || 
               state == AppLifecycleState.hidden) {
      // App went to background or is closing
      OnlineStatusService.instance.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    
    return MaterialApp.router(
      title: 'BlueTalk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) {
            final isOnline = ref.watch(connectivityProvider).value ?? true;
            return Stack(
              children: [
                if (child != null) child,
                if (!isOnline) const Positioned.fill(child: OfflineOverlay()),
              ],
            );
          },
        );
      },
    );
  }
}

