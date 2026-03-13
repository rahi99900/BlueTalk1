import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';

import '../../../../core/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/cloudinary_service.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/widgets/custom_loading_indicator.dart';
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  late String _selectedGender;
  late DateTime _dob;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;

  final List<String> _genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    final u = AuthService.instance.currentUser;
    _nameCtrl = TextEditingController(text: u?.displayName ?? '');
    _usernameCtrl = TextEditingController(text: u?.username ?? '');
    _bioCtrl = TextEditingController(text: u?.bio ?? '');
    _selectedGender = u?.gender ?? 'Prefer not to say';
    _dob = u?.dob ?? DateTime(2000, 1, 1);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.updateProfile(
        displayName: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        gender: _selectedGender,
        dob: _dob,
        avatarUrl: _uploadedImageUrl ?? AuthService.instance.currentUser?.avatarUrl,
      );
      if (mounted) {
        // Also update auth user provider locally so UI updates immediately
        AuthService.instance.refreshUser();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
                  Expanded(
                    child: Text('Edit Profile', textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CustomLoadingIndicator(color: AppColors.primary))
                        : Text('Save', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: GestureDetector(
                        onTap: _isUploadingImage ? null : () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (pickedFile != null) {
                            setState(() => _isUploadingImage = true);
                            String? url;
                            try {
                              if (kIsWeb) {
                                final bytes = await pickedFile.readAsBytes();
                                url = await CloudinaryService.instance.uploadImage(bytes: bytes, filename: pickedFile.name);
                              } else {
                                url = await CloudinaryService.instance.uploadImage(filePath: pickedFile.path);
                              }
                              if (url != null) {
                                if (mounted) setState(() => _uploadedImageUrl = url);
                              } else {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
                              }
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading: $e')));
                            } finally {
                              if (mounted) setState(() => _isUploadingImage = false);
                            }
                          }
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryLight,
                                image: _uploadedImageUrl != null 
                                    ? DecorationImage(image: NetworkImage(_uploadedImageUrl!), fit: BoxFit.cover)
                                    : (AuthService.instance.currentUser?.avatarUrl != null 
                                       ? DecorationImage(image: NetworkImage(AuthService.instance.currentUser!.avatarUrl!), fit: BoxFit.cover)
                                       : null),
                                gradient: (_uploadedImageUrl == null && AuthService.instance.currentUser?.avatarUrl == null) ? LinearGradient(
                                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ) : null,
                              ),
                              child: (_uploadedImageUrl == null && AuthService.instance.currentUser?.avatarUrl == null) ? Center(
                                child: Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                              ) : null,
                            ),
                            if (_isUploadingImage)
                              Container(
                                width: 96, height: 96,
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                                child: const Center(child: CustomLoadingIndicator(color: Colors.white)),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    const _FieldLabel('Display Name'),
                    const SizedBox(height: 8),
                    _StyledTextField(controller: _nameCtrl, icon: Icons.badge_outlined, hint: 'Display name'),

                    const SizedBox(height: 16),
                    const _FieldLabel('Username'),
                    const SizedBox(height: 8),
                    _StyledTextField(controller: _usernameCtrl, icon: Icons.alternate_email_rounded, hint: 'username'),

                    const SizedBox(height: 16),
                    const _FieldLabel('Bio'),
                    const SizedBox(height: 8),
                    _StyledTextField(controller: _bioCtrl, icon: Icons.edit_note_rounded, hint: 'Write a short bio...', maxLines: 3),

                    const SizedBox(height: 16),
                    const _FieldLabel('Gender'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _genders.map((g) {
                        final isSelected = _selectedGender == g;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGender = g),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderLight),
                            ),
                            child: Text(
                              g,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.textPrimaryLight),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    const _FieldLabel('Date of Birth'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dob,
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                            child: child!,
                          ),
                        );
                        if (picked != null) setState(() => _dob = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake_rounded, size: 20, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 12),
                            Text(
                              '${_dob.day}/${_dob.month}/${_dob.year}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CustomLoadingIndicator(color: Colors.white))
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondaryLight, letterSpacing: 0.5),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _StyledTextField({required this.controller, required this.hint, required this.icon, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: AppColors.textSecondaryLight),
        ),
        hintText: hint,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
