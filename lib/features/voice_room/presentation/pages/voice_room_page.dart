import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';

// ── Global mini-player state (simple singleton) ──
class VoiceRoomState {
  VoiceRoomState._();
  static final VoiceRoomState instance = VoiceRoomState._();

  String? activeRoomId;
  String? activeRoomName;

  void joinRoom(String id, String name) {
    activeRoomId = id;
    activeRoomName = name;
  }

  void leaveRoom() {
    activeRoomId = null;
    activeRoomName = null;
  }
}

class VoiceRoomPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const VoiceRoomPage({super.key, required this.roomId, required this.roomName});

  @override
  State<VoiceRoomPage> createState() => _VoiceRoomPageState();
}

class _VoiceRoomPageState extends State<VoiceRoomPage> with TickerProviderStateMixin {
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  // Audio settings state
  double _outputVolume = 0.75;
  double _inputVolume = 0.80;
  bool _noiseCancell = true;

  // Room background
  int _bgIndex = 0;

  @override
  void initState() {
    super.initState();
    VoiceRoomState.instance.joinRoom(widget.roomId, widget.roomName);
  }

  // ── Leave / Minimize ──
  void _minimize() {
    // Go home, keep mini-player active
    context.go('/home');
  }

  void _leaveRoom() {
    VoiceRoomState.instance.leaveRoom();
    context.go('/home');
  }

  // ── Participant tap menu ──
  void _showParticipantMenu(BuildContext ctx, _Participant p, bool isHost) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark; // needed for container color
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2035) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              // User info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 48, height: 48,
                    decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                    child: Center(child: Text(p.name[0],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)))),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(p.role, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight)),
                  ]),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              _MenuItem(icon: Icons.mic_off_rounded, label: 'Mute for me', iconColor: AppColors.primary,
                  onTap: () => Navigator.pop(ctx)),
              _MenuItem(icon: Icons.volume_down_rounded, label: 'Lower volume', iconColor: AppColors.primary,
                  onTap: () => Navigator.pop(ctx)),
              if (isHost)
                _MenuItem(icon: Icons.person_remove_rounded, label: 'Kick from room',
                    iconColor: AppColors.errorRed, textColor: AppColors.errorRed,
                    onTap: () => Navigator.pop(ctx)),
              _MenuItem(icon: Icons.person_outline_rounded, label: 'View profile', iconColor: AppColors.primary,
                  onTap: () => Navigator.pop(ctx)),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── Settings menu bottom sheet ──
  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2035) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.tune_rounded,
                label: 'Audio Settings',
                subLabel: 'Volume, noise cancellation',
                iconColor: AppColors.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showAudioSettings();
                },
              ),
              _MenuItem(
                icon: Icons.wallpaper_rounded,
                label: 'Room Background',
                subLabel: 'Change room background (Admin)',
                iconColor: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(ctx);
                  _showBackgroundPicker();
                },
              ),
              _MenuItem(
                icon: Icons.group_rounded,
                label: 'Group Detail',
                subLabel: 'View group info and members',
                iconColor: const Color(0xFF14B8A6),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/group/1');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── Audio settings bottom sheet ──
  void _showAudioSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
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
                  child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20)),
                const SizedBox(width: 10),
                Text('Audio Settings', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 20),
              // Output volume
              _SliderRow(
                icon: Icons.volume_up_rounded,
                label: 'Output Volume',
                value: _outputVolume,
                onChanged: (v) { setLocal(() {}); setState(() => _outputVolume = v); },
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              // Input volume
              _SliderRow(
                icon: Icons.mic_rounded,
                label: 'Input Volume',
                value: _inputVolume,
                onChanged: (v) { setLocal(() {}); setState(() => _inputVolume = v); },
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              // Noise cancellation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _noiseCancell ? AppColors.primaryLight : (isDark ? const Color(0xFF1E2535) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.noise_control_off_rounded,
                        color: _noiseCancell ? AppColors.primary : AppColors.textSecondaryLight, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Noise Cancellation', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('Reduce background noise', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight)),
                  ])),
                  Switch(
                    value: _noiseCancell,
                    onChanged: (v) { setLocal(() {}); setState(() => _noiseCancell = v); },
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primaryLight,
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      }),
    );
  }

  // ── Background picker ──
  void _showBackgroundPicker() {
    final backgrounds = [
      {'label': 'Default', 'color': const Color(0xFF0D1117)},
      {'label': 'Space', 'color': const Color(0xFF0F0C29)},
      {'label': 'Ocean', 'color': const Color(0xFF0F2027)},
      {'label': 'Forest', 'color': const Color(0xFF134E4A)},
      {'label': 'Sunset', 'color': const Color(0xFF7F1D1D)},
      {'label': 'Purple', 'color': const Color(0xFF2D1B69)},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
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
                  decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.wallpaper_rounded, color: Color(0xFF8B5CF6), size: 20)),
                const SizedBox(width: 10),
                Text('Room Background', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              Text('Admin only — changes for everyone', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
                children: List.generate(backgrounds.length, (i) {
                  final bg = backgrounds[i];
                  final selected = _bgIndex == i;
                  return GestureDetector(
                    onTap: () {
                      setLocal(() {});
                      setState(() => _bgIndex = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bg['color'] as Color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.primary : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        if (selected) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        const SizedBox(height: 4),
                        Text(bg['label'] as String,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      }),
    );
  }

  // ── Backgrounds list ──
  final List<Color> _bgs = [
    const Color(0xFF0D1117),
    const Color(0xFF0F0C29),
    const Color(0xFF0F2027),
    const Color(0xFF134E4A),
    const Color(0xFF7F1D1D),
    const Color(0xFF2D1B69),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: _bgs[_bgIndex],
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  // Minimize (down arrow)
                  GestureDetector(
                    onTap: _minimize,
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Colors.white),
                    ),
                  ),
                  // Room name center
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.roomName,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 6, height: 6,
                              decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                            ).animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 600.ms),
                            const SizedBox(width: 5),
                            Text('LIVE • 12 ONLINE',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: Colors.white60, letterSpacing: 1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Leave button (top right)
                  GestureDetector(
                    onTap: _leaveRoom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.call_end_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('Leave', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            // ── Participants ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    // Speakers label
                    Row(
                      children: [
                        const Icon(Icons.mic_rounded, size: 13, color: Colors.white60),
                        const SizedBox(width: 6),
                        Text('SPEAKERS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                            color: Colors.white60, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Grid
                    _buildSpeakersGrid(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Bottom Controls ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Invite
                        _ControlBtn(
                          icon: Icons.person_add_outlined,
                          label: 'Invite',
                          onTap: () => context.push('/add-friends'),
                        ),

                        // MIC — hero button
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isMuted = !_isMuted),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: _isMuted ? Colors.white.withValues(alpha: 0.1) : AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: _isMuted ? [] : [
                                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 14, spreadRadius: 2),
                                  ],
                                ),
                                child: Icon(
                                  _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(_isMuted ? 'Unmute' : 'Mute',
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
                                    color: Colors.white, letterSpacing: 0.5)),
                          ],
                        ),

                        // Speaker
                        _ControlBtn(
                          icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          label: 'Speaker',
                          isActive: _isSpeakerOn,
                          onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                        ),

                        // Settings/Menu button
                        _ControlBtn(
                          icon: Icons.tune_rounded,
                          label: 'Settings',
                          onTap: _showMenu,
                        ),
                      ],
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

  Widget _buildSpeakersGrid() {
    final speakers = [
      const _Participant('Alex', Color(0xFF6366F1), true, false, 'Host'),
      const _Participant('Jordan', Color(0xFFEC4899), false, false, 'Speaker'),
      const _Participant('Taylor', Color(0xFF14B8A6), false, false, 'Speaker'),
      const _Participant('Morgan', Color(0xFFF59E0B), false, false, 'Speaker'),
      const _Participant('Sam', Color(0xFF94A3B8), false, true, 'Speaker'),
      const _Participant('You', AppColors.primary, false, false, 'Speaker'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: speakers.length,
      itemBuilder: (ctx, i) {
        final p = speakers[i];
        final isMe = p.name == 'You';
        return GestureDetector(
          onTap: isMe ? null : () => _showParticipantMenu(ctx, p, true),
          child: _ParticipantCard(participant: p, isMe: isMe)
              .animate(delay: Duration(milliseconds: i * 60))
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.8, 0.8)),
        );
      },
    );
  }
}

// ── Data ──
class _Participant {
  final String name;
  final Color color;
  final bool isSpeaking;
  final bool isMuted;
  final String role;
  const _Participant(this.name, this.color, this.isSpeaking, this.isMuted, this.role);
}

// ── Participant Card ──
class _ParticipantCard extends StatelessWidget {
  final _Participant participant;
  final bool isMe;

  const _ParticipantCard({required this.participant, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (participant.isSpeaking)
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.04, 1.04), duration: 700.ms),

            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: participant.isMuted ? participant.color.withValues(alpha: 0.4) : participant.color,
                border: isMe ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2) : null,
              ),
              child: Center(
                child: Text(participant.name[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
              ),
            ),

            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: participant.isMuted ? Colors.white.withValues(alpha: 0.2) :
                    participant.isSpeaking ? AppColors.primary : Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Icon(
                  participant.isMuted ? Icons.mic_off_rounded :
                    participant.isSpeaking ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                  size: 11, color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isMe ? 'You' : participant.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.white),
          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
        ),
        Text(
          isMe ? 'Me' : participant.role,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500,
              color: participant.isSpeaking ? const Color(0xFF93C5FD) : Colors.white54),
        ),
      ],
    );
  }
}

// ── Control Button ──
class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _ControlBtn({required this.icon, required this.label, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? AppColors.primary.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, size: 22, color: isActive ? const Color(0xFF93C5FD) : Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
            color: Colors.white60, letterSpacing: 0.3)),
      ],
    );
  }
}

// ── Menu Item ──
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subLabel;
  final Color iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon, required this.label, this.subLabel,
    required this.iconColor, this.textColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 15,
                color: textColor ?? (isDark ? Colors.white : AppColors.textPrimaryLight))),
            if (subLabel != null)
              Text(subLabel!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryLight)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 18),
        ]),
      ),
    );
  }
}

// ── Slider Row ──
class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool isDark;

  const _SliderRow({
    required this.icon, required this.label,
    required this.value, required this.onChanged, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          Text('${(value * 100).round()}%',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: isDark ? AppColors.borderDark : AppColors.borderLight,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.15),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(value: value, onChanged: onChanged),
        ),
      ])),
    ]);
  }
}
