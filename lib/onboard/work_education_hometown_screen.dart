import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/onboard/onboarding_options.dart';
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
  String? religion;

  @override
  void initState() {
    super.initState();

    workPlaceCtrl.text = flow.workPlace.value ?? '';
    workRoleCtrl.text = flow.workRole.value ?? '';
    schoolCtrl.text = flow.educationSchool.value ?? '';
    hometownCtrl.text = flow.hometown.value ?? '';
    educationLevel = flow.educationLevel.value;
    religion = flow.religion.value;

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
                    value: 14 / 19,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFFFD6DE),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3B7A)),
                  ),
                ),
              ),
              SizedBox(height: 0.8.h),
              const TextWidget(
                text: '14 of 19',
                size: 12,
                color: null,
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
          color: CupidColors.textSecondary(context),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: CupidColors.surface(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CupidColors.border(context)),
          ),
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: CupidColors.textSecondary(context)),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.1.h),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.4.h),
        decoration: BoxDecoration(
          color: selected
              ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF30212B)
                  : const Color(0xFFFFECEF))
              : CupidColors.surface(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF6F7D)
                : CupidColors.border(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: TextWidget(
          text: text,
          weight: FontWeight.w600,
          color: selected
              ? const Color(0xFFFF6F7D)
              : CupidColors.textPrimary(context),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    flow.workPlace.value =
        workPlaceCtrl.text.trim().isEmpty ? null : workPlaceCtrl.text.trim();
    flow.workRole.value =
        workRoleCtrl.text.trim().isEmpty ? null : workRoleCtrl.text.trim();
    flow.educationSchool.value =
        schoolCtrl.text.trim().isEmpty ? null : schoolCtrl.text.trim();
    flow.educationLevel.value =
        (educationLevel ?? '').trim().isEmpty ? null : educationLevel;
    flow.hometown.value =
        hometownCtrl.text.trim().isEmpty ? null : hometownCtrl.text.trim();
    flow.religion.value =
        (religion ?? '').trim().isEmpty ? null : religion?.trim();
    flow.workEducationStepDone.value = true;

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
      backgroundColor: CupidColors.scaffold(context),
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
                  text: 'Work, education, hometown, and religion',
                  size: 18.sp,
                  weight: FontWeight.w600,
                ),
                0.15,
                0.3,
              ),
              SizedBox(height: 0.7.h),
              _animated(
                const TextWidget(
                  text:
                      'Everything here is optional. Add what feels useful, or skip straight through.',
                  size: 15,
                  color: null,
                ),
                0.2,
                0.35,
              ),
              SizedBox(height: 2.h),
              _animated(
                _field(
                  label: 'Where do you work?',
                  hint: 'Company / workplace',
                  controller: workPlaceCtrl,
                ),
                0.25,
                0.45,
              ),
              SizedBox(height: 1.6.h),
              _animated(
                _field(
                  label: 'What’s your role?',
                  hint: 'Your role / title',
                  controller: workRoleCtrl,
                ),
                0.3,
                0.5,
              ),
              SizedBox(height: 3.2.h),
              _animated(
                TextWidget(
                  text: 'Education',
                  size: 18.sp,
                  weight: FontWeight.w600,
                ),
                0.35,
                0.5,
              ),
              SizedBox(height: 0.7.h),
              _animated(
                _field(
                  label: 'School',
                  hint: 'UCLA, Stanford, Trade School...',
                  controller: schoolCtrl,
                ),
                0.45,
                0.65,
              ),
              SizedBox(height: 1.2.h),
              _animated(
                Wrap(
                  spacing: 3.w,
                  runSpacing: 1.2.h,
                  children: kEducationLevels
                      .map(
                        (item) => _chip(
                          text: item,
                          selected: educationLevel == item,
                          onTap: () => setState(() => educationLevel = item),
                        ),
                      )
                      .toList(),
                ),
                0.5,
                0.72,
              ),
              SizedBox(height: 3.2.h),
              _animated(
                _field(
                  label: 'Hometown',
                  hint: 'Phnom Penh, Bangkok, Los Angeles...',
                  controller: hometownCtrl,
                ),
                0.55,
                0.76,
              ),
              SizedBox(height: 3.2.h),
              _animated(
                TextWidget(
                  text: 'Religion',
                  size: 18.sp,
                  weight: FontWeight.w600,
                ),
                0.6,
                0.78,
              ),
              SizedBox(height: 1.2.h),
              _animated(
                Wrap(
                  spacing: 3.w,
                  runSpacing: 1.2.h,
                  children: kReligionOptions
                      .map(
                        (item) => _chip(
                          text: item,
                          selected: religion == item,
                          onTap: () => setState(() => religion = item),
                        ),
                      )
                      .toList(),
                ),
                0.65,
                0.88,
              ),
              SizedBox(height: 3.h),
              _animated(
                Row(
                  children: [
                    TextButton(
                      onPressed: _continue,
                      child: const Text('Skip'),
                    ),
                    const Spacer(),
                    Expanded(
                      child: ButtonWidget(
                        text: 'Continue',
                        height: 7,
                        radius: 36,
                        variant: ButtonVariant.gradient,
                        gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                        enableShadow: true,
                        onTap: _continue,
                      ),
                    ),
                  ],
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
