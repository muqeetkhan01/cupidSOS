import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/height.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

class ReligionQuestionScreen extends StatefulWidget {
  const ReligionQuestionScreen({super.key});

  @override
  State<ReligionQuestionScreen> createState() => _ReligionQuestionScreenState();
}

class _ReligionQuestionScreenState extends State<ReligionQuestionScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();
  late final AnimationController _controller;

  String? selected;

  final List<String> options = const [
    "Buddhism",
    "Christianity",
    "Hinduism",
    "Islam",
    "Judaism",
    "Sikhism",
    "Spiritual",
    "Agnostic",
    "Atheist",
    "Other",
    "Prefer not to say",
  ];

  bool get isValid => selected != null && selected!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    selected = flow.religion.value;
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
          offset: Offset(0, (1 - anim.value) * 26),
          child: child,
        ),
      ),
    );
  }

  Future<void> _continue() async {
    if (!isValid) return;
    flow.religion.value = selected;
    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HeightQuestionScreen()),
    );
  }

  Widget _topHeader(BuildContext context) {
    return SizedBox(
      height: 7.h,
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 62.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 5 / 11,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFFFD6DE),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3B7A)),
                  ),
                ),
              ),
              SizedBox(height: 0.8.h),
              const TextWidget(
                text: '6 of 11',
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionChip(String text) {
    final isSelected = selected == text;
    return GestureDetector(
      onTap: () => setState(() => selected = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.7.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFECEF) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6F7D) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: TextWidget(
          text: text,
          weight: FontWeight.w600,
          color: isSelected ? const Color(0xFFFF6F7D) : const Color(0xFF1E1E1E),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 1.h),
              _animated(_topHeader(context), 0, 0.15),
              SizedBox(height: 3.h),
              _animated(
                TextWidget(
                  text: 'Do you follow any religion?',
                  size: 18.sp,
                  weight: FontWeight.w500,
                ),
                0.15,
                0.3,
              ),
              SizedBox(height: 0.8.h),
              _animated(
                const TextWidget(
                  text:
                      "Totally optional to share — but it can help with compatibility.",
                  size: 15,
                  color: Colors.grey,
                ),
                0.2,
                0.35,
              ),
              SizedBox(height: 3.h),
              _animated(
                Wrap(
                  spacing: 3.w,
                  runSpacing: 1.4.h,
                  children: options.map(_optionChip).toList(),
                ),
                0.35,
                0.9,
              ),
              SizedBox(height: 3.h),
              _animated(
                ButtonWidget(
                  text: 'Next',
                  height: 7,
                  radius: 36,
                  variant:
                      isValid ? ButtonVariant.gradient : ButtonVariant.solid,
                  gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                  backgroundColor: Colors.grey.shade300,
                  enableShadow: isValid,
                  onTap: isValid ? _continue : () {},
                ),
                0.9,
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
