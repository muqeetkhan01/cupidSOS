// lib/screens/profile/profile_screen.dart
import 'package:cupid_app/onboard/cupid_splash_screen.dart';
import 'package:cupid_app/community/community_hub_screen.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/config/theme_controller.dart';
import 'package:cupid_app/profile/edit.dart';
import 'package:cupid_app/profile/safety_center_screen.dart';
import 'package:cupid_app/widgets/subscription_review_dialog.dart';
import 'package:cupid_app/widgets/voice.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../config/flow.dart';
import '../../services/auth_service.dart';
import '../../services/premium_service.dart';
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
  final _premium = PremiumService.instance;

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

  String _tierLabel(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.gold:
        return 'Gold';
      case SubscriptionTier.elite:
        return 'Elite';
      case SubscriptionTier.standard:
        return 'Free';
    }
  }

  String _rushStatus(PremiumSnapshot premium) {
    final until = premium.cupidRushUntil;
    if (until == null || !until.isAfter(DateTime.now())) {
      return premium.cupidRushFreeRemaining > 0
          ? '${premium.cupidRushFreeRemaining} bundled Rush left'
          : '${PremiumService.cupidRushCostCoins} coins per Rush';
    }
    final remaining = until.difference(DateTime.now());
    final minutes = remaining.inMinutes.clamp(1, 30);
    return 'Active for $minutes min';
  }

  Future<void> _activateCupidRush(String uid) async {
    final result = await _premium.activateCupidRush(uid);
    if (!mounted) return;
    if (!result.activated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need ${PremiumService.cupidRushCostCoins} coins to start Cupid Rush.',
          ),
        ),
      );
      return;
    }
    final payment = result.usedBundledRush
        ? 'Used one bundled Cupid Rush.'
        : 'Used ${result.spentCoins} Cupid Coins.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cupid Rush is live for 30 minutes. $payment')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.to.currentUser;
    final name = (flow.displayName.value ?? user?.displayName ?? "").trim();
    final age = _ageFromBirthday(flow.birthday.value);
    final location = simplifyLocationLabel(flow.locationLabel.value);
    final photoUrl = (user?.photoURL ?? "").trim();
    final uid = user?.uid;

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

                if (uid != null) ...[
                  _sectionTitle("Cupid Plans"),
                  SizedBox(height: 1.2.h),
                  StreamBuilder<PremiumSnapshot>(
                    stream: _premium.watch(uid),
                    builder: (context, snap) {
                      final premium = snap.data ??
                          const PremiumSnapshot(
                            tier: SubscriptionTier.standard,
                            coins: 0,
                            sosArrowFreeRemaining: 1,
                            sosCallFreeRemaining: 1,
                            cupidRushFreeRemaining: 0,
                            cupidRushUntil: null,
                          );
                      return _subscriptionCard(uid, premium);
                    },
                  ),
                  SizedBox(height: 2.5.h),
                ],

                /// OPTIONS
                _optionTile(
                  icon: Icons.forum_outlined,
                  title: 'Cupid Community',
                  trailing: 'Audio + Hive',
                  trailingColor: const Color(0xFFFF6F7D),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CommunityHubScreen(),
                      ),
                    );
                  },
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

  Widget _subscriptionCard(String uid, PremiumSnapshot premium) {
    final activeRush = premium.isCupidRushActive;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1DC), Color(0xFFF7E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: CupidColors.shadow(context),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6F7D),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: '${_tierLabel(premium.tier)} Plan',
                      size: 16,
                      weight: FontWeight.w800,
                      color: const Color(0xFF3B2430),
                    ),
                    TextWidget(
                      text:
                          'Gold and Elite are the only paid subscription tiers.',
                      size: 11.8,
                      color: const Color(0xFF7C6470),
                    ),
                  ],
                ),
              ),
              TextWidget(
                text: '${premium.coins} coins',
                size: 12.5,
                weight: FontWeight.w700,
                color: const Color(0xFFFF6F7D),
              ),
            ],
          ),
          SizedBox(height: 1.7.h),
          Row(
            children: [
              Expanded(
                child: _planMiniCard(
                  title: 'Gold',
                  subtitle: 'More visibility',
                  icon: Icons.star_rounded,
                  features: const [
                    'Unlimited likes',
                    'Advanced filters',
                    '1 Cupid Rush / month',
                  ],
                  highlighted: premium.tier == SubscriptionTier.gold,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _planMiniCard(
                  title: 'Elite',
                  subtitle: 'Maximum intent',
                  icon: Icons.diamond_rounded,
                  features: const [
                    'Gold included',
                    'Message before match',
                    '3 Cupid Rush / month',
                  ],
                  highlighted: premium.tier == SubscriptionTier.elite,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.7.h),
          Container(
            padding: EdgeInsets.all(3.5.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  activeRush ? Icons.bolt_rounded : Icons.rocket_launch,
                  color: activeRush
                      ? const Color(0xFFFFA000)
                      : const Color(0xFFFF6F7D),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TextWidget(
                        text: 'Cupid Rush',
                        size: 14,
                        weight: FontWeight.w800,
                        color: Color(0xFF3B2430),
                      ),
                      TextWidget(
                        text:
                            '${_rushStatus(premium)} • Top of local queue for 30 min',
                        size: 11.5,
                        color: const Color(0xFF7C6470),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed:
                      activeRush ? null : () async => _activateCupidRush(uid),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F7D),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(activeRush ? 'Live' : 'Boost'),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showSubscriptionFeaturesSheet(premium),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6F7D),
                side: const BorderSide(color: Color(0xFFFF6F7D)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('See All Features'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planMiniCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> features,
    required bool highlighted,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFFF6F7D)
            : Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? Colors.transparent : const Color(0xFFFFCED6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: highlighted ? Colors.white : const Color(0xFFFF6F7D)),
          SizedBox(height: 0.8.h),
          TextWidget(
            text: title,
            size: 14.5,
            weight: FontWeight.w800,
            color: highlighted ? Colors.white : const Color(0xFF3B2430),
          ),
          TextWidget(
            text: subtitle,
            size: 10.8,
            color: highlighted
                ? Colors.white.withValues(alpha: 0.82)
                : const Color(0xFF7C6470),
          ),
          SizedBox(height: 0.8.h),
          ...features.take(3).map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextWidget(
                    text: '• $feature',
                    size: 10,
                    color: highlighted
                        ? Colors.white.withValues(alpha: 0.92)
                        : const Color(0xFF5F4652),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _showSubscriptionFeaturesSheet(PremiumSnapshot premium) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CupidColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(5.w, 2.2.h, 5.w, 3.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CupidColors.border(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  SizedBox(height: 1.8.h),
                  const TextWidget(
                    text: 'Compare Cupid Plans',
                    size: 20,
                    weight: FontWeight.w800,
                  ),
                  SizedBox(height: 0.6.h),
                  TextWidget(
                    text:
                        'Only Gold and Elite are paid plans. Cupid Rush can also be bought with coins.',
                    size: 13,
                    color: CupidColors.textSecondary(context),
                  ),
                  SizedBox(height: 2.h),
                  _featurePlanCard(
                    title: 'Gold',
                    price: 'Paid plan',
                    icon: Icons.star_rounded,
                    features: const [
                      'Unlimited likes',
                      'Priority placement in Discovery',
                      'Advanced filters',
                      'Cupid Vows premium rooms',
                      '1 bundled Cupid Rush every month',
                    ],
                    current: premium.tier == SubscriptionTier.gold,
                  ),
                  SizedBox(height: 1.2.h),
                  _featurePlanCard(
                    title: 'Elite',
                    price: 'Top plan',
                    icon: Icons.diamond_rounded,
                    features: const [
                      'Everything in Gold',
                      'Message before matching',
                      'Highest-intent profile placement',
                      '3 bundled Cupid Rush boosts every month',
                      'Best for peak evening and weekend exposure',
                    ],
                    current: premium.tier == SubscriptionTier.elite,
                  ),
                  SizedBox(height: 1.2.h),
                  _featureRow(
                    icon: Icons.bolt_rounded,
                    title: 'Cupid Rush',
                    body:
                        'Boosts your profile to the top of the local matching queue for 30 minutes. Costs ${PremiumService.cupidRushCostCoins} Cupid Coins when no bundled Rush is available.',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _featurePlanCard({
    required String title,
    required String price,
    required IconData icon,
    required List<String> features,
    required bool current,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surfaceMuted(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              current ? const Color(0xFFFF6F7D) : CupidColors.border(context),
          width: current ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFF6F7D)),
              SizedBox(width: 2.w),
              Expanded(
                child: TextWidget(
                  text: title,
                  size: 17,
                  weight: FontWeight.w800,
                ),
              ),
              if (current)
                const TextWidget(
                  text: 'Current',
                  size: 12,
                  weight: FontWeight.w800,
                  color: Color(0xFFFF6F7D),
                )
              else
                OutlinedButton(
                  onPressed: () => showSubscriptionReviewDialog(context),
                  child: const Text('Choose'),
                ),
            ],
          ),
          TextWidget(
            text: price,
            size: 12.5,
            color: CupidColors.textSecondary(context),
          ),
          SizedBox(height: 1.h),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle,
                      size: 17, color: Color(0xFFFF6F7D)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextWidget(
                      text: feature,
                      size: 12.8,
                      color: CupidColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surfaceMuted(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CupidColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF6F7D)),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(text: title, size: 14.5, weight: FontWeight.w800),
                const SizedBox(height: 4),
                TextWidget(
                  text: body,
                  size: 12.5,
                  color: CupidColors.textSecondary(context),
                ),
              ],
            ),
          ),
        ],
      ),
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
