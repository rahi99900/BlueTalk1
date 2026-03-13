import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/custom_snackbar.dart';

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final _linkCtrl = TextEditingController();

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  void _handleJoin() {
    final text = _linkCtrl.text.trim();
    if (text.isEmpty) return;

    // A standard BlueTalk invite link looks like: bluetalk.app/g/KJh23hSdf9328Hsdkhf
    // Extract the group ID from the last part of the link
    final parts = text.split('/');
    final possibleId = parts.last.trim();

    // Assuming Firestore auto-generated document IDs are 20 characters long
    if (possibleId.length == 20 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(possibleId)) {
      context.push('/join-group-preview/$possibleId');
    } else {
      CustomSnackbar.show(
        context,
        message: 'Invalid invite link. Please paste a valid BlueTalk invite link.',
        type: SnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Join a Group', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Description Header ──
              Text(
                'Enter an invite link to join an existing group.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 32),

              // ── Input Field ──
              Text(
                'INVITE LINK',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              
              TextField(
                controller: _linkCtrl,
                autofocus: true,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. bluetalk.app/g/aB3kFx9...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textSecondaryLight),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0D1117) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste_rounded, size: 20, color: AppColors.primary),
                    tooltip: 'Paste from clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        setState(() => _linkCtrl.text = data!.text!);
                      }
                    },
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _handleJoin(),
              ),

              const Spacer(),

              // ── Join Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _linkCtrl.text.trim().isEmpty ? null : _handleJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Join Group',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

