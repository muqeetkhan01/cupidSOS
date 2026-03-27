import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/onboarding_options.dart';
import 'package:cupid_app/onboard/work_education_hometown_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

class LookingForScreen extends StatefulWidget {
  const LookingForScreen({super.key});

  @override
  State<LookingForScreen> createState() => _LookingForScreenState();
}

class _LookingForScreenState extends State<LookingForScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();
  late final AnimationController _controller;
  String? selectedGoal;

  @override
  void initState() {
    super.initState();
    selectedGoal = flow.datingGoal.value;
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

  Widget _animated(Widget child, double from, double to) {
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 24),
          child: child,
        ),
      ),
    );
  }

  Widget _goalCard(String label, IconData icon) {
    final selected = selectedGoal == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedGoal = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFECEF) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? const Color(0xFFFF6F7D) : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 26,
                color: selected ? const Color(0xFFFF6F7D) : Colors.black87,
              ),
              SizedBox(height: 1.2.h),
              TextWidget(
                text: label,
                weight: FontWeight.w600,
                textAlign: TextAlign.center,
                color: selected ? const Color(0xFFFF6F7D) : Colors.black87,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    if (selectedGoal == null || selectedGoal!.trim().isEmpty) return;
    flow.datingGoal.value = selectedGoal;
    await flow.saveOnboardingProgress();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkEducationHometownScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = selectedGoal != null && selectedGoal!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 1.h),
              _animated(
                Stack(
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
                      text: '13 of 19',
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
                0,
                0.15,
              ),
              SizedBox(height: 4.h),
              _animated(
                TextWidget(
                  text: 'What are you looking for?',
                  size: 18.sp,
                  weight: FontWeight.w600,
                ),
                0.15,
                0.3,
              ),
              SizedBox(height: 0.8.h),
              _animated(
                const TextWidget(
                  text:
                      'Tell us what feels right right now so we can guide your matches with more intention.',
                  size: 15,
                  color: Colors.grey,
                ),
                0.2,
                0.35,
              ),
              SizedBox(height: 3.h),
              _animated(
                Row(
                  children: [
                    _goalCard(kDatingGoalOptions[0], Icons.favorite_outline),
                    SizedBox(width: 3.w),
                    _goalCard(kDatingGoalOptions[1],
                        Icons.local_fire_department_outlined),
                    SizedBox(width: 3.w),
                    _goalCard(kDatingGoalOptions[2], Icons.groups_outlined),
                  ],
                ),
                0.3,
                0.65,
              ),
              const Spacer(),
              _animated(
                ButtonWidget(
                  text: 'Continue',
                  height: 7,
                  radius: 36,
                  variant: canContinue
                      ? ButtonVariant.gradient
                      : ButtonVariant.solid,
                  gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                  backgroundColor: Colors.grey.shade300,
                  enableShadow: canContinue,
                  onTap: canContinue ? _continue : () {},
                ),
                0.7,
                1,
              ),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }
}
