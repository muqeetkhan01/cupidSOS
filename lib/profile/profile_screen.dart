// lib/screens/profile/profile_screen.dart
import 'package:cupid_app/onboard/cupid_splash_screen.dart';
import 'package:cupid_app/profile/edit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../config/flow.dart';
import '../../services/auth_service.dart';
import '../../widgets/text_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final flow = Get.find<AppFlowController>();

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
      if (flow.gender.value != null && flow.gender.value!.trim().isNotEmpty)
        flow.gender.value!.trim(),
      if (flow.heightCm.value != null) _heightPretty(flow.heightCm.value),
      if (flow.ethnicity.value != null &&
          flow.ethnicity.value!.trim().isNotEmpty)
        flow.ethnicity.value!.trim(),
      if (flow.datingGoal.value != null &&
          flow.datingGoal.value!.trim().isNotEmpty)
        "Goal: ${flow.datingGoal.value!.trim()}",
      if (flow.sexuality.value != null &&
          flow.sexuality.value!.trim().isNotEmpty)
        flow.sexuality.value!.trim(),
    ];

    final storyPhotos = flow.storyPhotoUrls.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
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
                      onPressed: () {
                        // TODO: route to settings screen if you have one
                      },
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
                _promptCard(
                  title: "Voice prompt",
                  value: (flow.voicePromptText.value ?? "").trim(),
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
                _interestChips(_deriveInterests(flow.preferences)),
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
                  onTap: () {},
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: const Color(0xFFFFECEF),
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

  Widget _promptCard({required String title, required String value}) {
    final shown = value.isEmpty ? "Not set" : value;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: title,
            size: 13,
            color: Colors.grey.shade600,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextWidget(
          text: "No photos yet. Add them in Edit Profile.",
          size: 14,
          color: Colors.grey.shade700,
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
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Colors.grey.shade100,
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
                color: const Color(0xFFFFECEF),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                backgroundColor: Colors.grey.shade200,
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
                  color: Colors.grey.shade600,
                  weight: FontWeight.w500,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {},
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade100,
                child: Icon(icon, color: Colors.black87, size: 24),
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
                  color: trailingColor ?? Colors.grey,
                  weight: FontWeight.w600,
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
