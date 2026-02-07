import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/map.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

enum EthnicityFlowStep { ethnicity, datingGoal, sexuality }

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

  EthnicityFlowStep step = EthnicityFlowStep.ethnicity;
  String? selected;

  final ethnicityOptions = [
    "East Asian",
    "Southeast Asian",
    "South Asian",
    "White/Caucasian",
    "Black/African Descent",
    "Hispanic/Latino",
    "Middle Eastern",
    "Pacific Islander",
    "American Indian",
    "Other",
  ];

  final datingGoalOptions = [
    "Long-term",
    "Casual",
    "Friends",
    "Prefer not to say",
  ];

  final sexualityOptions = [
    "Straight",
    "Bisexual",
    "Asexual",
    "Demisexual",
    "Queer",
    "Gay",
    "Lesbian",
    "Prefer not to say",
  ];

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

    // Resume: go to first missing field + preselect saved value
    if (flow.ethnicity.value == null || flow.ethnicity.value!.isEmpty) {
      step = EthnicityFlowStep.ethnicity;
      selected = flow.ethnicity.value;
    } else if (flow.datingGoal.value == null ||
        flow.datingGoal.value!.isEmpty) {
      step = EthnicityFlowStep.datingGoal;
      selected = flow.datingGoal.value;
    } else {
      step = EthnicityFlowStep.sexuality;
      selected = flow.sexuality.value;
    }
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
          offset: Offset(0, (1 - anim.value) * 28),
          child: child,
        ),
      ),
    );
  }

  Widget _topHeader(BuildContext context) {
    int stepIndex = step == EthnicityFlowStep.ethnicity
        ? 6
        : step == EthnicityFlowStep.datingGoal
            ? 7
            : 8;

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
                    value: stepIndex / 10,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFFFD6DE),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFFFF3B7A),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 0.8.h),
              TextWidget(
                text: '$stepIndex of 10',
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get questionText {
    switch (step) {
      case EthnicityFlowStep.ethnicity:
        return "What is your ethnicity?";
      case EthnicityFlowStep.datingGoal:
        return "Who are you looking to meet?";
      case EthnicityFlowStep.sexuality:
        return "What’s your sexuality?";
    }
  }

  List<String> get options {
    switch (step) {
      case EthnicityFlowStep.ethnicity:
        return ethnicityOptions;
      case EthnicityFlowStep.datingGoal:
        return datingGoalOptions;
      case EthnicityFlowStep.sexuality:
        return sexualityOptions;
    }
  }

  Widget _optionCard(String text) {
    final isSelected = selected == text;

    return GestureDetector(
      onTap: () => setState(() => selected = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.2.h),
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD86BCF).withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: TextWidget(
          text: text,
          size: 15,
          weight: FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    final v = selected;
    if (v == null) return;

    if (step == EthnicityFlowStep.ethnicity) {
      flow.ethnicity.value = v;
    } else if (step == EthnicityFlowStep.datingGoal) {
      flow.datingGoal.value = v;
    } else {
      flow.sexuality.value = v;
    }

    await flow.saveOnboardingProgress();

    if (!mounted) return;

    setState(() {
      selected = null;

      if (step == EthnicityFlowStep.ethnicity) {
        step = EthnicityFlowStep.datingGoal;
        selected = flow.datingGoal.value;
      } else if (step == EthnicityFlowStep.datingGoal) {
        step = EthnicityFlowStep.sexuality;
        selected = flow.sexuality.value;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LocationQuestionScreen(),
          ),
        );
      }
    });
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
                const TextWidget(
                  text: 'COMPATIBILITY QUIZ',
                  size: 13,
                  weight: FontWeight.w700,
                  color: Color(0xFFFF6F7D),
                ),
                0.15,
                0.3,
              ),
              SizedBox(height: 1.2.h),
              _animated(
                TextWidget(
                  text: questionText,
                  size: 18,
                ),
                0.2,
                0.4,
              ),
              SizedBox(height: 4.h),
              Expanded(
                child: ListView(
                  children: options.map(_optionCard).toList(),
                ),
              ),
              SizedBox(height: 2.h),
              _animated(
                ButtonWidget(
                  text: 'Continue',
                  height: 7,
                  radius: 36,
                  variant: selected != null
                      ? ButtonVariant.gradient
                      : ButtonVariant.solid,
                  gradient: const [
                    Color(0xFFFF6F7D),
                    Color(0xFFD86BCF),
                  ],
                  backgroundColor: Colors.grey.shade300,
                  enableShadow: selected != null,
                  onTap: selected != null ? _onContinue : () {},
                ),
                0.8,
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
