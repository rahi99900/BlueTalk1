import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../shared/utils/custom_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/services/cloudinary_service.dart';
import 'package:flutter/foundation.dart';
import '../../../../../../shared/widgets/custom_loading_indicator.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // Push notification toggles
  bool _notifFriendReq = true;
  bool _notifRoomEnter = true;

  @override
  void initState() {
    super.initState();
    _loadNotifSettings();
  }

  Future<void> _loadNotifSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Fallback to local initially
    bool req = prefs.getBool('notif_friend_req') ?? true;
    bool room = prefs.getBool('notif_room_enter') ?? true;

    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .get();
        if (doc.exists) {
          req = doc.data()?['notif_friend_req'] ?? req;
          prefs.setBool('notif_friend_req', req);
        }
      } catch (e) {
        debugPrint("Error loading notif settings from DB: $e");
      }
    }

    setState(() {
      _notifFriendReq = req;
      _notifRoomEnter = room;
    });
  }

  Future<void> _updateNotifSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    final user = AuthService.instance.currentUser;
    if (user != null && key == 'notif_friend_req') {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({key: value});
      } catch (e) {
        debugPrint("Error updating notif setting in DB: $e");
      }
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(builder: (ctx, setLocal) {
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2035) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 18)),
                  const SizedBox(width: 10),
                  Text('Push Notifications', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 16),

                _NotifToggle(
                  title: 'Friend Requests',
                  subtitle: 'When someone adds you',
                  value: _notifFriendReq,
                  onChanged: (v) { 
                    setLocal(() => _notifFriendReq = v); 
                    setState(() => _notifFriendReq = v);
                    _updateNotifSetting('notif_friend_req', v);
                  },
                  isDark: isDark,
                ),

                _NotifToggle(
                  title: 'Room Activity',
                  subtitle: 'When friends enter a voice room',
                  value: _notifRoomEnter,
                  onChanged: (v) { 
                    setLocal(() => _notifRoomEnter = v); 
                    setState(() => _notifRoomEnter = v);
                    _updateNotifSetting('notif_room_enter', v);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showEditProfile() {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final nameCtrl = TextEditingController(text: user.displayName);
    final bioCtrl = TextEditingController(text: user.bio);
    bool isLoading = false;
    bool isUploadingAvatar = false;
    String? uploadedAvatarUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(builder: (ctx, setLocal) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2035) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 36, height: 4,
                      decoration: BoxDecoration(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text('Edit Profile', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),

                  // Avatar Pick
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight, 
                            shape: BoxShape.circle,
                            image: (uploadedAvatarUrl != null)
                                ? DecorationImage(image: NetworkImage(uploadedAvatarUrl!), fit: BoxFit.cover)
                                : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                    ? DecorationImage(image: NetworkImage(user.avatarUrl!), fit: BoxFit.cover)
                                    : null,
                          ),
                          child: (uploadedAvatarUrl == null && (user.avatarUrl == null || user.avatarUrl!.isEmpty))
                              ? Center(child: Text(nameCtrl.text.isNotEmpty ? nameCtrl.text[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 36, fontWeight: FontWeight.w800)))
                              : null,
                        ),
                        if (isUploadingAvatar)
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                            child: const Center(child: CustomLoadingIndicator(color: Colors.white)),
                          ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: isUploadingAvatar ? null : () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                              if (pickedFile != null) {
                                setLocal(() { isUploadingAvatar = true; });
                                String? url;
                                if (kIsWeb) {
                                  final bytes = await pickedFile.readAsBytes();
                                  url = await CloudinaryService.instance.uploadImage(bytes: bytes, filename: pickedFile.name);
                                } else {
                                  url = await CloudinaryService.instance.uploadImage(filePath: pickedFile.path);
                                }
                                setLocal(() {
                                  isUploadingAvatar = false;
                                  if (url != null) {
                                    uploadedAvatarUrl = url;
                                  } else {
                                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
                                  }
                                });
                              }
                            },
                            child: Container(
                              width: 26, height: 26,
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: nameCtrl,
                    onChanged: (v) => setLocal(() {}), // Update avatar letter
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: bioCtrl,
                    maxLines: 2,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setLocal(() => isLoading = true);
                      await AuthService.instance.updateProfile(
                        displayName: nameCtrl.text.trim(),
                        username: user.username ?? '', // Keep existing
                        bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
                        avatarUrl: uploadedAvatarUrl,
                      );
                      setState(() {});
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CustomLoadingIndicator(color: Colors.white))
                        : Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  void _logout() async {
    await AuthService.instance.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Watch the live user stream to redraw the profile on edits
    final userStream = ref.watch(authUserProvider);
    
    return userStream.when(
      data: (user) {
        if (user == null) return const SizedBox();
        // The rest of the scaffold is strictly underneath

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : Colors.white,
                border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text('Profile', textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 40), // Balance the title since no logout button on right
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ── Hero section ──
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 110, height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryLight,
                              border: Border.all(color: AppColors.primary, width: 4),
                              image: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                  ? DecorationImage(image: NetworkImage(user.avatarUrl!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty) 
                              ? Center(
                                  child: Text((user.displayName ?? '').isNotEmpty ? (user.displayName ?? 'U')[0].toUpperCase() : 'U',
                                      style: const TextStyle(color: AppColors.primary, fontSize: 42, fontWeight: FontWeight.w800)),
                                ) 
                              : null,
                          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                          const SizedBox(height: 20),

                          Text(user.displayName ?? 'Gamer',
                              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight, letterSpacing: -0.3),
                          ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

                          const SizedBox(height: 4),
                          Text('@${user.username}',
                              style: GoogleFonts.inter(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

                          const SizedBox(height: 12),
                          Text(user.bio ?? 'Playing games and chatting on BlueTalk 🎮',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 13, height: 1.5,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

                          const SizedBox(height: 24),

                          ElevatedButton.icon(
                            onPressed: _showEditProfile,
                            icon: const Icon(Icons.edit_note_rounded, size: 20),
                            label: const Text('Edit Profile'),
                          ).animate(delay: 250.ms).fadeIn(duration: 300.ms),
                        ],
                      ),
                    ),
                           // ── Settings List ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('SETTINGS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                              color: AppColors.textSecondaryLight, letterSpacing: 1.2)),
                          const SizedBox(height: 16),

                          _SettingsRow(
                            icon: Icons.notifications_active_rounded,
                            iconColor: AppColors.primary,
                            title: 'Notification Settings',
                            subtitle: 'Manage push alerts',
                            isDark: isDark,
                            onTap: _showNotificationSettings,
                          ).animate(delay: 300.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // We check what providers the user is linked with
                          Builder(
                            builder: (context) {
                              final authUser = FirebaseAuth.instance.currentUser;
                              final providerData = authUser?.providerData ?? [];
                              
                              final isGoogleLinked = providerData.any((info) => info.providerId == 'google.com');
                              final googleEmail = isGoogleLinked 
                                  ? providerData.firstWhere((info) => info.providerId == 'google.com').email 
                                  : null;

                              return Column(
                                children: [
                                  if (isGoogleLinked)
                                    _SettingsRow(
                                      customIcon: Image.asset('assets/images/google_logo.png', width: 24, height: 24),
                                      iconColor: const Color(0xFFDB4437),
                                      title: 'Google Connected',
                                      subtitle: googleEmail ?? authUser?.email ?? 'Linked to Google Account',
                                      isDark: isDark,
                                      onTap: () {
                                        CustomSnackbar.show(context, message: 'Google account is already linked.');
                                      },
                                    ).animate(delay: 350.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1)
                                  else
                                    _SettingsRow(
                                      customIcon: Image.asset('assets/images/google_logo.png', width: 24, height: 24),
                                      iconColor: const Color(0xFFDB4437),
                                      title: 'Link Google Account',
                                      subtitle: 'Connect your Google account',
                                      isDark: isDark,
                                      onTap: () async {
                                        try {
                                           await authUser?.linkWithProvider(GoogleAuthProvider());
                                           if (context.mounted) {
                                              CustomSnackbar.show(context, message: 'Google account linked successfully!');
                                              setState(() {}); // Refresh to show it as linked
                                           }
                                        } catch (e) {
                                           if (context.mounted) {
                                              CustomSnackbar.show(context, message: 'Failed to link Google account', type: SnackbarType.error);
                                           }
                                        }
                                      },
                                    ).animate(delay: 350.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),
                                ],
                              );
                            }
                          ),
                          
                          const SizedBox(height: 16),

                          _SettingsRow(
                            icon: Icons.dark_mode_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            title: 'Theme & Appearance',
                            subtitle: 'Dark, Light, or System mode',
                            isDark: isDark,
                            onTap: _showThemeSettings,
                          ).animate(delay: 450.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),
                          
                          const SizedBox(height: 36),
                          
                          // Logout Button
                          ElevatedButton.icon(
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.errorRed.withValues(alpha: 0.1),
                              foregroundColor: AppColors.errorRed,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
                          ).animate(delay: 500.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    }, 
    loading: () => const Center(child: CustomLoadingIndicator(color: AppColors.primary)),
    error: (e, st) => const SizedBox(),
   );
  }

  void _showThemeSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2035) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.dark_mode_rounded, color: Color(0xFF8B5CF6), size: 18)),
                const SizedBox(width: 10),
                Text('Theme Selector', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 16),
              const _ThemeOption(mode: ThemeMode.system, label: 'System Default', icon: Icons.brightness_auto_rounded),
              const _ThemeOption(mode: ThemeMode.light, label: 'Light Mode', icon: Icons.light_mode_rounded),
              const _ThemeOption(mode: ThemeMode.dark, label: 'Dark Mode', icon: Icons.dark_mode_rounded),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends ConsumerWidget {
  final ThemeMode mode;
  final String label;
  final IconData icon;

  const _ThemeOption({required this.mode, required this.label, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeNotifierProvider);
    final isSelected = currentTheme == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        ref.read(themeModeNotifierProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondaryLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimaryLight),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingsRow({
    this.icon, this.customIcon, required this.iconColor, required this.title,
    required this.subtitle, required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: customIcon != null 
                  ? Center(child: customIcon)
                  : Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight)),
              ]),
            ),
            const Icon(Icons.keyboard_arrow_right_rounded, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _NotifToggle({required this.title, required this.subtitle, required this.value, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight)),
          ])),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
          ),
        ]),
      ),
    );
  }
}
