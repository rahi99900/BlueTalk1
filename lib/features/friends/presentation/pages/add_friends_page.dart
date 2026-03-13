import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/services/auth_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/models/user_model.dart';
import '../../../../../../core/services/friends_repository.dart';
import '../../../../../../core/services/friends_provider.dart';
import 'dart:async';
import '../../../../../../shared/widgets/custom_loading_indicator.dart';
import '../../../../../../shared/utils/custom_snackbar.dart';

class AddFriendsPage extends ConsumerStatefulWidget {
  const AddFriendsPage({super.key});

  @override
  ConsumerState<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends ConsumerState<AddFriendsPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  late TabController _tabCtrl;
  Timer? _debounce;
  List<UserModel> _searchResults = [];
  List<UserModel> _suggestedUsers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadSuggestedUsers();
  }

  Future<void> _loadSuggestedUsers() async {
    final currentUserId = AuthService.instance.currentUser?.id;
    final users = await ref.read(friendsRepositoryProvider).getSuggestedUsers();
    final filtered = users.where((u) => u.id != currentUserId).toList();
    if (mounted) {
      setState(() {
        _suggestedUsers = filtered;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await ref.read(friendsRepositoryProvider).searchUsers(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
                  const Spacer(),
                  Text(
                    'Add Friends',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    onPressed: () async {
                      final scannedUserId = await context.push<String>('/qr-scanner');
                      if (scannedUserId != null && scannedUserId.isNotEmpty) {
                        setState(() => _isSearching = true);
                        try {
                          final user = await ref.read(friendsRepositoryProvider).getUserById(scannedUserId);
                          if (user != null) {
                            setState(() {
                              _searchResults = [user];
                              _isSearching = false;
                            });
                            _searchCtrl.clear();
                          } else {
                            if (mounted) {
                              CustomSnackbar.show(context, message: 'User not found.', type: SnackbarType.error);
                              setState(() => _isSearching = false);
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            CustomSnackbar.show(context, message: 'Error: $e', type: SnackbarType.error);
                            setState(() => _isSearching = false);
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // Tabs
            Container(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondaryLight,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 2.5,
                dividerColor: isDark ? AppColors.borderDark : AppColors.dividerLight,
                tabs: const [
                  Tab(text: 'Find Friends'),
                  Tab(text: 'Requests'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // Tab 1: Search
                  ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondaryLight, size: 20),
                          hintText: 'Search by username or name...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ).animate(delay: 50.ms).fadeIn(duration: 300.ms),

                  const SizedBox(height: 20),

                  // Quick actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _QuickAction(
                          icon: Icons.qr_code_rounded, 
                          label: 'My QR Code', 
                          color: AppColors.primary,
                          onTap: () => _showMyQrCode(context, isDark),
                        ),
                      ],
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

                  const SizedBox(height: 24),

                  // Results header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(_searchCtrl.text.isEmpty ? 'Suggested Friends' : 'Search Results', 
                              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),

                  if (_isSearching)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CustomLoadingIndicator(color: AppColors.primary)))
                  else if (_searchCtrl.text.isNotEmpty && _searchResults.isEmpty)
                     Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No users found', style: GoogleFonts.inter(color: AppColors.textSecondaryLight))))
                  else if (_searchCtrl.text.isEmpty && _suggestedUsers.isNotEmpty)
                     ..._suggestedUsers.asMap().entries.map((e) {
                       final user = e.value;
                       return _UserResultCard(user: user, isDark: isDark)
                           .animate(delay: Duration(milliseconds: 150 + e.key * 60))
                           .fadeIn(duration: 300.ms)
                           .slideY(begin: 0.1);
                     })
                  else if (_searchResults.isNotEmpty)
                    ..._searchResults.asMap().entries.map((e) {
                      final user = e.value;
                      return _UserResultCard(user: user, isDark: isDark)
                          .animate(delay: Duration(milliseconds: 150 + e.key * 60))
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.1);
                    }),
                ],
              ),
              // Tab 2: Requests
              _buildRequestsTab(isDark),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _buildRequestsTab(bool isDark) {
    final pendingAsync = ref.watch(pendingRequestsProvider);
    
    return pendingAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_disabled_rounded, size: 56, color: AppColors.textSecondaryLight),
                const SizedBox(height: 12),
                Text('No pending requests', style: GoogleFonts.inter(color: AppColors.textSecondaryLight, fontSize: 15)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          itemCount: requests.length,
          itemBuilder: (ctx, i) {
            final user = requests[i];
            return _PendingRequestCard(user: user, isDark: isDark)
                .animate(delay: Duration(milliseconds: i * 40))
                .fadeIn(duration: 280.ms);
          },
        );
      },
      loading: () => const Center(child: CustomLoadingIndicator(color: AppColors.primary)),
      error: (e, st) => Center(child: Text('Error loading requests: $e', style: const TextStyle(color: AppColors.errorRed))),
    );
  }
  void _showMyQrCode(BuildContext context, bool isDark) {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Scan to add me', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: 'bluetalk://user/${user.id}',
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text('@${user.displayName ?? user.id.substring(0, 8)}', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _UserResultCard extends ConsumerStatefulWidget {
  final UserModel user;
  final bool isDark;

  const _UserResultCard({required this.user, required this.isDark});

  @override
  ConsumerState<_UserResultCard> createState() => _UserResultCardState();
}

class _UserResultCardState extends ConsumerState<_UserResultCard> {
  bool _isLoading = false;

  void _sendRequest() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(friendsRepositoryProvider).sendFriendRequest(widget.user.id);
      // Status will automatically update via the StreamProvider
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(friendStatusProvider(widget.user.id));
    final status = statusAsync.value ?? 'none';
    
    final displayName = (widget.user.displayName?.isNotEmpty == true ? widget.user.displayName! : widget.user.username) ?? 'User';
    final colorVal = ((displayName.codeUnitAt(0) * 8)) % 0xFFFFFF + 0xFF000000;
    final userColor = Color(colorVal).withValues(alpha: 1.0);

    // Build button label + color based on status
    final bool canAdd = status == 'none';
    final String btnLabel;
    final Color btnColor;
    final Color btnTextColor;

    switch (status) {
      case 'friend':
        btnLabel = 'Friends ✓';
        btnColor = const Color(0xFF22C55E).withValues(alpha: 0.12);
        btnTextColor = const Color(0xFF22C55E);
        break;
      case 'sent':
        btnLabel = 'Sent';
        btnColor = widget.isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9);
        btnTextColor = AppColors.textSecondaryLight;
        break;
      case 'received':
        btnLabel = 'Accept';
        btnColor = AppColors.primary;
        btnTextColor = Colors.white;
        break;
      default:
        btnLabel = 'Add';
        btnColor = AppColors.primary;
        btnTextColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: userColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.network(widget.user.avatarUrl!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          displayName[0].toUpperCase(),
                          style: TextStyle(color: userColor, fontWeight: FontWeight.w700, fontSize: 20),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text('@${widget.user.username ?? 'user'}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Action button
          GestureDetector(
            onTap: status == 'received' ? () async {
              setState(() => _isLoading = true);
              await ref.read(friendsRepositoryProvider).acceptRequest(widget.user.id);
              if (mounted) setState(() => _isLoading = false);
            } : canAdd ? _sendRequest : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: statusAsync.isLoading || _isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CustomLoadingIndicator(color: Colors.white))
                  : Text(
                      btnLabel,
                      style: GoogleFonts.inter(
                        color: btnTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends ConsumerStatefulWidget {
  final UserModel user;
  final bool isDark;

  const _PendingRequestCard({required this.user, required this.isDark});

  @override
  ConsumerState<_PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends ConsumerState<_PendingRequestCard> {
  bool _isLoading = false;

  void _accept() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(friendsRepositoryProvider).acceptRequest(widget.user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _reject() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(friendsRepositoryProvider).rejectRequest(widget.user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reject: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (widget.user.displayName?.isNotEmpty == true ? widget.user.displayName! : widget.user.username) ?? 'User';
    final colorVal = ((displayName.codeUnitAt(0) * 8)) % 0xFFFFFF + 0xFF000000;
    final userColor = Color(colorVal).withValues(alpha: 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: userColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.network(widget.user.avatarUrl!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          displayName[0].toUpperCase(),
                          style: TextStyle(color: userColor, fontWeight: FontWeight.w700, fontSize: 20),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text('@${widget.user.username ?? 'user'}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _reject,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 18, height: 18, child: CustomLoadingIndicator(color: AppColors.errorRed))
                    : const Icon(Icons.close_rounded, color: AppColors.errorRed, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                 onTap: _accept,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(
                     color: AppColors.primary,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: _isLoading 
                     ? const SizedBox(width: 18, height: 18, child: CustomLoadingIndicator(color: Colors.white))
                     : Text(
                     'Accept',
                     style: GoogleFonts.inter(
                       color: Colors.white,
                       fontWeight: FontWeight.w700,
                       fontSize: 13,
                     ),
                   ),
                 ),
               ),
            ],
          ),
        ],
      ),
    );
  }
}
