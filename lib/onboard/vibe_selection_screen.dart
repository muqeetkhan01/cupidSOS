// lib/onboard/vibe_selection_screen.dart
// Fix: Remove hardcoded Taurus/Tiger and show computed Western + Chinese from birthday.

import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/widgets/zodiac.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';
import 'big_three_screen.dart';

class VibeSelectionScreen extends StatefulWidget {
  const VibeSelectionScreen({super.key});

  @override
  State<VibeSelectionScreen> createState() => _VibeSelectionScreenState();
}

class _VibeSelectionScreenState extends State<VibeSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pageController;
  late final AnimationController _selectController;
  final flow = Get.find<AppFlowController>();

  // Instead of enum, use dynamic selection keys
  String? selectedKey;

  late WesternZodiac _western;
  late ChineseZodiac _chinese;

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    final dob = flow.birthday.value;
    if (dob != null) {
      _western = ZodiacUtils.westernZodiac(dob);
      _chinese = ZodiacUtils.chineseZodiac(dob);

      selectedKey = "western";
      flow.vibeType.value = _western.name;
      flow.sunSign.value = _western.name;

      _selectController.value = 1.0; // ✅ FULLY selected immediately
    }

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _pageController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _selectController.dispose();
    super.dispose();
  }

  Widget _animatedItem({
    required Widget child,
    required double start,
    required double end,
  }) {
    final anim = CurvedAnimation(
      parent: _pageController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 28),
          child: child,
        ),
      ),
    );
  }

  Widget _vibeCard({
    required String keyName,
    required String title,
    required String subtitle,
    required String meta,
    required String emoji,
    required VoidCallback onSelected,
  }) {
    final bool isSelected = selectedKey == keyName;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedKey = keyName;
          _selectController.forward(from: 0);
        });
        onSelected();
      },
      child: AnimatedBuilder(
        animation: _selectController,
        builder: (_, __) {
          final double fill = isSelected ? _selectController.value : 0;

          return Container(
            height: 12.h,
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : CupidColors.border(context),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: FractionallySizedBox(
                        heightFactor: fill,
                        widthFactor: 1,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    child: Row(
                      children: [
                        Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: isSelected
                                ? Colors.white.withOpacity(0.25)
                                : CupidColors.surface(context),
                          ),
                          alignment: Alignment.center,
                          child: Text(emoji, style: TextStyle(fontSize: 26.sp)),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextWidget(
                                text: title,
                                size: 17,
                                weight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : CupidColors.textPrimary(context),
                              ),
                              SizedBox(height: 0.4.h),
                              TextWidget(
                                text: subtitle,
                                size: 14,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : CupidColors.textSecondary(context),
                              ),
                              SizedBox(height: 0.2.h),
                              TextWidget(
                                text: meta,
                                size: 13,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.8)
                                    : CupidColors.textSecondary(context),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF6F7D),
                            ),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 18),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = flow.birthday.value != null;

    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            children: [
              SizedBox(height: 1.5.h),
              _animatedItem(
                start: 0,
                end: 0.15,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const TextWidget(
                      text: 'Step 3 of 10',
                      size: 14,
                      color: null,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6.h),
              _animatedItem(
                start: 0.15,
                end: 0.3,
                child: TextWidget(
                  text: '✨ YOUR COSMIC BADGES ✨',
                  size: 15,
                  color: CupidColors.textSecondary(context),
                ),
              ),
              SizedBox(height: 1.5.h),
              _animatedItem(
                start: 0.3,
                end: 0.45,
                child: TextWidget(
                  text: 'Your signs based on your birthday 🌙',
                  size: 18,
                  weight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 1.h),
              _animatedItem(
                start: 0.45,
                end: 0.55,
                child: TextWidget(
                  text: ready
                      ? 'Pick the badge you want on your profile'
                      : 'Go back and enter your birthday',
                  size: 14,
                  color: CupidColors.textSecondary(context),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 5.h),
              _animatedItem(
                start: 0.55,
                end: 0.75,
                child: Column(
                  children: [
                    _vibeCard(
                      keyName: "western",
                      title: _western.name,
                      subtitle: "Western Zodiac",
                      meta: _western.rangeLabel,
                      emoji: _western.emoji,
                      onSelected: () {
                        flow.vibeType.value = _western.name;
                        flow.sunSign.value = _western.name;
                      },
                    ),
                    _vibeCard(
                      keyName: "chinese",
                      title: _chinese.animal,
                      subtitle: "Chinese Zodiac",
                      meta: "Born in ${_chinese.year}",
                      emoji: _chinese.emoji,
                      onSelected: () {
                        // If you want this as profile badge instead:
                        flow.vibeType.value = _chinese.animal;
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _animatedItem(
                start: 0.75,
                end: 1,
                child: ButtonWidget(
                  text: 'Continue ✨',
                  height: 7,
                  radius: 36,
                  variant: selectedKey != null
                      ? ButtonVariant.gradient
                      : ButtonVariant.solid,
                  gradient: selectedKey != null
                      ? const [Color(0xFFFF6F7D), Color(0xFFD86BCF)]
                      : null,
                  backgroundColor: CupidColors.border(context),
                  enableShadow: selectedKey != null,
                  onTap: selectedKey == null
                      ? () {}
                      : () async {
                          await flow.saveOnboardingProgress();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BigThreeScreen()),
                          );
                        },
                ),
              ),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }
}
