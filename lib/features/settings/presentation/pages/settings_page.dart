import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                color: isDark ? AppColors.backgroundDark.withValues(alpha: 0.9) : AppColors.backgroundLight.withValues(alpha: 0.9),
                border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    'Settings',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  // Profile quick view
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  border: Border.all(color: AppColors.primary, width: 2),
                                ),
                                child: const Center(
                                  child: Text('AG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.onlineGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isDark ? AppColors.backgroundDark : Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Alex_Gamer99', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
                                Text('#BT-9421', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/edit-profile'),
                            child: Text('Edit', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: 50.ms).fadeIn(duration: 300.ms),

                  // Account section
                  const _SectionHeader(title: 'ACCOUNT'),
                  _SettingsGroup(
                    isDark: isDark,
                    items: [
                      _SettingsTile(icon: Icons.person_outline_rounded, iconColor: AppColors.primary, label: 'Account Settings', onTap: () {}),
                      _SettingsTile(icon: Icons.notifications_outlined, iconColor: AppColors.primary, label: 'Notification Settings', onTap: () {}),
                      _SettingsTile(icon: Icons.shield_outlined, iconColor: AppColors.primary, label: 'Privacy Settings', onTap: () {}),
                      _SettingsTile(icon: Icons.block_rounded, iconColor: AppColors.primary, label: 'Blocked Users', onTap: () {}),
                    ],
                  ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

                  const SizedBox(height: 24),

                  // Connections section
                  const _SectionHeader(title: 'CONNECTIONS'),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      border: Border(
                        top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                    child: Column(
                      children: [
                        _ConnectionTile(
                          icon: Icons.g_mobiledata_rounded,
                          label: 'Google',
                          subtitle: 'Connect to sync contacts',
                          isConnected: false,
                          isDark: isDark,
                        ),
                        Divider(height: 0, color: isDark ? AppColors.borderDark : AppColors.dividerLight),
                        _ConnectionTile(
                          icon: Icons.facebook_rounded,
                          label: 'Facebook',
                          subtitle: 'Find gaming buddies',
                          isConnected: true,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

                  const SizedBox(height: 24),

                  // Pro card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.graphic_eq_rounded, color: AppColors.primary, size: 32),
                          const SizedBox(height: 8),
                          Text('BlueTalk Pro', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight)),
                          const SizedBox(height: 4),
                          Text('Get custom avatars and premium voice filters.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Upgrade Now'),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

                  const SizedBox(height: 24),

                  // Sign out
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.3)),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ).animate(delay: 250.ms).fadeIn(duration: 300.ms),

                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'BlueTalk v1.0.0',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondaryLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsTile> items;
  final bool isDark;
  const _SettingsGroup({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        children: items
            .asMap()
            .entries
            .map((e) => Column(children: [
                  e.value,
                  if (e.key < items.length - 1)
                    Divider(height: 0, color: isDark ? AppColors.borderDark : AppColors.dividerLight, indent: 64),
                ]))
            .toList(),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 15),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isConnected;
  final bool isDark;

  const _ConnectionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isConnected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 15)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          isConnected
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                  child: Text('Connected', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                )
              : OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text('Connect', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
        ],
      ),
    );
  }
}
