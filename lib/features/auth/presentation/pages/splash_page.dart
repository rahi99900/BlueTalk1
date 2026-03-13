import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/services/auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../shared/widgets/custom_loading_indicator.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _hasInternet = true;
  bool _isCheckingInternet = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (!mounted) return;
    setState(() {
      _isCheckingInternet = true;
      _hasInternet = true;
    });

    // Wait for splash animation to play at least a little bit
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        setState(() {
          _hasInternet = false;
          _isCheckingInternet = false;
        });
      }
      return;
    }

    final authService = AuthService.instance;
    
    // Quick delay just in case Firebase auth listener needs to populate currentUser
    await Future.delayed(const Duration(milliseconds: 1500));
    if (authService.isLoggedIn && authService.currentUser == null) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (authService.isLoggedIn) {
      if (mounted) {
        if (authService.currentUser?.isProfileComplete == true) {
          context.go('/home');
        } else {
          context.go('/profile-setup');
        }
      }
    } else {
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            )
                .animate()
                .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            Text(
              'BlueTalk',
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            )
                .animate(delay: 300.ms)
                .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 8),

            Text(
              'Voice for Gamers',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 1.2,
              ),
            )
                .animate(delay: 500.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 80),

            // Loading dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(delay: Duration(milliseconds: 700 + i * 150))
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 400.ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .fade(end: 0.3, duration: 400.ms)
                    .then()
                    .fade(end: 1.0, duration: 400.ms);
              }),
            ),
            
            if (!_hasInternet) ...[
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'No Internet Connection',
                      style: GoogleFonts.inter(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your network and try again.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isCheckingInternet ? null : _checkAuthStatus,
                      child: _isCheckingInternet 
                          ? const CustomLoadingIndicator(color: Colors.white, width: 30, height: 20)
                          : const Text('Retry'),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
            ]
          ],
        ),
      ),
    );
  }
}
