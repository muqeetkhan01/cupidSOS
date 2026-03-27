import 'package:cupid_app/auth/BirthdayScreen.dart';
import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/match_loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

class WelcomeHouseRulesScreen extends StatefulWidget {
  const WelcomeHouseRulesScreen({
    super.key,
    this.isFinalStep = false,
  });

  final bool isFinalStep;

  @override
  State<WelcomeHouseRulesScreen> createState() =>
      _WelcomeHouseRulesScreenState();
}

class _WelcomeHouseRulesScreenState extends State<WelcomeHouseRulesScreen>
    with SingleTickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();
  late final AnimationController _controller;

  final List<_RuleItem> _rules = const [
    _RuleItem(
      title: 'Keep it real.',
      body: 'Make sure your profile reflects who you truly are.',
      icon: Icons.verified_user_outlined,
      accent: Color(0xFFF26573),
    ),
    _RuleItem(
      title: 'Stay safe.',
      body: 'Don’t share personal information too quickly.',
      icon: Icons.shield_outlined,
      accent: Color(0xFFDB7A53),
    ),
    _RuleItem(
      title: 'Lead with kindness.',
      body: 'Treat others with respect.',
      icon: Icons.favorite_border_rounded,
      accent: Color(0xFFE0578C),
    ),
    _RuleItem(
      title: 'Be genuine.',
      body: 'Connect with honesty and real intentions.',
      icon: Icons.forum_outlined,
      accent: Color(0xFF7D6AE6),
    ),
    _RuleItem(
      title: 'Honor connection.',
      body: 'Value culture and meaningful relationships.',
      icon: Icons.diversity_3_outlined,
      accent: Color(0xFF4D8B7A),
    ),
    _RuleItem(
      title: 'Speak up.',
      body: 'Report bad behavior.',
      icon: Icons.flag_outlined,
      accent: Color(0xFF343434),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
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
          offset: Offset(0, (1 - anim.value) * 26),
          child: child,
        ),
      ),
    );
  }

  Future<void> _continue() async {
    if (widget.isFinalStep) {
      flow.finalRulesSeen.value = true;
    } else {
      flow.welcomeSeen.value = true;
    }
    await flow.saveOnboardingProgress();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.isFinalStep
            ? const MatchLoadingScreen()
            : const BirthdayScreen(),
      ),
    );
  }

  String get _stepLabel => widget.isFinalStep ? '20 of 20' : '2 of 19';

  String get _badgeLabel =>
      widget.isFinalStep ? 'Final House Rules' : 'House Rules';

  String get _heroTitle => widget.isFinalStep
      ? 'Before you go live\non Cupid SOS'
      : 'Welcome to\nCupid SOS';

  String get _heroBody => widget.isFinalStep
      ? 'You’re verified. One last reminder before you enter the community for real.'
      : 'Real people. Thoughtful connections.\nLet’s set the tone before we start matching.';

  String get _supportingText => widget.isFinalStep
      ? 'A strong community works when the rules are clear, calm, and easy to remember.'
      : 'A safe, thoughtful space starts with shared standards.';

  String get _ctaText => widget.isFinalStep ? 'Enter Cupid SOS' : 'I’m in';

  Widget _heroCard() {
    final gradient = widget.isFinalStep
        ? const [
            Color(0xFF1E1F2F),
            Color(0xFF51406A),
            Color(0xFFD95C7A),
          ]
        : const [
            Color(0xFFF45E7D),
            Color(0xFFD56391),
            Color(0xFFB96FD1),
          ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.22),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -10,
            child: Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.14),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -16,
            child: Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.5.w,
                      vertical: 0.9.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: TextWidget(
                      text: _badgeLabel,
                      size: 12,
                      color: Colors.white,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 11.w,
                    height: 11.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                    ),
                    child: Icon(
                      widget.isFinalStep
                          ? Icons.shield_moon_outlined
                          : Icons.favorite_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.2.h),
              TextWidget(
                text: _heroTitle,
                size: 19.sp,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
              SizedBox(height: 1.2.h),
              TextWidget(
                text: _heroBody,
                size: 14.5,
                color: Colors.white.withOpacity(0.92),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ruleCard(int index, _RuleItem rule) {
    return Container(
      padding: EdgeInsets.all(4.2.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB96FD1).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 13.w,
            height: 13.w,
            decoration: BoxDecoration(
              color: rule.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(rule.icon, color: rule.accent, size: 22),
          ),
          SizedBox(width: 3.5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8EDF1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: TextWidget(
                        text: '0${index + 1}',
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: rule.accent,
                      ),
                    ),
                    SizedBox(width: 2.5.w),
                    Expanded(
                      child: TextWidget(
                        text: rule.title,
                        size: 15.5,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.8.h),
                TextWidget(
                  text: rule.body,
                  size: 14,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1EE),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.isFinalStep
                ? const [
                    Color(0xFFF7F0F2),
                    Color(0xFFF3EEF7),
                    Color(0xFFF1EFF6),
                  ]
                : const [
                    Color(0xFFFFF4F2),
                    Color(0xFFFDF1F4),
                    Color(0xFFF6EFF8),
                  ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              left: -22,
              child: Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF45E7D).withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              top: 24.h,
              right: -30,
              child: Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFB96FD1).withOpacity(0.07),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _animated(
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.5.w,
                              vertical: 0.9.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: TextWidget(
                              text: _stepLabel,
                              size: 13,
                              color: Colors.black87,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      0,
                      0.12,
                    ),
                    SizedBox(height: 2.2.h),
                    _animated(_heroCard(), 0.12, 0.35),
                    SizedBox(height: 2.2.h),
                    _animated(
                      TextWidget(
                        text: _supportingText,
                        size: 14.5,
                        color: Colors.grey.shade700,
                      ),
                      0.2,
                      0.38,
                    ),
                    SizedBox(height: 2.h),
                    Expanded(
                      child: ClipRect(
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(bottom: 1.h),
                          itemCount: _rules.length,
                          separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
                          itemBuilder: (_, index) =>
                              _ruleCard(index, _rules[index]),
                        ),
                      ),
                    ),
                    SizedBox(height: 1.2.h),
                    _animated(
                      Column(
                        children: [
                          ButtonWidget(
                            text: _ctaText,
                            height: 7,
                            radius: 36,
                            variant: ButtonVariant.gradient,
                            gradient: widget.isFinalStep
                                ? const [
                                    Color(0xFF2B2C40),
                                    Color(0xFFD95C7A),
                                  ]
                                : const [
                                    Color(0xFFFF6F7D),
                                    Color(0xFFD86BCF),
                                  ],
                            enableShadow: true,
                            onTap: _continue,
                          ),
                          SizedBox(height: 1.h),
                          TextWidget(
                            text: widget.isFinalStep
                                ? 'Thoughtful connections start here.'
                                : 'You’re in control. We’ve got your back.',
                            size: 13,
                            color: Colors.grey.shade600,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      0.85,
                      1,
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
}

class _RuleItem {
  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  const _RuleItem({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });
}
