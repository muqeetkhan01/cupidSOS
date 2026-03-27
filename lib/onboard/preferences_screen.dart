import 'dart:math';

import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/onboarding_options.dart';
import 'package:cupid_app/onboard/quirk_prompt_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();
  late final AnimationController _controller;

  bool datingGoalAny = false;
  String? preferredDatingGoal;

  bool genderAny = false;
  final Set<String> preferredGenders = <String>{};

  bool ageAny = false;
  RangeValues ageRange = const RangeValues(18, 45);

  bool heightAny = false;
  RangeValues heightRangeCm = const RangeValues(160, 190);

  bool distanceAny = false;
  RangeValues distanceRange = const RangeValues(0, 200);

  bool ethnicityAny = false;
  final Set<String> ethnicities = <String>{};

  bool languageAny = false;
  final Set<String> languages = <String>{};

  @override
  void initState() {
    super.initState();

    datingGoalAny = flow.prefDatingGoalAny.value;
    preferredDatingGoal = flow.prefDatingGoal.value;

    genderAny = flow.prefGenderAny.value;
    preferredGenders.addAll(flow.preferredGenders);

    ageAny = flow.prefAgeAny.value;
    ageRange = RangeValues(flow.prefAgeMin.value, flow.prefAgeMax.value);

    heightAny = flow.prefHeightAny.value;
    heightRangeCm = _clampRange(
      RangeValues(
        flow.prefHeightMinCm.value ?? 160,
        flow.prefHeightMaxCm.value ?? 190,
      ),
      min: 140,
      max: 220,
    );

    distanceAny = flow.prefDistanceAny.value;
    distanceRange = _clampRange(
      RangeValues(flow.prefDistanceMinMi.value, flow.prefDistanceMaxMi.value),
      min: 0,
      max: 200,
    );

    ethnicityAny = flow.prefEthnicityAny.value;
    ethnicities.addAll(flow.preferredEthnicities);

    languageAny = flow.prefLanguageAny.value;
    languages.addAll(flow.preferredLanguages);

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

  RangeValues _clampRange(
    RangeValues values, {
    required double min,
    required double max,
  }) {
    final start = values.start.clamp(min, max).toDouble();
    final end = values.end.clamp(min, max).toDouble();
    return start <= end ? RangeValues(start, end) : RangeValues(end, start);
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
                    value: 15 / 19,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFFFD6DE),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3B7A)),
                  ),
                ),
              ),
              SizedBox(height: 0.8.h),
              const TextWidget(
                text: '15 of 19',
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    String title, {
    bool showToggle = false,
    bool toggle = false,
    VoidCallback? onToggle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: TextWidget(text: title, size: 17, weight: FontWeight.w600)),
        if (showToggle)
          GestureDetector(
            onTap: onToggle,
            child: Row(
              children: [
                const TextWidget(
                  text: "Doesn't matter",
                  size: 14,
                  color: Colors.grey,
                ),
                SizedBox(width: 2.w),
                Icon(
                  toggle ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: toggle ? const Color(0xFFFF6F7D) : Colors.grey,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chip(String text, Set<String> selectedSet) {
    final selected = selectedSet.contains(text);
    return GestureDetector(
      onTap: () {
        setState(() {
          selected ? selectedSet.remove(text) : selectedSet.add(text);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)])
              : null,
          color: selected ? null : Colors.white,
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: TextWidget(
          text: text,
          size: 14,
          weight: FontWeight.w500,
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _singleSelectCard(String label, String? selectedValue) {
    final selected = selectedValue == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => preferredDatingGoal = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.8.h),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFECEF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFFFF6F7D) : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: TextWidget(
            text: label,
            textAlign: TextAlign.center,
            weight: FontWeight.w600,
            color: selected ? const Color(0xFFFF6F7D) : Colors.black87,
          ),
        ),
      ),
    );
  }

  String _formatHeight(double cm) {
    final unit = flow.heightUnit.value;
    if (unit == 'cm') return '${cm.round()} cm';
    final totalInches = (cm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet'$inches\"";
  }

  Future<void> _continue() async {
    flow.prefDatingGoalAny.value = datingGoalAny;
    flow.prefDatingGoal.value = datingGoalAny ? null : preferredDatingGoal;

    flow.prefGenderAny.value = genderAny;
    flow.preferredGenders
        .assignAll(genderAny ? <String>[] : preferredGenders.toList());

    flow.prefAgeAny.value = ageAny;
    flow.prefAgeMin.value = ageRange.start;
    flow.prefAgeMax.value = ageRange.end;

    flow.prefHeightAny.value = heightAny;
    flow.prefHeightMinCm.value = heightRangeCm.start;
    flow.prefHeightMaxCm.value = heightRangeCm.end;

    flow.prefDistanceAny.value = distanceAny;
    flow.prefDistanceMinMi.value = distanceRange.start;
    flow.prefDistanceMaxMi.value = distanceRange.end;

    flow.prefEthnicityAny.value = ethnicityAny;
    flow.preferredEthnicities
        .assignAll(ethnicityAny ? <String>[] : ethnicities.toList());

    flow.prefLanguageAny.value = languageAny;
    flow.preferredLanguages
        .assignAll(languageAny ? <String>[] : languages.toList());

    flow.preferences.assignAll([
      ...flow.preferredGenders.map((value) => 'gender:$value'),
      ...flow.preferredEthnicities.map((value) => 'ethnicity:$value'),
      ...flow.preferredLanguages.map((value) => 'language:$value'),
      if ((flow.prefDatingGoal.value ?? '').trim().isNotEmpty)
        'datingGoal:${flow.prefDatingGoal.value}',
    ]);

    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuirkPromptScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeHeight = _clampRange(heightRangeCm, min: 140, max: 220);
    final safeDistance = _clampRange(distanceRange, min: 0, max: 200);
    final safeAge = _clampRange(ageRange, min: 18, max: 80);

    if (safeHeight != heightRangeCm ||
        safeDistance != distanceRange ||
        safeAge != ageRange) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          heightRangeCm = safeHeight;
          distanceRange = safeDistance;
          ageRange = safeAge;
        });
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 1.h),
                    _animated(_topHeader(context), 0, 0.15),
                    SizedBox(height: 3.h),
                    _animated(
                      const TextWidget(
                        text: 'Who are you looking to meet?',
                        size: 22,
                        weight: FontWeight.bold,
                      ),
                      0.15,
                      0.3,
                    ),
                    SizedBox(height: 1.h),
                    _animated(
                      const TextWidget(
                        text:
                            'Set your dating preferences now. You can always fine-tune them later.',
                        color: Colors.grey,
                      ),
                      0.2,
                      0.35,
                    ),
                    SizedBox(height: 4.h),
                    _sectionHeader(
                      'Dating goal',
                      showToggle: true,
                      toggle: datingGoalAny,
                      onToggle: () =>
                          setState(() => datingGoalAny = !datingGoalAny),
                    ),
                    if (!datingGoalAny) ...[
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          _singleSelectCard(
                              kDatingGoalOptions[0], preferredDatingGoal),
                          SizedBox(width: 3.w),
                          _singleSelectCard(
                              kDatingGoalOptions[1], preferredDatingGoal),
                          SizedBox(width: 3.w),
                          _singleSelectCard(
                              kDatingGoalOptions[2], preferredDatingGoal),
                        ],
                      ),
                    ],
                    SizedBox(height: 3.h),
                    _sectionHeader(
                      'Preferred gender',
                      showToggle: true,
                      toggle: genderAny,
                      onToggle: () => setState(() => genderAny = !genderAny),
                    ),
                    if (!genderAny) ...[
                      SizedBox(height: 2.h),
                      Wrap(
                        spacing: 3.w,
                        runSpacing: 2.h,
                        children: kGenderOptions
                            .map((option) => _chip(option, preferredGenders))
                            .toList(),
                      ),
                    ],
                    SizedBox(height: 3.h),
                    _sectionHeader(
                      'Preferred age',
                      showToggle: true,
                      toggle: ageAny,
                      onToggle: () => setState(() => ageAny = !ageAny),
                    ),
                    if (!ageAny) ...[
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFFF6F7D),
                          inactiveTrackColor:
                              const Color(0xFFFF6F7D).withOpacity(0.25),
                          thumbColor: const Color(0xFFFF6F7D),
                          overlayColor:
                              const Color(0xFFFF6F7D).withOpacity(0.12),
                        ),
                        child: RangeSlider(
                          min: 18,
                          max: 80,
                          divisions: 62,
                          values: safeAge,
                          onChanged: (values) =>
                              setState(() => ageRange = values),
                        ),
                      ),
                      Row(
                        children: [
                          TextWidget(text: '${safeAge.start.round()}'),
                          const Spacer(),
                          const TextWidget(text: '–'),
                          const Spacer(),
                          TextWidget(text: '${safeAge.end.round()}'),
                        ],
                      ),
                    ],
                    SizedBox(height: 3.h),
                    _sectionHeader(
                      'Preferred height',
                      showToggle: true,
                      toggle: heightAny,
                      onToggle: () => setState(() => heightAny = !heightAny),
                    ),
                    if (!heightAny) ...[
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFFF6F7D),
                          inactiveTrackColor:
                              const Color(0xFFFF6F7D).withOpacity(0.25),
                          thumbColor: const Color(0xFFFF6F7D),
                          overlayColor:
                              const Color(0xFFFF6F7D).withOpacity(0.12),
                        ),
                        child: RangeSlider(
                          min: 140,
                          max: 220,
                          divisions: 16,
                          values: safeHeight,
                          onChanged: (values) =>
                              setState(() => heightRangeCm = values),
                        ),
                      ),
                      Row(
                        children: [
                          TextWidget(text: _formatHeight(safeHeight.start)),
                          const Spacer(),
                          const TextWidget(text: '–'),
                          const Spacer(),
                          TextWidget(text: _formatHeight(safeHeight.end)),
                        ],
                      ),
                    ],
                    SizedBox(height: 3.h),
                    _sectionHeader(
                      'Preferred distance',
                      showToggle: true,
                      toggle: distanceAny,
                      onToggle: () =>
                          setState(() => distanceAny = !distanceAny),
                    ),
                    if (!distanceAny) ...[
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFFF6F7D),
                          inactiveTrackColor:
                              const Color(0xFFFF6F7D).withOpacity(0.25),
                          thumbColor: const Color(0xFFFF6F7D),
                          overlayColor:
                              const Color(0xFFFF6F7D).withOpacity(0.12),
                        ),
                        child: RangeSlider(
                          min: 0,
                          max: 200,
                          divisions: 20,
                          values: safeDistance,
                          onChanged: (values) =>
                              setState(() => distanceRange = values),
                        ),
                      ),
                      Row(
                        children: [
                          TextWidget(
                              text: '${max(0, safeDistance.start.round())} mi'),
                          const Spacer(),
                          const TextWidget(text: '–'),
                          const Spacer(),
                          TextWidget(
                              text: '${min(200, safeDistance.end.round())} mi'),
                        ],
                      ),
                    ],
                    SizedBox(height: 3.h),
                    _sectionHeader(
                      'Preferred ethnicity',
                      showToggle: true,
                      toggle: ethnicityAny,
                      onToggle: () =>
                          setState(() => ethnicityAny = !ethnicityAny),
                    ),
                    if (!ethnicityAny) ...[
                      SizedBox(height: 2.h),
                      Wrap(
                        spacing: 3.w,
                        runSpacing: 2.h,
                        children: kPreferenceEthnicityOptions
                            .map((option) => _chip(option, ethnicities))
                            .toList(),
                      ),
                    ],
                    SizedBox(height: 4.h),
                    _sectionHeader(
                      'Preferred languages',
                      showToggle: true,
                      toggle: languageAny,
                      onToggle: () =>
                          setState(() => languageAny = !languageAny),
                    ),
                    if (!languageAny) ...[
                      const TextWidget(
                        text:
                            "Select the languages you’re comfortable using to chat, flirt, and connect.",
                        size: 14,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 2.h),
                      Wrap(
                        spacing: 3.w,
                        runSpacing: 2.h,
                        children: kSpokenLanguageOptions
                            .map((option) => _chip(option, languages))
                            .toList(),
                      ),
                    ],
                    SizedBox(height: 6.h),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.5.h),
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
      ),
    );
  }
}
