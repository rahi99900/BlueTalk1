import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../shared/utils/custom_snackbar.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/models/voice_room_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/rooms_repository.dart';
import '../../../../core/services/rooms_provider.dart';
import '../../../../core/services/groups_provider.dart';
import '../../../../core/services/groups_repository.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/friends_provider.dart';
import '../../../../shared/widgets/custom_loading_indicator.dart';

class GroupDetailPage extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  @override
  void initState() {
    super.initState();
  }

  // ── Edit group bottom sheet ──
  void _showEditSheet(String currentName, String currentPic) {
    final nameCtrl = TextEditingController(text: currentName);
    File? pickedImage;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setLocal) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
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
                Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18)),
                  const SizedBox(width: 10),
                  Text('Edit Group', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 20),
                // Group picture picker
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                          if (img != null) {
                            setLocal(() => pickedImage = File(img.path));
                          }
                        },
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: pickedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(pickedImage!, fit: BoxFit.cover),
                                )
                              : currentPic.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.network(currentPic, fit: BoxFit.cover),
                                    )
                                  : Center(child: Text(
                                      nameCtrl.text.isNotEmpty ? nameCtrl.text[0].toUpperCase() : 'G',
                                      style: const TextStyle(color: AppColors.primary, fontSize: 36, fontWeight: FontWeight.w800),
                                    )),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 26, height: 26,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Group Name', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  onChanged: (_) => setLocal(() {}),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      setLocal(() => isSaving = true);
                      try {
                        // Upload image if picked
                        String? newImageUrl;
                        if (pickedImage != null) {
                          // Use existing Cloudinary or a simple upload
                          // For now, we store the local path reference which Cloudinary service handles
                          try {
                            final cloudinaryUrl = await CloudinaryService.instance.uploadImage(filePath: pickedImage!.path);
                            newImageUrl = cloudinaryUrl;
                          } catch (uploadErr) {
                            // If upload fails, just save without image
                          }
                        }
                        await ref.read(groupsRepositoryProvider).updateGroupDetails(
                          widget.groupId,
                          name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                          profilePicUrl: newImageUrl,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          CustomSnackbar.show(context, message: 'Group updated successfully!');
                        }
                      } catch (e) {
                        setLocal(() => isSaving = false);
                        if (mounted) {
                          CustomSnackbar.show(context, message: 'Failed to save: $e', type: SnackbarType.error);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CustomLoadingIndicator(color: Colors.white))
                        : Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Invite bottom sheet ──
  void _showInviteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2035) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Center(child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: const Color(0xFF25D366).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.person_add_rounded, color: Color(0xFF25D366), size: 18)),
                    const SizedBox(width: 10),
                    Text('Invite to Group', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const Divider(height: 20),
                // Share options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SHARE VIA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppColors.textSecondaryLight, letterSpacing: 1)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ShareOption(icon: Icons.link_rounded, label: 'Copy Link',
                              color: AppColors.primary, bg: AppColors.primaryLight,
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: 'Hey! Join my awesome BlueTalk group here: https://invite.bluetalk.site/i/${widget.groupId}'));
                                Navigator.pop(ctx);
                                CustomSnackbar.show(context, message: 'Invite link copied!');
                              }),
                          _ShareOption(
                              faIcon: FontAwesomeIcons.whatsapp, label: 'WhatsApp',
                              color: const Color(0xFF25D366), bg: const Color(0xFFDCFCE7),
                               onTap: () {
                                Share.share('Hey! Join my awesome BlueTalk group here: https://invite.bluetalk.site/i/${widget.groupId}');
                              }),
                          _ShareOption(
                              faIcon: FontAwesomeIcons.facebook, label: 'Facebook',
                              color: const Color(0xFF1877F2), bg: const Color(0xFFDBEAFE),
                               onTap: () {
                                Share.share('Hey! Join my awesome BlueTalk group here: https://invite.bluetalk.site/i/${widget.groupId}');
                              }),
                          _ShareOption(
                              faIcon: FontAwesomeIcons.facebookMessenger, label: 'Messenger',
                              color: const Color(0xFF8B5CF6), bg: const Color(0xFFEDE9FE),
                               onTap: () {
                                Share.share('Hey! Join my awesome BlueTalk group here: https://invite.bluetalk.site/i/${widget.groupId}');
                              }),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Text('ADD FROM FRIENDS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppColors.textSecondaryLight, letterSpacing: 1)),
                  ]),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Consumer(builder: (context, ref, _) {
                    final friendsAsync = ref.watch(friendsProvider);
                    return friendsAsync.when(
                      data: (friends) {
                        if (friends.isEmpty) {
                           return Center(child: Text('You have no friends yet.', style: GoogleFonts.inter(color: AppColors.textSecondaryLight)));
                        }
                        return ListView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ...friends.map((friend) => _FriendInviteRow(
                              user: friend,
                              isDark: isDark,
                              onInvite: () async {
                                try {
                                  await ref.read(groupsRepositoryProvider).addMember(widget.groupId, friend.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${friend.displayName ?? friend.username} added to the group!'), duration: const Duration(seconds: 2)),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to add friend: $e'), duration: const Duration(seconds: 2)),
                                    );
                                  }
                                }
                              },
                            )),
                          ],
                        );
                      },
                      loading: () => const Center(child: CustomLoadingIndicator(color: AppColors.primary)),
                      error: (err, st) => Center(child: Text('Error loading friends: $err')),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Create Room dialog ──
  void _showCreateRoom() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A2035) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 18)),
            const SizedBox(width: 10),
            Text('Create Room', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Room name (e.g. Strategy Room)',
              filled: true,
              fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            onSubmitted: (_) => _createRoom(ctrl.text, ctx),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => _createRoom(ctrl.text, ctx),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Create', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _createRoom(String name, BuildContext ctx) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    
    Navigator.pop(ctx);
    try {
      await ref.read(roomsRepositoryProvider).createRoom(
        groupId: widget.groupId,
        name: trimmed,
      );
      if (mounted) {
        CustomSnackbar.show(context, message: 'Room "$trimmed" created!');
      }
    } catch(e) {
      if (mounted) {
        CustomSnackbar.show(context, message: 'Failed to create room', type: SnackbarType.error);
      }
    }
  }

  // ── Members List bottom sheet ──
  void _showMembersList(List<UserModel> members, String? adminId, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          maxChildSize: 0.9,
          minChildSize: 0.6,
          initialChildSize: 0.7,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2035) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Center(child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2)))),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    Text('Group Members', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                      child: Text('${members.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                  ]),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isMemberAdmin = member.id == adminId;
                      final canKick = isAdmin && !isMemberAdmin;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primaryLight,
                                  backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                                  child: member.avatarUrl == null ? Text(member.displayName?[0].toUpperCase() ?? member.username?[0].toUpperCase() ?? 'U') : null,
                                ),
                                if (isMemberAdmin)
                                  Positioned(
                                    bottom: 0, right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                                      child: const Icon(Icons.shield_rounded, size: 10, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member.displayName ?? member.username ?? 'Unknown', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                  if (isMemberAdmin)
                                    Text('Admin', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            if (canKick)
                              IconButton(
                                icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () => _confirmKick(member),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmKick(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kick ${user.displayName ?? user.username}?'),
        content: const Text('This will remove the user from the group. They can join again via an invite link.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(groupsRepositoryProvider).kickMember(widget.groupId, user.id);
                if (mounted) CustomSnackbar.show(context, message: 'User kicked successfully.');
              } catch (e) {
                if (mounted) CustomSnackbar.show(context, message: 'Failed to kick: $e', type: SnackbarType.error);
              }
            },
            child: const Text('Kick', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Find group info
    final groupsAsync = ref.watch(userGroupsProvider);
    final group = groupsAsync.maybeWhen(
      data: (groups) => groups.where((g) => g.id == widget.groupId).firstOrNull,
      orElse: () => null,
    );
    final groupName = group?.name ?? 'Unknown Group';
    final profilePicUrl = group?.profilePicUrl;
    
    // Stream rooms
    final roomsStream = ref.watch(roomsProvider(widget.groupId));
    
    // Member count stream
    final memberCountAsync = ref.watch(groupMemberCountProvider(widget.groupId));
    final memberCount = memberCountAsync.valueOrNull ?? 1;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : Colors.white,
                border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
                  Expanded(
                    child: Text('Group Management', textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  // Invite button
                  TextButton.icon(
                    onPressed: _showInviteSheet,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: Text('Invite', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                  if (group?.adminId == AuthService.instance.currentUser?.id || group?.createdBy == AuthService.instance.currentUser?.id)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                      tooltip: 'Edit Group',
                      onPressed: () {
                        final grp = ref.read(userGroupsProvider).valueOrNull?.where((g) => g.id == widget.groupId).firstOrNull;
                        _showEditSheet(groupName, grp?.profilePicUrl ?? '');
                      },
                    ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  // ── Group hero ──
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 3),
                            image: profilePicUrl != null && profilePicUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(profilePicUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: profilePicUrl != null && profilePicUrl.isNotEmpty
                              ? null
                              : Center(
                                  child: Text(
                                    groupName.isNotEmpty ? groupName[0].toUpperCase() : 'G',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 14),
                        Text(groupName,
                            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800))
                            .animate(delay: 100.ms).fadeIn(duration: 300.ms),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(width: 7, height: 7,
                              decoration: const BoxDecoration(color: AppColors.onlineGreen, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text('$memberCount Members • Active now',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
                        ]).animate(delay: 150.ms).fadeIn(duration: 300.ms),
                      ],
                    ),
                  ),

                  // ── Members Row ──
                  Consumer(builder: (context, ref, _) {
                    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
                    return membersAsync.when(
                      data: (members) {
                        if (members.isEmpty) return const SizedBox.shrink();
                        
                        final displayMembers = members.take(5).toList();
                        final hasMore = members.length > 5;

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Group Members', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      final currentUserId = AuthService.instance.currentUser?.id;
                                      final isAdmin = group?.adminId == currentUserId || group?.createdBy == currentUserId;
                                      _showMembersList(members, group?.adminId, isAdmin);
                                    },
                                    child: Text('See All', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ...displayMembers.map((m) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: AppColors.primaryLight,
                                          backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                                          child: m.avatarUrl == null ? Text(m.displayName?[0].toUpperCase() ?? m.username?[0].toUpperCase() ?? 'U', style: const TextStyle(fontSize: 14)) : null,
                                        ),
                                        if (m.id == group?.adminId)
                                          Positioned(
                                            bottom: 0, right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                                              child: const Icon(Icons.shield_rounded, size: 8, color: Colors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )),
                                  if (hasMore)
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9), shape: BoxShape.circle),
                                      child: Center(child: Text('+${members.length - 5}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700))),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  }).animate(delay: 150.ms).fadeIn(duration: 300.ms),

                  // ── Create room button ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: ElevatedButton.icon(
                      onPressed: _showCreateRoom,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text('Create Room', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
                  ),

                  // ── Rooms header & Grid ──
                  roomsStream.when(
                    data: (rooms) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Voice Rooms', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                                  child: Text('${rooms.length} ROOMS',
                                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ),
                              ],
                            ),
                          ),
                          if (rooms.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.mic_off_rounded, size: 48, color: AppColors.textSecondaryLight.withValues(alpha: 0.5)),
                                    const SizedBox(height: 12),
                                    Text('No rooms yet', style: GoogleFonts.inter(color: AppColors.textSecondaryLight)),
                                    const SizedBox(height: 4),
                                    Text('Tap "Create Room" to add one',
                                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight)),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...rooms.asMap().entries.map((e) {
                              final r = e.value;
                              return _RoomCard(room: r, isDark: isDark, groupId: widget.groupId)
                                  .animate(delay: Duration(milliseconds: 250 + (e.key * 70).toInt()))
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: 0.1);
                            }),
                        ]
                      );
                    },
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CustomLoadingIndicator(color: AppColors.primary),
                    )),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic_off_rounded, size: 40, color: AppColors.textSecondaryLight.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text('No rooms yet', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('Tap "Create Room" to add one', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
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

// ── Room Card ──
class _RoomCard extends StatelessWidget {
  final VoiceRoomModel room;
  final bool isDark;
  final String groupId;
  const _RoomCard({required this.room, required this.isDark, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: isDark ? Border.all(color: AppColors.borderDark) : null,
            ),
            child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(room.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
              const SizedBox(height: 2),
              Text('0 members joined',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
            ]),
          ),
          OutlinedButton(
            onPressed: () => context.push('/voice-room/${room.id}?name=${Uri.encodeComponent(room.name)}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Join', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Share option ──
class _ShareOption extends StatelessWidget {
  final IconData? icon;
  final IconData? faIcon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _ShareOption({this.icon, this.faIcon, required this.label, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Center(child: faIcon != null 
              ? FaIcon(faIcon, color: color, size: 26) 
              : Icon(icon, color: color, size: 26)),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
      ]),
    );
  }
}

// ── Friend invite row ──
class _FriendInviteRow extends StatefulWidget {
  final UserModel user;
  final bool isDark;
  final VoidCallback onInvite;
  const _FriendInviteRow({required this.user, required this.isDark, required this.onInvite});

  @override
  State<_FriendInviteRow> createState() => _FriendInviteRowState();
}

class _FriendInviteRowState extends State<_FriendInviteRow> {
  bool _invited = false;
  @override
  Widget build(BuildContext context) {
    final displayName = (widget.user.displayName?.isNotEmpty == true ? widget.user.displayName! : widget.user.username) ?? 'User';
    final colorVal = ((displayName.codeUnitAt(0) * 8)) % 0xFFFFFF + 0xFF000000;
    final userColor = Color(colorVal).withValues(alpha: 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: userColor.withValues(alpha: 0.15), 
            shape: BoxShape.circle
          ),
          child: widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(widget.user.avatarUrl!, fit: BoxFit.cover),
              )
            : Center(child: Text(displayName[0].toUpperCase(),
                style: TextStyle(color: userColor, fontWeight: FontWeight.w700, fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          Text('@${widget.user.username ?? "user"}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight)),
        ])),
        GestureDetector(
          onTap: () {
            if (_invited) return;
            setState(() => _invited = true);
            widget.onInvite();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _invited ? AppColors.onlineGreen.withValues(alpha: 0.12) : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _invited ? 'Added ✓' : 'Add',
              style: GoogleFonts.inter(
                color: _invited ? AppColors.onlineGreen : AppColors.primary,
                fontWeight: FontWeight.w700, fontSize: 13,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

