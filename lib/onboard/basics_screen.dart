import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/height.dart';
import 'package:cupid_app/onboard/onboarding_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

enum Gender { male, female, nonBinary }

class BasicsScreen extends StatefulWidget {
  const BasicsScreen({super.key});

  @override
  State<BasicsScreen> createState() => _BasicsScreenState();
}

class _BasicsScreenState extends State<BasicsScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();
  late final AnimationController _controller;

  final TextEditingController nameCtrl = TextEditingController();
  Gender? gender;

  bool get isValid => nameCtrl.text.trim().isNotEmpty && gender != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    nameCtrl.text = (flow.displayName.value ?? '').trim();
    switch ((flow.gender.value ?? '').trim()) {
      case 'Male':
        gender = Gender.male;
        break;
      case 'Female':
        gender = Gender.female;
        break;
      case 'Non-Binary':
        gender = Gender.nonBinary;
        break;
    }

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _controller.forward();
    });

    nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    nameCtrl.dispose();
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

  Widget _header(BuildContext context) {
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
                    value: 6 / 19,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFFFD6DE),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFFFF3B7A),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 0.8.h),
              const TextWidget(
                text: '6 of 19',
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderChip(Gender value, String label) {
    final selected = gender == value;
    return GestureDetector(
      onTap: () => setState(() => gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 6.5.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? const Color(0xFFFFECEF) : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFFFF6F7D) : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: TextWidget(
          text: label,
          weight: FontWeight.w600,
          color: selected ? const Color(0xFFFF6F7D) : const Color(0xFF1E1E1E),
        ),
      ),
    );
  }

  Widget _inputField({required String hint}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: nameCtrl,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.1.h),
          border: InputBorder.none,
        ),
      ),
    );
  }

  String _genderLabel() {
    switch (gender) {
      case Gender.male:
        return kGenderOptions[0];
      case Gender.female:
        return kGenderOptions[1];
      case Gender.nonBinary:
        return kGenderOptions[2];
      case null:
        return '';
    }
  }

  Future<void> _continue() async {
    if (!isValid) return;
    flow.displayName.value = nameCtrl.text.trim();
    flow.gender.value = _genderLabel();
    await flow.saveOnboardingProgress();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HeightQuestionScreen()),
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
              _animated(_header(context), 0, 0.15),
              SizedBox(height: 2.h),
              _animated(
                TextWidget(
                  text: 'The Basics',
                  size: 18.sp,
                  weight: FontWeight.w500,
                ),
                0.15,
                0.3,
              ),
              SizedBox(height: 0.6.h),
              _animated(
                const TextWidget(
                  text: 'Name and gender help us set up your profile properly.',
                  size: 15,
                  color: Colors.grey,
                ),
                0.2,
                0.35,
              ),
              SizedBox(height: 4.h),
              _animated(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextWidget(
                      text: 'FULL NAME',
                      size: 12,
                      weight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 1.h),
                    _inputField(hint: 'What do friends call you?'),
                    SizedBox(height: .4.h),
                    Padding(
                      padding: EdgeInsets.only(left: 2.w),
                      child: const TextWidget(
                        text:
                            'This is the name others will see on your profile.',
                        size: 12,
                        weight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                0.3,
                0.5,
              ),
              SizedBox(height: 3.h),
              _animated(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextWidget(
                      text: 'GENDER',
                      size: 12,
                      weight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 1.5.h),
                    Row(
                      children: [
                        Expanded(child: _genderChip(Gender.female, 'Female')),
                        SizedBox(width: 3.w),
                        Expanded(child: _genderChip(Gender.male, 'Male')),
                      ],
                    ),
                    SizedBox(height: 1.2.h),
                    SizedBox(
                      width: double.infinity,
                      child: _genderChip(Gender.nonBinary, 'Non-Binary'),
                    ),
                  ],
                ),
                0.6,
                0.85,
              ),
              const Spacer(),
              _animated(
                ButtonWidget(
                  text: 'Next Step',
                  height: 7,
                  radius: 36,
                  variant:
                      isValid ? ButtonVariant.gradient : ButtonVariant.solid,
                  gradient: const [
                    Color(0xFFFF6F7D),
                    Color(0xFFD86BCF),
                  ],
                  backgroundColor: Colors.grey.shade300,
                  enableShadow: isValid,
                  onTap: isValid ? _continue : () {},
                ),
                0.85,
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
