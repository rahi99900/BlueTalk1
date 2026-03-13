import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../shared/utils/custom_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/group_model.dart';
import '../../../../core/services/groups_repository.dart';
import '../../../../core/services/groups_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/cloudinary_service.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/widgets/custom_loading_indicator.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  void _showCreateGroupForm() {
    final nameCtrl = TextEditingController();
    bool isLoading = false;
    bool isUploadingImage = false;
    String? uploadedImageUrl;

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
                  Text('Create Group', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
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
                            image: uploadedImageUrl != null 
                                ? DecorationImage(image: NetworkImage(uploadedImageUrl!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: (uploadedImageUrl == null) 
                              ? Center(child: Text(nameCtrl.text.isNotEmpty ? nameCtrl.text[0].toUpperCase() : 'G',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 36, fontWeight: FontWeight.w800)))
                              : null,
                        ),
                        if (isUploadingImage)
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                            child: const Center(child: CustomLoadingIndicator(color: Colors.white)),
                          ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: isUploadingImage ? null : () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                              if (pickedFile != null) {
                                setLocal(() { isUploadingImage = true; });
                                String? url;
                                if (kIsWeb) {
                                  final bytes = await pickedFile.readAsBytes();
                                  url = await CloudinaryService.instance.uploadImage(bytes: bytes, filename: pickedFile.name);
                                } else {
                                  url = await CloudinaryService.instance.uploadImage(filePath: pickedFile.path);
                                }
                                setLocal(() {
                                  isUploadingImage = false;
                                  if (url != null) {
                                    uploadedImageUrl = url;
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
                    onChanged: (v) => setLocal(() {}),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Group Name',
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
                      
                      try {
                        await ref.read(groupsRepositoryProvider).createGroup(
                          name: nameCtrl.text.trim(),
                          description: 'A new voice community',
                          profilePicUrl: uploadedImageUrl,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          CustomSnackbar.show(context, message: 'Group created successfully!');
                        }
                      } catch (e) {
                         setLocal(() => isLoading = false);
                         if (mounted) {
                           CustomSnackbar.show(context, message: 'Failed to create group.', type: SnackbarType.error);
                         }
                      }
                    },
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CustomLoadingIndicator(color: Colors.white))
                        : Text('Confirm', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Groups',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  // Action Buttons
                  Row(
                    children: [
                      _HeaderButton(
                        icon: Icons.search_rounded,
                        label: 'Join',
                        color: const Color(0xFF10B981), // Emerald
                        onTap: () => context.push('/join-group'),
                      ),
                      const SizedBox(width: 8),
                      _HeaderButton(
                        icon: Icons.add_rounded,
                        label: 'Create',
                        color: AppColors.primary,
                        onTap: _showCreateGroupForm,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final groupsAsync = ref.watch(userGroupsProvider);
                  
                  return groupsAsync.when(
                    data: (groups) {
                      if (groups.isEmpty) {
                        return Center(
                           child: Text("You haven't joined any groups yet.\nCreate or join one!", 
                             textAlign: TextAlign.center,
                             style: GoogleFonts.inter(color: AppColors.textSecondaryLight),
                           ),
                        );
                      }
                      
                      return ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          const SizedBox(height: 16),
                          ...groups.asMap().entries.map((e) {
                            final g = e.value;
                            return _GroupCard(group: g, isDark: isDark, onTap: () {
                              context.push('/group/${g.id}');
                            })
                                .animate(delay: Duration(milliseconds: e.key * 80))
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: 0.1);
                          }),
                        ],
                      );
                    },
                    loading: () => const Center(child: CustomLoadingIndicator(color: AppColors.primary)),
                    error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.errorRed))),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final bool isDark;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // We'll use a static color mapped from ID hash for consistency since we don't store colors yet
    final colorVal = (((group.name.codeUnitAt(0) * 8)) % 0xFFFFFF) + 0xFF000000;
    final displayColor = Color(colorVal).withValues(alpha: 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            // Group avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: displayColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                image: group.profilePicUrl != null && group.profilePicUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(group.profilePicUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: group.profilePicUrl != null && group.profilePicUrl!.isNotEmpty
                  ? null
                  : Center(
                      child: Text(
                        group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                        style: TextStyle(
                          color: displayColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.description ?? 'No description provided.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 13, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text('Members', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
