// lib/screens/profile/profile_screen.dart
import 'package:cupid_app/onboard/cupid_splash_screen.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/config/theme_controller.dart';
import 'package:cupid_app/profile/edit.dart';
import 'package:cupid_app/profile/safety_center_screen.dart';
import 'package:cupid_app/widgets/voice.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../config/flow.dart';
import '../../services/auth_service.dart';
import '../../services/profile_display.dart';
import '../../widgets/text_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final flow = Get.find<AppFlowController>();
  final theme = Get.find<ThemeController>();

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CupidColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 3.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextWidget(
                text: 'Settings',
                size: 18,
                weight: FontWeight.w700,
              ),
              SizedBox(height: 2.h),
              Obx(
                () => Row(
                  children: [
                    Icon(
                      theme.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: CupidColors.textPrimary(sheetContext),
                    ),
                    SizedBox(width: 3.w),
                    const Expanded(
                      child: TextWidget(
                        text: 'Dark Mode',
                        size: 15,
                        weight: FontWeight.w600,
                      ),
                    ),
                    Switch.adaptive(
                      value: theme.isDarkMode,
                      onChanged: (value) {
                        theme.toggleDark(value);
                        Get.back();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 1.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.edit_outlined,
                  color: CupidColors.textPrimary(sheetContext),
                ),
                title: const TextWidget(
                  text: 'Edit Profile',
                  size: 15,
                  weight: FontWeight.w600,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ).then((_) => _refresh());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await flow.hydrateFromFirestore();
    if (mounted) setState(() {});
  }

  int? _ageFromBirthday(DateTime? birthday) {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday.year;
    final hadBirthdayThisYear = (now.month > birthday.month) ||
        (now.month == birthday.month && now.day >= birthday.day);
    if (!hadBirthdayThisYear) age -= 1;
    if (age < 0 || age > 120) return null;
    return age;
  }

  String _heightPretty(double? cm) {
    if (cm == null) return "";
    final inches = (cm / 2.54).round();
    final feet = inches ~/ 12;
    final inch = inches % 12;
    return "$feet'$inch\" • ${cm.round()} cm";
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.to.currentUser;
    final name = (flow.displayName.value ?? user?.displayName ?? "").trim();
    final age = _ageFromBirthday(flow.birthday.value);
    final location = (flow.locationLabel.value ?? "").trim();
    final photoUrl = (user?.photoURL ?? "").trim();

    final headlineParts = <String>[
      if (visibleProfileValue(flow.gender.value).isNotEmpty)
        visibleProfileValue(flow.gender.value),
      if (flow.heightCm.value != null) _heightPretty(flow.heightCm.value),
      if (visibleProfileValue(flow.ethnicity.value).isNotEmpty)
        visibleProfileValue(flow.ethnicity.value),
      if (visibleProfileValue(flow.datingGoal.value).isNotEmpty)
        "Goal: ${visibleProfileValue(flow.datingGoal.value)}",
      if (visibleProfileValue(flow.sexuality.value).isNotEmpty)
        visibleProfileValue(flow.sexuality.value),
    ];

    final storyPhotos = flow.storyPhotoUrls.toList();

    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const TextWidget(
                      text: 'Profile',
                      size: 20,
                      weight: FontWeight.bold,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: _openSettingsSheet,
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                /// HERO CARD
                _profileCard(
                  name: name.isEmpty ? "Unnamed" : name,
                  age: age,
                  location: location.isEmpty ? "Location not set" : location,
                  photoUrl: photoUrl.isEmpty ? null : photoUrl,
                  onEditPhoto: () async {
                    // In your app, you likely have a "change profile photo" flow.
                    // This is a placeholder tile tap; main edit screen handles photo uploads.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ).then((_) => _refresh());
                  },
                ),

                SizedBox(height: 2.h),

                /// QUICK INFO
                if (headlineParts.isNotEmpty) ...[
                  _sectionTitle("About"),
                  SizedBox(height: 1.2.h),
                  _infoCard(headlineParts),
                  SizedBox(height: 2.5.h),
                ],

                /// STORY / PROMPTS
                _sectionTitle("Prompts"),
                SizedBox(height: 1.2.h),
                _promptCard(
                  title: "Cultural quirk",
                  value: (flow.quirkText.value ?? "").trim(),
                ),
                SizedBox(height: 1.2.h),
                _promptCardWithAudio(
                  title: "Voice prompt",
                  value: (flow.voicePromptText.value ?? "").trim(),
                  audioPathOrUrl: (flow.voiceNotePath.value ?? "").trim(),
                ),
                SizedBox(height: 2.5.h),

                /// PHOTOS
                _sectionTitle("Photos"),
                SizedBox(height: 1.2.h),
                _photosGrid(storyPhotos),
                SizedBox(height: 2.5.h),

                /// INTERESTS (from your persisted preferences tags if present)
                _sectionTitle("My Interests"),
                SizedBox(height: 1.2.h),
                _interestChips(_deriveInterests(flow.interests)),
                SizedBox(height: 2.5.h),

                /// OPTIONS
                _optionTile(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Upgrade to Gold',
                  trailing: '2× visibility',
                  trailingColor: const Color(0xFFFF6F7D),
                  onTap: () {},
                ),
                _optionTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ).then((_) => _refresh());
                  },
                ),
                _optionTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Verification',
                  trailing: 'Get verified',
                  trailingColor: const Color(0xFFFF6F7D),
                  onTap: () {},
                ),
                _optionTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SafetyCenterScreen(),
                      ),
                    );
                  },
                ),
                Obx(
                  () => _optionTile(
                    icon: theme.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: 'Dark Mode',
                    trailingWidget: Switch.adaptive(
                      value: theme.isDarkMode,
                      onChanged: (value) {
                        theme.toggleDark(value);
                      },
                    ),
                    hideChevron: true,
                    onTap: () {
                      theme.toggleDark(!theme.isDarkMode);
                    },
                  ),
                ),
                _optionTile(
                  icon: Icons.logout,
                  title: 'Log out',
                  onTap: () async {
                    await flow.logout();
                    if (!context.mounted) return;
                    Get.offAll(CupidSplashScreen());
                    // Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),

                SizedBox(height: 5.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _deriveInterests(List<String> raw) {
    // Your app uses "preferences" inconsistently. This tries to extract readable tags.
    final cleaned = <String>[];
    for (final s in raw) {
      final t = s.trim();
      if (t.isEmpty) continue;
      if (t.startsWith("ethnicity:")) continue;
      if (t.startsWith("language:")) continue;
      cleaned.add(t);
    }
    return cleaned.isEmpty ? ["Add interests in Edit Profile"] : cleaned;
  }

  Widget _sectionTitle(String text) {
    return TextWidget(
      text: text,
      size: 16,
      weight: FontWeight.w600,
    );
  }

  Widget _infoCard(List<String> items) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: CupidColors.shadow(context),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items
            .map(
              (e) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF30212B)
                      : const Color(0xFFFFECEF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextWidget(
                  text: e,
                  size: 14,
                  color: const Color(0xFFFF6F7D),
                  weight: FontWeight.w500,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _promptCardWithAudio({
    required String title,
    required String value,
    required String audioPathOrUrl,
  }) {
    final shown = value.isEmpty ? "Not set" : value;
    final hasAudio = audioPathOrUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CupidColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: title,
            size: 13,
            color: CupidColors.textSecondary(context),
            weight: FontWeight.w600,
          ),
          SizedBox(height: 0.8.h),
          TextWidget(
            text: shown,
            size: 15,
            weight: FontWeight.w500,
          ),
          if (hasAudio) ...[
            SizedBox(height: 1.6.h),
            VoiceNotePlayer(source: audioPathOrUrl),
          ] else ...[
            SizedBox(height: 1.2.h),
            TextWidget(
              text: "No voice note recorded",
              size: 13,
              color: CupidColors.textSecondary(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _promptCard({required String title, required String value}) {
    final shown = value.isEmpty ? "Not set" : value;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CupidColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: title,
            size: 13,
            color: CupidColors.textSecondary(context),
            weight: FontWeight.w600,
          ),
          SizedBox(height: 0.8.h),
          TextWidget(
            text: shown,
            size: 15,
            weight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _photosGrid(List<String> urls) {
    if (urls.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: CupidColors.surface(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: CupidColors.border(context)),
        ),
        child: TextWidget(
          text: "No photos yet. Add them in Edit Profile.",
          size: 14,
          color: CupidColors.textSecondary(context),
        ),
      );
    }

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
                  child: const CircularProgressIndicator(),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _interestChips(List<String> items) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF30212B)
                    : const Color(0xFFFFECEF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextWidget(
                text: e,
                size: 14,
                color: const Color(0xFFFF6F7D),
                weight: FontWeight.w500,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _profileCard({
    required String name,
    required int? age,
    required String location,
    required String? photoUrl,
    required VoidCallback onEditPhoto,
  }) {
    final title = age == null ? name : "$name, $age";

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: CupidColors.shadow(context),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: CupidColors.surfaceMuted(context),
                backgroundImage:
                    photoUrl == null ? null : NetworkImage(photoUrl),
                child: photoUrl == null
                    ? const Icon(Icons.person, size: 34, color: Colors.white)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: onEditPhoto,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF6F7D),
                    ),
                    child:
                        const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: title,
                  size: 18,
                  weight: FontWeight.w600,
                ),
                SizedBox(height: 0.6.h),
                TextWidget(
                  text: location,
                  size: 14,
                  color: CupidColors.textSecondary(context),
                  weight: FontWeight.w500,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ).then((_) => _refresh());
            },
          )
        ],
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    String? trailing,
    Color? trailingColor,
    Widget? trailingWidget,
    bool hideChevron = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.6.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.3.h),
          decoration: BoxDecoration(
            color: CupidColors.surface(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: CupidColors.shadow(context),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: CupidColors.surfaceMuted(context),
                child: Icon(icon,
                    color: CupidColors.textPrimary(context), size: 24),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: TextWidget(
                  text: title,
                  size: 15,
                  weight: FontWeight.w600,
                ),
              ),
              if (trailing != null)
                TextWidget(
                  text: trailing,
                  size: 13,
                  color: trailingColor ?? CupidColors.textSecondary(context),
                  weight: FontWeight.w600,
                ),
              if (trailingWidget != null) trailingWidget,
              if (!hideChevron) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
