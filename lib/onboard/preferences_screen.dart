import 'package:cupid_app/config/flow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';
import 'quirk_prompt_screen.dart';

import 'dart:math';

import 'package:cupid_app/config/flow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';
import 'quirk_prompt_screen.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();
  late final AnimationController _controller;

  bool heightAny = false;
  bool distanceAny = false;

  /// Always store height range in cm locally.
  RangeValues heightRangeCm = const RangeValues(160, 190);

  /// Store distance in miles locally.
  RangeValues distanceRange = const RangeValues(0, 200);

  final Set<String> ethnicities = {};
  final Set<String> languages = {};

  final ethnicityOptions = const [
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

  final languageOptions = const [
    "English",
    "Mandarin Chinese",
    "Yue Chinese",
    "Wu Chinese",
    "Korean",
    "Japanese",
    "Khmer",
    "Vietnamese",
    "Thai",
    "Filipino  (Tagalog)",
    "Indonesian",
    "Malay",
    "Algerian Arabic",
    "Amharic",
    "Arabic",
    "Bengali",
    "Bhojpuri",
    "Burmese",
    "Farsi (Persian)",
    "French",
    "German",
    "Gujarati",
    "Hausa",
    "Hindi",
    "Hmong",
    "Italian",
    "Javanese",
    "Kannada",
    "Maithili",
    "Odia",
  ];

  @override
  void initState() {
    super.initState();

    heightAny = flow.prefHeightAny.value;
    distanceAny = flow.prefDistanceAny.value;

    // Restore (clamp to safe bounds)
    heightRangeCm = _clampRange(
      RangeValues(
          flow.prefHeightMinCm.value ?? 0.0, flow.prefHeightMaxCm.value ?? 0.0),
      min: 140,
      max: 220,
    );

    distanceRange = _clampRange(
      RangeValues(flow.prefDistanceMinMi.value, flow.prefDistanceMaxMi.value),
      min: 0,
      max: 200,
    );

    ethnicities.addAll(flow.preferredEthnicities);
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

  RangeValues _clampRange(RangeValues v,
      {required double min, required double max}) {
    final a = v.start.clamp(min, max).toDouble();
    final b = v.end.clamp(min, max).toDouble();
    return a <= b ? RangeValues(a, b) : RangeValues(b, a);
  }

  double _cmToFtDecimal(double cm) => cm / 30.48; // 1ft=30.48cm

  double _ftDecimalToCm(double ft) => ft * 30.48;

  String _formatHeight(double cm) {
    final unit = flow.heightUnit.value; // "cm" or "ft"
    if (unit == "cm") {
      return "${cm.round()} cm";
    }
    final totalInches = (cm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet'$inches\"";
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
                    value: 0.75,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFFFD6DE),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3B7A)),
                  ),
                ),
              ),
              SizedBox(height: 0.8.h),
              const TextWidget(
                text: '7 of 10',
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
        TextWidget(text: title, size: 17, weight: FontWeight.w600),
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
              color: selected ? Colors.transparent : Colors.grey.shade300),
          boxShadow: selected
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
          size: 14,
          weight: FontWeight.w500,
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Future<void> _continue() async {
    // Save preferences in canonical units.
    flow.prefHeightAny.value = heightAny;
    flow.prefHeightMinCm.value = heightRangeCm.start;
    flow.prefHeightMaxCm.value = heightRangeCm.end;

    flow.prefDistanceAny.value = distanceAny;
    flow.prefDistanceMinMi.value = distanceRange.start;
    flow.prefDistanceMaxMi.value = distanceRange.end;

    flow.preferredEthnicities.assignAll(ethnicities.toList());
    flow.preferredLanguages.assignAll(languages.toList());

    flow.preferences.assignAll([
      ...ethnicities.map((e) => "ethnicity:$e"),
      ...languages.map((l) => "language:$l"),
    ]);

    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CulturalVibeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = flow.heightUnit.value; // "cm" or "ft"

    // Slider bounds
    const minCm = 140.0;
    const maxCm = 220.0;

    // Distance bounds
    const minMi = 0.0;
    const maxMi = 200.0;

    // Keep values safe (prevents RangeSlider assertion)
    final safeHeightCm = _clampRange(heightRangeCm, min: minCm, max: maxCm);
    final safeDistance = _clampRange(distanceRange, min: minMi, max: maxMi);

    if (safeHeightCm != heightRangeCm || safeDistance != distanceRange) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          heightRangeCm = safeHeightCm;
          distanceRange = safeDistance;
        });
      });
    }

    // For display slider in ft: show ft-decimal but persist cm.
    final heightSliderMin = unit == "ft" ? _cmToFtDecimal(minCm) : minCm;
    final heightSliderMax = unit == "ft" ? _cmToFtDecimal(maxCm) : maxCm;

    RangeValues heightSliderValues = unit == "ft"
        ? RangeValues(_cmToFtDecimal(safeHeightCm.start),
            _cmToFtDecimal(safeHeightCm.end))
        : safeHeightCm;

    heightSliderValues = _clampRange(heightSliderValues,
        min: heightSliderMin, max: heightSliderMax);

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
                        text: 'Preferences',
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
                            'Set your search criteria to find the perfect connection.',
                        color: Colors.grey,
                      ),
                      0.2,
                      0.35,
                    ),
                    SizedBox(height: 4.h),
                    _sectionHeader(
                      'Preferred Height *',
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
                          min: heightSliderMin,
                          max: heightSliderMax,
                          divisions: 16,
                          values: heightSliderValues,
                          onChanged: (values) {
                            setState(() {
                              // Convert back to cm for storage in state.
                              final newCm = unit == "ft"
                                  ? RangeValues(_ftDecimalToCm(values.start),
                                      _ftDecimalToCm(values.end))
                                  : values;

                              heightRangeCm =
                                  _clampRange(newCm, min: minCm, max: maxCm);
                            });
                          },
                        ),
                      ),
                      Row(
                        children: [
                          TextWidget(text: _formatHeight(heightRangeCm.start)),
                          const Spacer(),
                          const TextWidget(text: "  –  "),
                          const Spacer(),
                          TextWidget(text: _formatHeight(heightRangeCm.end)),
                        ],
                      ),
                    ],
                    SizedBox(height: 3.h),
                    _sectionHeader(
                      'Preferred Distance *',
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
                          min: minMi,
                          max: maxMi,
                          divisions: 20,
                          values: safeDistance,
                          onChanged: (values) {
                            setState(() {
                              distanceRange =
                                  _clampRange(values, min: minMi, max: maxMi);
                            });
                          },
                        ),
                      ),
                      Row(
                        children: [
                          TextWidget(
                              text:
                                  "${max(0, distanceRange.start.round())} mi"),
                          const Spacer(),
                          const TextWidget(text: "  –  "),
                          const Spacer(),
                          TextWidget(
                              text:
                                  "${min(200, distanceRange.end.round())} mi"),
                        ],
                      ),
                    ],
                    SizedBox(height: 3.h),
                    _sectionHeader('Preferred Ethnicity *'),
                    SizedBox(height: 2.h),
                    Wrap(
                      spacing: 3.w,
                      runSpacing: 2.h,
                      children: ethnicityOptions
                          .map((e) => _chip(e, ethnicities))
                          .toList(),
                    ),
                    SizedBox(height: 4.h),
                    _sectionHeader('Preferred Languages *'),
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
                      children: languageOptions
                          .map((l) => _chip(l, languages))
                          .toList(),
                    ),
                    SizedBox(height: 6.h),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.5.h),
              child: ButtonWidget(
                text: 'Continue ✨',
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
