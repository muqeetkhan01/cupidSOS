// lib/onboard/birthday_screen.dart
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/vibe_selection_screen.dart';
import 'package:cupid_app/widgets/roldex.dart';
import 'package:cupid_app/widgets/zodiac.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();

  late final AnimationController _controller;

  late DateTime _dob;

  @override
  void initState() {
    super.initState();

    // ✅ Preserve previous behavior: if already saved, show saved DOB
    _dob = flow.birthday.value ?? DateTime(2000, 1, 5);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _ageFromDob(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    final hadBirthdayThisYear = (now.month > dob.month) ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthdayThisYear) age -= 1;
    return age;
  }

  Future<void> _continue() async {
    final dt = _dob;

    // ✅ Same validity guard as before (and common dating-app requirement)
    final age = _ageFromDob(dt);
    if (age < 18 || age > 120) {
      Get.snackbar("Invalid date", "Enter a valid birthday");
      return;
    }

    // ✅ Save exactly like before
    flow.birthday.value = dt;

    // ✅ Compute & store signs immediately (same as your previous code)
    final western = ZodiacUtils.westernZodiac(dt);
    flow.vibeType.value = western.name;
    flow.sunSign.value = western.name;

    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const VibeSelectionScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _animatedItem({
    required Widget child,
    required double start,
    required double end,
  }) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * 28),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final age = _ageFromDob(_dob);

    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 1.5.h),

                // 🔙 Back + Step (kept like your previous screen)
                _animatedItem(
                  start: 0.0,
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
                        text: 'Step 2 10',
                        size: 14,
                        color: null,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 6.h),

                // 📅 Icon (kept)
                _animatedItem(
                  start: 0.15,
                  end: 0.3,
                  child: Container(
                    width: 18.w,
                    height: 18.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD86BCF).withOpacity(0.12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFFD86BCF),
                      size: 34,
                    ),
                  ),
                ),

                SizedBox(height: 4.h),

                _animatedItem(
                  start: 0.3,
                  end: 0.45,
                  child: const TextWidget(
                    text: "When’s your birthday? 🎂",
                    size: 24,
                    weight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 1.2.h),

                _animatedItem(
                  start: 0.45,
                  end: 0.6,
                  child: TextWidget(
                    text:
                        "We’ll unlock your cosmic soul badges\nYour birthday is locked once you set it.",
                    size: 15,
                    color: CupidColors.textSecondary(context),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 4.h),

                // ✅ Rolodex picker (replaces MM/DD/YYYY text fields)
                _animatedItem(
                  start: 0.6,
                  end: 0.78,
                  child: RolodexDobPicker(
                    initialDate: _dob,
                    minYear: 1900,
                    maxYear: DateTime.now().year,
                    height: 24.h,
                    itemExtent: 6.h,
                    backgroundColor: CupidColors.surface(context),
                    highlightColor: const Color(0xFFD86BCF).withOpacity(0.08),
                    textStyle: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD86BCF),
                    ),
                    fadedTextStyle: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: CupidColors.textSecondary(context),
                    ),
                    onChanged: (d) => setState(() => _dob = d),
                  ),
                ),

                SizedBox(height: 2.4.h),

                _animatedItem(
                  start: 0.72,
                  end: 0.88,
                  child: TextWidget(
                    text: "You're $age.",
                    size: 15,
                    color: CupidColors.textSecondary(context),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 4.h),

                // ✅ Same CTA as before + calls _continue()
                _animatedItem(
                  start: 0.78,
                  end: 1.0,
                  child: ButtonWidget(
                    text: '✨ Reveal My Signs',
                    height: 7,
                    radius: 36,
                    variant: ButtonVariant.gradient,
                    gradient: const [
                      Color(0xFFFF6F7D),
                      Color(0xFFD86BCF),
                    ],
                    onTap: _continue,
                  ),
                ),

                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
