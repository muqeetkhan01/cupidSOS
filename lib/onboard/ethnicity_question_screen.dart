import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/onboard/map.dart';
import 'package:cupid_app/onboard/onboarding_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

enum IdentityFlowStep {
  ethnicity,
  languages,
  culturalIdentity,
  personalIdentity,
}

class EthnicityQuestionScreen extends StatefulWidget {
  const EthnicityQuestionScreen({super.key});

  @override
  State<EthnicityQuestionScreen> createState() =>
      _EthnicityQuestionScreenState();
}

class _EthnicityQuestionScreenState extends State<EthnicityQuestionScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();
  late final AnimationController _controller;

  IdentityFlowStep step = IdentityFlowStep.ethnicity;
  String? singleSelection;
  final Set<String> multiSelection = <String>{};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _controller.forward();
    });

    _hydrateStep();
  }

  void _hydrateStep() {
    if ((flow.ethnicity.value ?? '').trim().isEmpty) {
      step = IdentityFlowStep.ethnicity;
      singleSelection = flow.ethnicity.value;
      return;
    }
    if (flow.languagesSpoken.isEmpty) {
      step = IdentityFlowStep.languages;
      multiSelection
        ..clear()
        ..addAll(flow.languagesSpoken);
      return;
    }
    if ((flow.culturalIdentity.value ?? '').trim().isEmpty) {
      step = IdentityFlowStep.culturalIdentity;
      singleSelection = flow.culturalIdentity.value;
      return;
    }
    step = IdentityFlowStep.personalIdentity;
    singleSelection = flow.sexuality.value;
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

  bool get _isValid {
    if (step == IdentityFlowStep.languages) return multiSelection.isNotEmpty;
    return singleSelection != null && singleSelection!.trim().isNotEmpty;
  }

  Widget _header(BuildContext context) {
    final stepIndex = step.index;
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
                    value: (8 + stepIndex) / 19,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFFFD6DE),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3B7A)),
                  ),
                ),
              ),
              SizedBox(height: 0.8.h),
              TextWidget(
                text: '${8 + stepIndex} of 19',
                size: 12,
                color: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _choiceChip(String label) {
    final selected = singleSelection == label;
    return GestureDetector(
      onTap: () => setState(() => singleSelection = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
        decoration: BoxDecoration(
          color: selected
              ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF30212B)
                  : const Color(0xFFFFECEF))
              : CupidColors.surface(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF6F7D)
                : CupidColors.border(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: TextWidget(
          text: label,
          weight: FontWeight.w600,
          color: selected
              ? const Color(0xFFFF6F7D)
              : CupidColors.textPrimary(context),
        ),
      ),
    );
  }

  Widget _multiChip(String label) {
    final selected = multiSelection.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          selected ? multiSelection.remove(label) : multiSelection.add(label);
        });
      },
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
          text: label,
          weight: FontWeight.w600,
          color: selected
              ? const Color(0xFFFF6F7D)
              : CupidColors.textPrimary(context),
        ),
      ),
    );
  }

  String get _title {
    switch (step) {
      case IdentityFlowStep.ethnicity:
        return 'What’s your ethnic background?';
      case IdentityFlowStep.languages:
        return 'Which languages do you speak?';
      case IdentityFlowStep.culturalIdentity:
        return 'How do you identify culturally?';
      case IdentityFlowStep.personalIdentity:
        return 'How do you identify?';
    }
  }

  String get _subtitle {
    switch (step) {
      case IdentityFlowStep.ethnicity:
        return 'Choose what feels most accurate for your profile.';
      case IdentityFlowStep.languages:
        return 'Pick every language you feel comfortable using to connect.';
      case IdentityFlowStep.culturalIdentity:
        return 'Pick what feels most like home. This helps us show your vibe to matches.';
      case IdentityFlowStep.personalIdentity:
        return 'Share only what feels right for you.';
    }
  }

  Widget _content() {
    switch (step) {
      case IdentityFlowStep.ethnicity:
        return Wrap(
          spacing: 3.w,
          runSpacing: 1.4.h,
          children: kEthnicityOptions.map(_choiceChip).toList(),
        );
      case IdentityFlowStep.languages:
        return Wrap(
          spacing: 3.w,
          runSpacing: 1.4.h,
          children: kSpokenLanguageOptions.map(_multiChip).toList(),
        );
      case IdentityFlowStep.culturalIdentity:
        return Wrap(
          spacing: 3.w,
          runSpacing: 1.4.h,
          children: kCulturalIdentityOptions.map(_choiceChip).toList(),
        );
      case IdentityFlowStep.personalIdentity:
        return Wrap(
          spacing: 3.w,
          runSpacing: 1.4.h,
          children: kIdentityOptions.map(_choiceChip).toList(),
        );
    }
  }

  Future<void> _continue() async {
    if (!_isValid) return;

    if (step == IdentityFlowStep.ethnicity) {
      flow.ethnicity.value = singleSelection;
      await flow.saveOnboardingProgress();
      setState(() {
        step = IdentityFlowStep.languages;
        multiSelection
          ..clear()
          ..addAll(flow.languagesSpoken);
      });
      return;
    }

    if (step == IdentityFlowStep.languages) {
      flow.languagesSpoken.assignAll(multiSelection.toList());
      await flow.saveOnboardingProgress();
      setState(() {
        step = IdentityFlowStep.culturalIdentity;
        singleSelection = flow.culturalIdentity.value;
      });
      return;
    }

    if (step == IdentityFlowStep.culturalIdentity) {
      flow.culturalIdentity.value = singleSelection;
      await flow.saveOnboardingProgress();
      setState(() {
        step = IdentityFlowStep.personalIdentity;
        singleSelection = flow.sexuality.value;
      });
      return;
    }

    flow.sexuality.value = singleSelection;
    await flow.saveOnboardingProgress();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationQuestionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 1.h),
              _animated(_header(context), 0, 0.15),
              SizedBox(height: 3.h),
              _animated(
                TextWidget(text: _title, size: 18.sp, weight: FontWeight.w500),
                0.15,
                0.3,
              ),
              SizedBox(height: 0.8.h),
              _animated(
                TextWidget(
                  text: _subtitle,
                  size: 15,
                  color: CupidColors.textSecondary(context),
                ),
                0.2,
                0.35,
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: SingleChildScrollView(
                  child: _animated(_content(), 0.35, 0.85),
                ),
              ),
              SizedBox(height: 2.h),
              _animated(
                ButtonWidget(
                  text: step == IdentityFlowStep.personalIdentity
                      ? 'Continue'
                      : 'Next',
                  height: 7,
                  radius: 36,
                  variant:
                      _isValid ? ButtonVariant.gradient : ButtonVariant.solid,
                  gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                  backgroundColor: CupidColors.border(context),
                  enableShadow: _isValid,
                  onTap: _isValid ? _continue : () {},
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
