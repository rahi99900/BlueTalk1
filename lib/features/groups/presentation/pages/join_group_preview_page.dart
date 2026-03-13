import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/custom_snackbar.dart';
import '../../../../core/models/group_model.dart';
import '../../../../core/services/groups_repository.dart';
import '../../../../shared/widgets/custom_loading_indicator.dart';

class JoinGroupPreviewPage extends ConsumerStatefulWidget {
  final String groupId;
  
  const JoinGroupPreviewPage({super.key, required this.groupId});

  @override
  ConsumerState<JoinGroupPreviewPage> createState() => _JoinGroupPreviewPageState();
}

class _JoinGroupPreviewPageState extends ConsumerState<JoinGroupPreviewPage> {
  bool _isLoading = true;
  bool _isJoining = false;
  GroupModel? _group;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (doc.exists) {
        setState(() {
          final data = doc.data()!;
          data['id'] = doc.id;
          _group = GroupModel.fromJson(data);
          _isLoading = false;
        });
      } else {
        if (mounted) {
          CustomSnackbar.show(context, message: 'Group not found or invite link is invalid.', type: SnackbarType.error);
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, message: 'Failed to load group details.', type: SnackbarType.error);
        context.pop();
      }
    }
  }

  Future<void> _joinGroup() async {
    setState(() => _isJoining = true);
    try {
      await ref.read(groupsRepositoryProvider).joinGroup(widget.groupId);
      if (mounted) {
        CustomSnackbar.show(context, message: 'Successfully joined the group!');
        context.go('/group/${widget.groupId}'); // Go directly to the group chat
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, message: 'Failed to join group.', type: SnackbarType.error);
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CustomLoadingIndicator(color: AppColors.primary)),
      );
    }
    
    if (_group == null) return const Scaffold();

    final groupName = _group!.name;
    final firstLetter = groupName.isNotEmpty ? groupName[0].toUpperCase() : 'G';
    final bgColor = (((groupName.codeUnitAt(0) * 8)) % 0xFFFFFF) + 0xFF000000;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(bgColor).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    firstLetter,
                    style: GoogleFonts.inter(
                      fontSize: 48, 
                      fontWeight: FontWeight.w800, 
                      color: Color(bgColor).withValues(alpha: 1.0)
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'You\'ve been invited to join',
                style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 8),
              Text(
                groupName,
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              if (_group!.description != null && _group!.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _group!.description!,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondaryLight),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Decline', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isJoining ? null : _joinGroup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isJoining
                          ? const SizedBox(width: 24, height: 24, child: CustomLoadingIndicator(color: Colors.white))
                          : Text('Join Group', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
