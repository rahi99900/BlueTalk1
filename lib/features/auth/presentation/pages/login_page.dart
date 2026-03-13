import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../shared/utils/custom_snackbar.dart';
import '../../../../../../shared/widgets/custom_loading_indicator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  void _socialLogin(String provider) async {
    if (provider != 'Google') {
      CustomSnackbar.show(context, message: '$provider login is not implemented yet.', type: SnackbarType.info);
      return;
    }
    
    setState(() => _isLoading = true);
    
    final result = await AuthService.instance.signInWithGoogle();
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (result.success && result.user != null) {
      if (result.user!.isProfileComplete) {
        context.go('/home');
      } else {
        context.go('/profile-setup');
      }
    } else {
      CustomSnackbar.show(
        context, 
        message: result.errorMessage ?? 'Authentication failed', 
        type: SnackbarType.error
      );
    }
  }

  void _createAccount() {
    context.go('/profile-setup');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),

              // ── Logo ──
              Column(
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 20),
                  Text('BlueTalk',
                      style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800,
                          color: AppColors.primary, letterSpacing: -0.5),
                  ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

                  const SizedBox(height: 8),
                  Text('Level up your voice chat 🎮',
                      style: GoogleFonts.inter(fontSize: 15,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
                ],
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.1),

              // ── Loading indicator ──
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: CustomLoadingIndicator(color: AppColors.primary),
                  ),
                ),

              // ── Login Buttons ──
              _LoginButton(
                iconWidget: Image.asset('assets/images/google_logo.png', width: 24, height: 24),
                label: 'Continue with Google',
                bgColor: isDark ? AppColors.surfaceDark : Colors.white,
                textColor: isDark ? Colors.white : AppColors.textPrimaryLight,
                borderColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                onTap: () => _socialLogin('Google'),
              ).animate(delay: 300.ms).fadeIn(duration: 350.ms).slideY(begin: 0.15),



              const SizedBox(height: 24),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            letterSpacing: 1)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ).animate(delay: 400.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: 24),

              _LoginButton(
                icon: Icons.person_add_rounded,
                label: 'Create BlueTalk Account',
                bgColor: AppColors.primary,
                textColor: Colors.white,
                borderColor: AppColors.primary,
                iconColor: Colors.white,
                onTap: _createAccount,
                isPrimary: true,
              ).animate(delay: 450.ms).fadeIn(duration: 350.ms).slideY(begin: 0.15),

              const SizedBox(height: 32),
              
              Text('By continuing, you agree to our Terms of Service & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight),
              ).animate(delay: 500.ms).fadeIn(duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool isPrimary;

  const _LoginButton({
    this.icon, this.iconWidget, required this.label, required this.bgColor,
    required this.textColor, required this.borderColor, this.iconColor,
    required this.onTap, this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: isPrimary
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null) iconWidget!
            else if (icon != null) Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: textColor)),
          ],
        ),
      ),
    );
  }
}
