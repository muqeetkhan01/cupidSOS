import 'package:cupid_app/Discover/discover_screen.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/services/auth_service.dart';
import 'package:cupid_app/services/profile_display.dart';
import 'package:cupid_app/profile/safety_center_screen.dart';
import 'package:cupid_app/widgets/voice.dart';
import 'package:cupid_app/widgets/safety_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/text_widget.dart';

class UserProfileScreen extends StatefulWidget {
  final DiscoverUser user;
  final String match;

  const UserProfileScreen({
    super.key,
    required this.user,
    required this.match,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // lib/screens/user/user_profile_screen.dart
// Add these methods INSIDE _UserProfileScreenState (same class where _aboutCard/_promptCard exist)

  Widget _infoRow(
      {required String label, required String value, String? emoji}) {
    final v = value.trim();
    if (v.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (emoji != null) ...[
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 26.w,
            child: TextWidget(
              text: label,
              size: 12.5,
              color: CupidColors.textSecondary(context),
              weight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: TextWidget(
              text: v,
              size: 14.5,
              weight: FontWeight.w700,
              color: CupidColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard({required List<Widget> children}) {
    final visible = children.where((w) => w is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CupidColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: visible,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final hero = u.heroImageUrl;
    final myUid = AuthService.to.currentUser?.uid;

    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      body: Stack(
        children: [
          /// Scroll content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: CupidColors.scaffold(context),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (myUid != null)
                    SafetyMenuButton(
                      currentUid: myUid,
                      targetUid: u.uid,
                      showUnmatch: false,
                      onOpenSafetyCenter: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SafetyCenterScreen(),
                          ),
                        );
                      },
                    ),
                ],
                expandedHeight: 52.h,
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroHeader(
                    imageUrl: hero,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _identityCard(
                        title: u.displayTitle,
                        location: simplifyLocationLabel(u.locationLabel),
                        match: widget.match,
                        tags: u.tags,
                      ),
                      SizedBox(height: 2.2.h),

                      /// About
                      _sectionTitle("About"),
                      SizedBox(height: 1.2.h),
                      _aboutCard(
                        u.bioText.isEmpty
                            ? "No bio yet. You can ask them about their vibe 😉"
                            : u.bioText,
                      ),
                      SizedBox(height: 2.2.h),

                      /// Work & Education (NEW)
                      _sectionTitle("Work & Education"),
                      SizedBox(height: 1.2.h),
                      _detailsCard(
                        children: [
                          _infoRow(
                            emoji: "💼",
                            label: "Work",
                            value: [
                              u.workRole.trim(),
                              u.workPlace.trim(),
                            ].where((s) => s.isNotEmpty).join(" • "),
                          ),
                          _infoRow(
                            emoji: "🎓",
                            label: "Education",
                            value: [
                              u.educationLevel.trim(),
                              u.educationSchool.trim(),
                            ].where((s) => s.isNotEmpty).join("\n"),
                          ),
                          _infoRow(
                            emoji: "🌍",
                            label: "Hometown",
                            value: u.hometown,
                          ),
                        ],
                      ),
                      SizedBox(height: 2.2.h),

                      /// Prompts (if you want to show these from user model)
                      _sectionTitle("Prompts"),
                      SizedBox(height: 1.2.h),

                      _promptCard(
                        title: "Cultural quirk",
                        value: u.quirkText.isEmpty ? "Not set" : u.quirkText,
                      ),
                      SizedBox(height: 1.2.h),

                      _voicePromptCard(
                        promptText: u.voicePromptText,
                        audioUrl: u.voiceNoteUrl,
                      ),

                      SizedBox(height: 1.2.h),

                      _promptCard(
                        title: "Story",
                        value: u.storyText.isEmpty ? "Not set" : u.storyText,
                      ),

                      SizedBox(height: 2.2.h),

                      /// Photos
                      _sectionTitle("Photos"),
                      SizedBox(height: 1.2.h),
                      _photoGrid(
                          u.storyPhotoUrls.isEmpty ? [hero] : u.storyPhotoUrls),

                      SizedBox(height: 12.h), // space for bottom actions
                    ],
                  ),
                ),
              ),
            ],
          ),

          /// Bottom floating actions
          // Positioned(
          //   left: 0,
          //   right: 0,
          //   bottom: 0,
          //   child: _BottomActionsBar(
          //     onReject: () => Navigator.pop(context, "reject"),
          //     onBoost: () => Navigator.pop(context, "boost"),
          //     onLike: () => Navigator.pop(context, "like"),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _identityCard({
    required String title,
    required String location,
    required String match,
    required List<String> tags,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CupidColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextWidget(
                  text: title,
                  size: 20,
                  weight: FontWeight.w800,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6F7D).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TextWidget(
                  text: '$match Match',
                  size: 12.2,
                  weight: FontWeight.w700,
                  color: const Color(0xFFFF6F7D),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          TextWidget(
            text: location.isEmpty ? 'Unknown location' : location,
            size: 13.5,
            color: CupidColors.textSecondary(context),
          ),
          if (tags.isNotEmpty) ...[
            SizedBox(height: 1.2.h),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .take(6)
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: CupidColors.surfaceMuted(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: TextWidget(
                        text: tag,
                        size: 12.2,
                        weight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return TextWidget(
      text: text,
      size: 16,
      weight: FontWeight.w800,
    );
  }

  Widget _voicePromptCard({
    required String promptText,
    required String audioUrl,
  }) {
    final hasPrompt = promptText.trim().isNotEmpty;
    final hasAudio = audioUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CupidColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: "Voice prompt",
            size: 12.5,
            color: CupidColors.textSecondary(context),
            weight: FontWeight.w700,
          ),
          SizedBox(height: 0.8.h),
          TextWidget(
            text: hasPrompt ? promptText : "Not set",
            size: 14.5,
            weight: FontWeight.w600,
            color: CupidColors.textPrimary(context),
          ),
          if (hasAudio) ...[
            SizedBox(height: 1.4.h),
            VoiceNotePlayer(source: audioUrl), // ✅ plays URL (or local path)
          ] else ...[
            SizedBox(height: 1.h),
            TextWidget(
              text: "No voice note available",
              size: 13,
              color: CupidColors.textSecondary(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _aboutCard(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CupidColors.shadow(context),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextWidget(
        text: text,
        size: 14.5,
        color: CupidColors.textPrimary(context),
      ),
    );
  }

  Widget _promptCard({required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CupidColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: title,
            size: 12.5,
            color: CupidColors.textSecondary(context),
            weight: FontWeight.w700,
          ),
          SizedBox(height: 0.8.h),
          TextWidget(
            text: value,
            size: 14.5,
            weight: FontWeight.w600,
            color: CupidColors.textPrimary(context),
          ),
        ],
      ),
    );
  }

  Widget _photoGrid(List<String> urls) {
    return Wrap(
      spacing: 3.w,
      runSpacing: 2.h,
      children: urls.take(6).map((u) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: (100.w - (5.w * 2) - 3.w) / 2,
            height: 22.h,
            child: Image.network(
              u,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: CupidColors.surfaceMuted(context),
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: CupidColors.surfaceMuted(context),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// ----------------------
/// HERO HEADER WIDGET
/// ----------------------
class _HeroHeader extends StatelessWidget {
  final String imageUrl;

  const _HeroHeader({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: CupidColors.surfaceMuted(context),
        alignment: Alignment.center,
        child: const Icon(Icons.person, size: 64),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: CupidColors.surfaceMuted(context),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }
}

/// ----------------------
/// BOTTOM ACTION BAR
/// ----------------------
class _BottomActionsBar extends StatefulWidget {
  final VoidCallback onReject;
  final VoidCallback onBoost;
  final VoidCallback onLike;

  const _BottomActionsBar({
    required this.onReject,
    required this.onBoost,
    required this.onLike,
  });

  @override
  State<_BottomActionsBar> createState() => _BottomActionsBarState();
}

class _BottomActionsBarState extends State<_BottomActionsBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding:
            EdgeInsets.only(left: 8.w, right: 8.w, bottom: 2.h, top: 1.5.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _actionCircle(
              icon: Icons.close,
              color: Colors.redAccent,
              onTap: widget.onReject,
            ),
            ScaleTransition(
              scale: _scale,
              child: _actionCircle(
                icon: Icons.flash_on,
                color: Colors.amber,
                onTap: widget.onBoost,
                big: true,
              ),
            ),
            _actionCircle(
              icon: Icons.favorite,
              color: Colors.pinkAccent,
              onTap: widget.onLike,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool big = false,
  }) {
    final size = big ? 18.w : 15.w;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: big ? 34 : 28),
      ),
    );
  }
}
