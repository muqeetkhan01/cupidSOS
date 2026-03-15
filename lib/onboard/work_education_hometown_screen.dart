import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

class WorkEducationHometownScreen extends StatefulWidget {
  const WorkEducationHometownScreen({super.key});

  @override
  State<WorkEducationHometownScreen> createState() =>
      _WorkEducationHometownScreenState();
}

class _WorkEducationHometownScreenState
    extends State<WorkEducationHometownScreen> with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();
  late final AnimationController _controller;

  final workPlaceCtrl = TextEditingController();
  final workRoleCtrl = TextEditingController();
  final schoolCtrl = TextEditingController();
  final hometownCtrl = TextEditingController();

  String? educationLevel;

  final educationLevels = const [
    "Ph.D. or higher",
    "Master’s Degree",
    "Bachelor’s Degree",
    "Apprenticeship / Trade School",
    "High School Diploma",
    "Some High School",
    "Prefer not to say",
  ];

  bool get isValid =>
      workPlaceCtrl.text.trim().isNotEmpty &&
      workRoleCtrl.text.trim().isNotEmpty &&
      educationLevel != null &&
      educationLevel!.trim().isNotEmpty &&
      hometownCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    workPlaceCtrl.text = flow.workPlace.value ?? "";
    workRoleCtrl.text = flow.workRole.value ?? "";
    schoolCtrl.text = flow.educationSchool.value ?? "";
    hometownCtrl.text = flow.hometown.value ?? "";
    educationLevel = flow.educationLevel.value;

    for (final c in [workPlaceCtrl, workRoleCtrl, schoolCtrl, hometownCtrl]) {
      c.addListener(() => setState(() {}));
    }

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
    workPlaceCtrl.dispose();
    workRoleCtrl.dispose();
    schoolCtrl.dispose();
    hometownCtrl.dispose();
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
          offset: Offset(0, (1 - anim.value) * 28),
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
                    value: 8 / 11,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFFFD6DE),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3B7A)),
                  ),
                ),
              ),
              SizedBox(height: 0.8.h),
              const TextWidget(
                text: '9 of 11',
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: label.toUpperCase(),
          size: 12,
          weight: FontWeight.w600,
          color: Colors.grey,
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.1.h),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _levelChip(String text) {
    final selected = educationLevel == text;
    return GestureDetector(
      onTap: () => setState(() => educationLevel = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFECEF) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFFF6F7D) : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: TextWidget(
          text: text,
          weight: FontWeight.w600,
          color: selected ? const Color(0xFFFF6F7D) : const Color(0xFF1E1E1E),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    if (!isValid) return;

    flow.workPlace.value = workPlaceCtrl.text.trim();
    flow.workRole.value = workRoleCtrl.text.trim();
    flow.educationSchool.value =
        schoolCtrl.text.trim().isEmpty ? null : schoolCtrl.text.trim();
    flow.educationLevel.value = educationLevel;
    flow.hometown.value = hometownCtrl.text.trim();

    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PreferencesScreen()),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 1.h),
              _animated(_header(context), 0, 0.15),
              SizedBox(height: 3.h),
              _animated(
                TextWidget(
                  text: 'Work & Career 💼',
                  size: 18.sp,
                  weight: FontWeight.w600,
                ),
                0.15,
                0.25,
              ),
              SizedBox(height: 0.7.h),
              _animated(
                const TextWidget(
                  text:
                      "Your work is part of your story. Sharing it helps create more meaningful connections.",
                  size: 15,
                  color: Colors.grey,
                ),
                0.2,
                0.3,
              ),
              SizedBox(height: 2.h),
              _animated(
                _field(
                  label: "Where do you work?",
                  hint: "Company / Workplace",
                  controller: workPlaceCtrl,
                ),
                0.25,
                0.45,
              ),
              SizedBox(height: 1.6.h),
              _animated(
                _field(
                  label: "What’s your role?",
                  hint: "Your role / title",
                  controller: workRoleCtrl,
                ),
                0.3,
                0.5,
              ),
              SizedBox(height: 3.2.h),
              _animated(
                TextWidget(
                  text: 'Education 🎓',
                  size: 18.sp,
                  weight: FontWeight.w600,
                ),
                0.35,
                0.5,
              ),
              SizedBox(height: 0.7.h),
              _animated(
                const TextWidget(
                  text:
                      "Degrees don’t define you, but they can be a great conversation starter.",
                  size: 15,
                  color: Colors.grey,
                ),
                0.4,
                0.55,
              ),
              SizedBox(height: 2.h),
              _animated(
                _field(
                  label: "School (optional)",
                  hint: "UCLA, Stanford, Trade School...",
                  controller: schoolCtrl,
                ),
                0.45,
                0.65,
              ),
              SizedBox(height: 1.6.h),
              _animated(
                const TextWidget(
                  text: "EDUCATION LEVEL — SELECT ONE",
                  size: 12,
                  weight: FontWeight.w600,
                  color: Colors.grey,
                ),
                0.48,
                0.7,
              ),
              SizedBox(height: 1.2.h),
              _animated(
                Wrap(
                  spacing: 3.w,
                  runSpacing: 1.2.h,
                  children: educationLevels.map(_levelChip).toList(),
                ),
                0.52,
                0.78,
              ),
              SizedBox(height: 3.2.h),
              _animated(
                TextWidget(
                  text: 'Hometown 🌍',
                  size: 18.sp,
                  weight: FontWeight.w600,
                ),
                0.6,
                0.8,
              ),
              SizedBox(height: 0.7.h),
              _animated(
                const TextWidget(
                  text:
                      "It’s a small detail that can lead to more meaningful connections.",
                  size: 15,
                  color: Colors.grey,
                ),
                0.65,
                0.85,
              ),
              SizedBox(height: 2.h),
              _animated(
                _field(
                  label: "Type your hometown",
                  hint: "Phnom Penh, Bangkok, Los Angeles...",
                  controller: hometownCtrl,
                ),
                0.7,
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
                0.75,
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
