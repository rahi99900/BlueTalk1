import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../widgets/auth_widgets.dart';
import '../../../../shared/widgets/custom_loading_indicator.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final PageController _pageCtrl = PageController();
  int _step = 0;

  // Step 1 fields
  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  String? _usernameError;
  bool _checkingUsername = false;
  
  // Image Upload fields
  XFile? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  // Step 2 fields
  final _bioCtrl = TextEditingController();
  String _selectedGender = '';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAndNext() async {
    final name = _displayNameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _usernameError = 'Display name is required');
      return;
    }
    if (username.isEmpty) {
      setState(() => _usernameError = 'Username is required');
      return;
    }
    if (username.length < 3) {
      setState(() => _usernameError = 'Username must be at least 3 characters');
      return;
    }
    if (username.contains(' ')) {
      setState(() => _usernameError = 'No spaces allowed in username');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() => _usernameError = 'Only letters, numbers and _ allowed');
      return;
    }

    setState(() { _checkingUsername = true; _usernameError = null; });
    final available = await AuthService.instance.isUsernameAvailable(username);
    if (!mounted) return;
    setState(() => _checkingUsername = false);

    if (!available) {
      setState(() => _usernameError = 'Username "@$username" is already taken');
      return;
    }

    _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    setState(() => _step = 1);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
        _isUploadingImage = true;
      });

      String? url;
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        url = await CloudinaryService.instance.uploadImage(bytes: bytes, filename: pickedFile.name);
      } else {
        url = await CloudinaryService.instance.uploadImage(filePath: pickedFile.path);
      }

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          if (url != null) {
             _uploadedImageUrl = url;
          } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
             _selectedImage = null;
          }
        });
      }
    }
  }

  Future<void> _finish() async {
    setState(() => _isSubmitting = true);
    
    // Simulate user creation since we skipped sign up page
    if (AuthService.instance.currentUser == null) {
      await AuthService.instance.signUp(email: 'local_${DateTime.now().millisecondsSinceEpoch}@bluetalk.app', password: 'local_password_123');
    }

    await AuthService.instance.updateProfile(
      displayName: _displayNameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      gender: _selectedGender.isEmpty ? null : _selectedGender,
      avatarUrl: _uploadedImageUrl,
    );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_step == 0) {
                            context.pop();
                          } else {
                            _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            setState(() => _step = 0);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(width: 8),
                      Expanded(child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4, decoration: BoxDecoration(color: _step > 0 ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight), borderRadius: BorderRadius.circular(2)))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _step == 0 ? 'Set up your profile' : 'Tell us about yourself',
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _step == 0 ? 'Choose a name and username' : 'Optional — skip anytime',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),

            const SizedBox(height: 24),

            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildStep1(isDark), _buildStep2(isDark)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Avatar
          Center(
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight, 
                      shape: BoxShape.circle,
                      image: _uploadedImageUrl != null 
                          ? DecorationImage(image: NetworkImage(_uploadedImageUrl!), fit: BoxFit.cover)
                          : (_selectedImage != null && !kIsWeb)
                              ? DecorationImage(image: FileImage(File(_selectedImage!.path)), fit: BoxFit.cover)
                              : null,
                    ),
                    child: (_selectedImage == null) 
                        ? const Icon(Icons.person_rounded, size: 52, color: AppColors.primary)
                        : null,
                  ),
                  if (_isUploadingImage)
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                      child: const Center(child: CustomLoadingIndicator(color: Colors.white)),
                    ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.add_a_photo_rounded, size: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

          const SizedBox(height: 28),

          AuthTextField(
            controller: _displayNameCtrl,
            hintText: 'Display name (e.g. Alex Johnson)',
            icon: Icons.badge_outlined,
          ).animate(delay: 50.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 14),

          // Username with check
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameCtrl,
                onChanged: (_) {
                  if (_usernameError != null) setState(() => _usernameError = null);
                },
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.alternate_email_rounded,
                      color: AppColors.textSecondaryLight, size: 20),
                  hintText: 'Username (e.g. alex_gamer)',
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  suffixIcon: _checkingUsername
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CustomLoadingIndicator(color: AppColors.primary),
                        )
                      : null,
                ),
              ),
              if (_usernameError != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_usernameError!,
                        style: GoogleFonts.inter(color: AppColors.errorRed, fontSize: 12))),
                  ],
                ),
              ],
            ],
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _checkingUsername ? null : _checkUsernameAndNext,
            child: _checkingUsername
                ? const SizedBox(width: 20, height: 20,
                    child: CustomLoadingIndicator(color: Colors.white))
                : Text('Continue', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isDark) {
    final genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            maxLength: 150,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 42),
                child: Icon(Icons.edit_note_rounded, color: AppColors.textSecondaryLight, size: 20),
              ),
              hintText: 'Write a short bio... (optional)',
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          Text('Gender (optional)',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryLight, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: genders.map((g) {
              final selected = _selectedGender == g;
              return GestureDetector(
                onTap: () => setState(() => _selectedGender = selected ? '' : g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(g, style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : (isDark ? Colors.white : AppColors.textPrimaryLight),
                  )),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 36),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _finish,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20,
                    child: CustomLoadingIndicator(color: Colors.white))
                : Text('Start BlueTalk 🎮',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
          ),

          const SizedBox(height: 16),
          TextButton(
            onPressed: _isSubmitting ? null : _finish,
            child: Center(child: Text('Skip for now',
                style: GoogleFonts.inter(color: AppColors.textSecondaryLight, fontSize: 13, fontWeight: FontWeight.w600))),
          ),
        ],
      ),
    );
  }
}
