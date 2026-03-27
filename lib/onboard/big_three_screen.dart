import 'package:cupid_app/config/flow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';
// 👉 import your next screen
import 'vibe_check_screen.dart';

enum Answer { yes, no }

class BigThreeScreen extends StatefulWidget {
  const BigThreeScreen({super.key});

  @override
  State<BigThreeScreen> createState() => _BigThreeScreenState();
}

class _BigThreeScreenState extends State<BigThreeScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();
  late final AnimationController _pageController;
  late final AnimationController _ctaController;

  Answer? family;
  Answer? marriage;
  Answer? culture;

  bool _ctaAnimated = false;

  bool get isValid => family != null && marriage != null && culture != null;

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _ctaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _pageController.forward();
    });

    family = _fromSaved(flow.familyApprovalImportant.value);
    marriage = _fromSaved(flow.marriageTimelineImportant.value);
    culture = _fromSaved(flow.culturalAlignmentImportant.value);
    if (isValid) {
      _ctaAnimated = true;
      _ctaController.value = 1;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ctaController.dispose();
    super.dispose();
  }

  Answer? _fromSaved(bool? value) {
    if (value == null) return null;
    return value ? Answer.yes : Answer.no;
  }

  Widget _animated({
    required Widget child,
    required double from,
    required double to,
  }) {
    final anim = CurvedAnimation(
      parent: _pageController,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
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

  void _onAnswerChanged() {
    if (isValid && !_ctaAnimated) {
      _ctaAnimated = true;
      _ctaController.forward();
    }
    setState(() {});
  }

  Widget _option({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 5.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                  )
                : null,
            color: selected ? null : Colors.grey.shade200,
          ),
          child: TextWidget(
            text: label,
            size: 15,
            weight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String desc,
    required Answer? value,
    required Function(Answer) onSelect,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFFF6F7D).withOpacity(0.12),
                child: Icon(icon, color: const Color(0xFFFF6F7D)),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: TextWidget(
                  text: title,
                  size: 17,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: const EdgeInsets.only(left: 55.0),
            child: TextWidget(
              text: desc,
              size: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 2.h),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                _option(
                  label: 'Yes 👍',
                  selected: value == Answer.yes,
                  onTap: () {
                    onSelect(Answer.yes);
                    _onAnswerChanged();
                  },
                ),
                SizedBox(width: 2.w),
                _option(
                  label: 'No 👎',
                  selected: value == Answer.no,
                  onTap: () {
                    onSelect(Answer.no);
                    _onAnswerChanged();
                  },
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
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            children: [
              SizedBox(height: 1.5.h),

              _animated(
                from: 0,
                to: 0.15,
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
                      text: '4 of 19',
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.h),

              _animated(
                from: 0.15,
                to: 0.3,
                child: const Column(
                  children: [
                    TextWidget(
                      text: 'The Big 3 💎',
                      size: 22,
                      weight: FontWeight.bold,
                    ),
                    SizedBox(height: 6),
                    TextWidget(
                      text: 'Your non-negotiables for a meaningful match',
                      size: 15,
                      color: Color(0xFF1E1E1E),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.h),

              _animated(
                from: 0.3,
                to: 0.45,
                child: _card(
                  icon: Icons.groups,
                  title: '💍 Family Blessing',
                  desc:
                      "Is your family's approval important when choosing a partner?",
                  value: family,
                  onSelect: (v) => family = v,
                ),
              ),

              SizedBox(height: 3.h),

              _animated(
                from: 0.45,
                to: 0.6,
                child: _card(
                  icon: Icons.favorite_border,
                  title: ' 💍 3-Year Marriage Plan',
                  desc:
                      'Are you looking to settle down within the next 3 years?',
                  value: marriage,
                  onSelect: (v) => marriage = v,
                ),
              ),

              SizedBox(height: 3.h),

              _animated(
                from: 0.6,
                to: 0.75,
                child: _card(
                  icon: Icons.restaurant_menu,
                  title: '🥢 Cultural Alignment',
                  desc:
                      'Is sharing cultural traditions (food, holidays, values) vital?',
                  value: culture,
                  onSelect: (v) => culture = v,
                ),
              ),

              SizedBox(height: 5.h),

              // 🚀 Animated CTA + NAVIGATION
              AnimatedBuilder(
                animation: _ctaController,
                builder: (_, __) {
                  final scale = 1 + (_ctaController.value * 0.04);

                  return Transform.scale(
                    scale: scale,
                    child: ButtonWidget(
                      text: 'Continue ✨',
                      height: 7,
                      radius: 36,
                      variant: isValid
                          ? ButtonVariant.gradient
                          : ButtonVariant.solid,
                      gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                      backgroundColor: Colors.grey.shade300,
                      enableShadow: isValid,
                      onTap: isValid
                          ? () async {
                              flow.familyApprovalImportant.value =
                                  family == Answer.yes;
                              flow.marriageTimelineImportant.value =
                                  marriage == Answer.yes;
                              flow.culturalAlignmentImportant.value =
                                  culture == Answer.yes;
                              await flow.saveOnboardingProgress();
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VibeCheckScreen(),
                                ),
                              );
                            }
                          : () {},
                    ),
                  );
                },
              ),

              SizedBox(height: 3.h),

              TextWidget(
                text: 'These help us find your perfect cultural match',
                size: 14,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }
}
