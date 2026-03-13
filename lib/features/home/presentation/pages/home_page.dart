import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/group_model.dart';
import '../../../../core/services/groups_provider.dart';
import '../../../../core/services/rooms_provider.dart';
import '../../../../core/services/friends_provider.dart';
import '../../../../core/models/user_model.dart';
import '../../../../shared/widgets/custom_loading_indicator.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {

  // ── Room picker bottom sheet ──
  void _showRoomPicker(BuildContext ctx, GroupModel group) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    
    // Aesthetic Color logic
    final colorVal = (((group.name.codeUnitAt(0) * 8)) % 0xFFFFFF) + 0xFF000000;
    final groupColor = Color(colorVal).withValues(alpha: 1.0);

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.65),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2035) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2)))),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: groupColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                      style: TextStyle(color: groupColor, fontWeight: FontWeight.w800, fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(group.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('Choose a voice room to join',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight)),
                ])),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ctx.push('/group/${group.id}');
                  },
                  child: Text('Manage', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            // Rooms List Stream
            Flexible(
              child: Consumer(
                builder: (context, ref, _) {
                  final roomsStream = ref.watch(roomsProvider(group.id));
                  
                  return roomsStream.when(
                    data: (rooms) {
                      if (rooms.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.mic_none_rounded, size: 40, color: AppColors.textSecondaryLight.withValues(alpha: 0.5)),
                              const SizedBox(height: 8),
                              Text('No rooms in this group',
                                  style: GoogleFonts.inter(color: AppColors.textSecondaryLight, fontSize: 13)),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: rooms.length,
                        itemBuilder: (c, i) {
                          final room = rooms[i];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              ctx.push('/voice-room/${room.id}?name=${Uri.encodeComponent(room.name)}');
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: groupColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.mic_rounded, color: groupColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Text(room.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                  ]),
                                  Text('0 members',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight)),
                                ])),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Join', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ]),
                            ).animate(delay: Duration(milliseconds: i * 50)).fadeIn(duration: 250.ms).slideY(begin: 0.08),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CustomLoadingIndicator(color: AppColors.primary),
                    )),
                    error: (err, stack) => Center(child: Text('Error loading rooms: $err')),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : Colors.white,
                border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  // BlueTalk logo
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('BlueTalk',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight, letterSpacing: -0.3)),
                  ]),
                  const Spacer(),
                  // Add Friends button with red dot badge
                  Consumer(
                    builder: (ctx, ref, _) {
                      final pendingCount = ref.watch(pendingRequestsCountProvider);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          TextButton.icon(
                            onPressed: () => context.push('/add-friends'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              backgroundColor: isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primaryLight.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: Text('Add Friends', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                          if (pendingCount > 0)
                            Positioned(
                              top: -2, right: -2,
                              child: Container(
                                width: 14, height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? AppColors.backgroundDark : Colors.white, width: 1.5),
                                ),
                                child: pendingCount > 9
                                    ? null
                                    : Center(
                                        child: Text('$pendingCount',
                                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                                      ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // ── Body ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // ── Online friends ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Row(children: [
                      Text('YOUR FRIENDS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, letterSpacing: 1)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/add-friends'),
                        child: Text('Find More', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),

                  SizedBox(
                    height: 88,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final friendsStream = ref.watch(friendsProvider);
                        
                        return friendsStream.when(
                          data: (allFriends) {
                            final friends = allFriends;
                            
                            if (friends.isEmpty) {
                              return Center(
                                child: Text('No friends added yet.', 
                                    style: GoogleFonts.inter(color: AppColors.textSecondaryLight, fontSize: 13)),
                              );
                            }
                            
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              scrollDirection: Axis.horizontal,
                              itemCount: friends.length,
                              itemBuilder: (ctx, i) {
                                final f = friends[i];
                                return _FriendAvatar(friend: f)
                                    .animate(delay: Duration(milliseconds: i * 60))
                                    .fadeIn(duration: 300.ms)
                                    .slideX(begin: 0.1);
                              },
                            );
                          },
                          loading: () => const Center(child: CustomLoadingIndicator(color: AppColors.primary)),
                          error: (error, stack) => const Center(child: Text('Failed to load friends', style: TextStyle(color: AppColors.errorRed))),
                        );
                      }
                    ),
                  ),

                  // ── My Groups ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Row(
                      children: [
                        Text('MY GROUPS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, letterSpacing: 1)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.go('/groups'),
                          child: Text('See all', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  // ── Group cards ──
                  Consumer(
                    builder: (context, ref, _) {
                      final groupsAsync = ref.watch(userGroupsProvider);
                      
                      return groupsAsync.when(
                        data: (groups) {
                          if (groups.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No groups yet. Create or join one!'),
                              ),
                            );
                          }
                          return Column(
                            children: groups.asMap().entries.map((e) {
                              final g = e.value;
                              return _GroupCard(
                                group: g,
                                isDark: isDark,
                                onTap: () => _showRoomPicker(context, g),
                              ).animate(delay: Duration(milliseconds: e.key * 70))
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: 0.08);
                            }).toList(),
                          );
                        },
                        loading: () => const Center(child: CustomLoadingIndicator(color: AppColors.primary)),
                        error: (err, stack) => const Center(child: Text('Error loading groups.')),
                      );
                    }
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

// Removed unused _Friend class

// ── Friend avatar ──
class _FriendAvatar extends StatelessWidget {
  final UserModel friend;
  const _FriendAvatar({required this.friend});

  @override
  Widget build(BuildContext context) {
    // Aesthetic color by name
    final colorVal = (((friend.displayName ?? friend.username ?? 'U').codeUnitAt(0) * 8)) % 0xFFFFFF + 0xFF000000;
    final friendColor = Color(colorVal).withValues(alpha: 1.0);

    return Container(
        width: 64,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: friendColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(friend.avatarUrl!, fit: BoxFit.cover),
                    )
                  : Center(
                      child: Text(
                        (friend.displayName ?? friend.username ?? 'U')[0].toUpperCase(),
                        style: TextStyle(color: friendColor, fontWeight: FontWeight.w700, fontSize: 20),
                      ),
                    ),
            ),
            const SizedBox(height: 5),
            Text((friend.displayName?.isNotEmpty == true ? friend.displayName! : friend.username) ?? 'User',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
    );
  }
}

// ── Group card ──
class _GroupCard extends ConsumerWidget {
  final GroupModel group;
  final bool isDark;
  final VoidCallback onTap;
  const _GroupCard({required this.group, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We stream rooms here just to get the 'live count', though this creates a subscription per card.
    // For a real app with many groups, you might condense this. 
    final roomsStream = ref.watch(roomsProvider(group.id));
    
    final colorVal = (((group.name.codeUnitAt(0) * 8)) % 0xFFFFFF) + 0xFF000000;
    final groupColor = Color(colorVal).withValues(alpha: 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            // Group icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: groupColor.withValues(alpha: 0.12),
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
                  : Center(child: Text(group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                      style: TextStyle(color: groupColor, fontWeight: FontWeight.w800, fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(group.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(group.description ?? 'A voice community',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.people_outline_rounded, size: 12, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 3),
                  Text('Members',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 10),
                  
                  // Rooms count based on stream
                  roomsStream.maybeWhen(
                    data: (rooms) {
                      final roomCount = rooms.length;
                      if (roomCount > 0) {
                        return Row(
                           children: [
                             Container(width: 6, height: 6,
                                 decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                             const SizedBox(width: 4),
                             Text('$roomCount room${roomCount > 1 ? 's' : ''}',
                                 style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                           ]
                        );
                      }
                      return Text('No rooms',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight));
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_right_rounded, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}
