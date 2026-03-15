import 'package:cupid_app/config/flow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';
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

  RangeValues heightRange = const RangeValues(160, 190); // unit-aware
  RangeValues distanceRange = const RangeValues(0, 100);
  RangeValues clampRangeValues({
    required RangeValues values,
    required double min,
    required double max,
  }) {
    final start = values.start.clamp(min, max).toDouble();
    final end = values.end.clamp(min, max).toDouble();
    if (start <= end) return RangeValues(start, end);
    return RangeValues(end, start);
  }

  final Set<String> ethnicities = {};
  final Set<String> languages = {};

  String get _heightUnit => (flow.heightUnit.value == "ft") ? "ft" : "cm";

  double _cmToFeet(double cm) => cm / 30.48;
  double _feetToCm(double ft) => ft * 30.48;

  double _clamp(double v, double min, double max) =>
      v < min ? min : (v > max ? max : v);

  RangeValues _defaultHeightRangeForUnit() {
    if (_heightUnit == "ft") return const RangeValues(5.0, 6.5);
    return const RangeValues(160, 190);
  }

  String _formatHeight(double value) {
    if (_heightUnit == "ft") return "${value.toStringAsFixed(1)} ft";
    return "${value.round()} cm";
  }

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

    // Stored in cm; UI is unit-aware.
    final minCm = flow.prefHeightMinCm.value ?? 160.0;
    final maxCm = flow.prefHeightMaxCm.value ?? 190.0;

    if (_heightUnit == "ft") {
      final minFt = _cmToFeet(minCm);
      final maxFt = _cmToFeet(maxCm);
      heightRange = RangeValues(
        _clamp(minFt, 4.5, 7.3),
        _clamp(maxFt, 4.5, 7.3),
      );
    } else {
      heightRange = RangeValues(
        _clamp(minCm, 140, 220),
        _clamp(maxCm, 140, 220),
      );
    }

    distanceRange =
        RangeValues(flow.prefDistanceMinMi.value, flow.prefDistanceMaxMi.value);

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

  Future<void> _continue() async {
    flow.prefHeightAny.value = heightAny;
    flow.prefDistanceAny.value = distanceAny;

    final minUi = heightRange.start;
    final maxUi = heightRange.end;

    final minCm = _heightUnit == "ft" ? _feetToCm(minUi) : minUi;
    final maxCm = _heightUnit == "ft" ? _feetToCm(maxUi) : maxUi;

    flow.prefHeightMinCm.value = minCm;
    flow.prefHeightMaxCm.value = maxCm;

    flow.prefDistanceMinMi.value = distanceRange.start;
    flow.prefDistanceMaxMi.value = distanceRange.end;

    flow.preferredEthnicities.assignAll(ethnicities.toList());
    flow.preferredLanguages.assignAll(languages.toList());

    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CulturalVibeScreen()),
    );
  }

  SliderThemeData _rangeTheme(BuildContext context) {
    return SliderTheme.of(context).copyWith(
      activeTrackColor: const Color(0xFFFF6F7D),
      inactiveTrackColor: const Color(0xFFFF6F7D).withOpacity(0.25),
      thumbColor: const Color(0xFFFF6F7D),
      overlayColor: const Color(0xFFFF6F7D).withOpacity(0.12),
      rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
      rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
      showValueIndicator: ShowValueIndicator.never,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = ethnicities.isNotEmpty && languages.isNotEmpty;

    final heightMin = _heightUnit == "ft" ? 4.5 : 140.0;
    final heightMax = _heightUnit == "ft" ? 7.3 : 220.0;
    final heightDivisions = _heightUnit == "ft" ? 28 : 80; // ~0.1ft or 1cm

    final heightLabelStart = _formatHeight(heightRange.start);
    final heightLabelEnd = _formatHeight(heightRange.end);
    final safeValues =
        clampRangeValues(values: distanceRange, min: 0, max: 100);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              _animated(
                SizedBox(
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
                                value: 9 / 11,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFFFD6DE),
                                valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFFF3B7A)),
                              ),
                            ),
                          ),
                          SizedBox(height: 0.8.h),
                          const TextWidget(
                            text: '10 of 11',
                            size: 12,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                0,
                0.15,
              ),
              SizedBox(height: 3.h),
              _animated(
                TextWidget(
                  text: 'Your Preferences',
                  size: 18.sp,
                  weight: FontWeight.w600,
                ),
                0.15,
                0.3,
              ),
              SizedBox(height: 2.5.h),

              // Height preference
              _animated(
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: TextWidget(
                              text: "Preferred Height",
                              weight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              const TextWidget(
                                  text: "Any", color: Colors.grey, size: 13),
                              Switch(
                                value: heightAny,
                                onChanged: (v) => setState(() => heightAny = v),
                              ),
                            ],
                          )
                        ],
                      ),
                      if (!heightAny) ...[
                        SizedBox(height: 1.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(text: heightLabelStart),
                            TextWidget(text: heightLabelEnd),
                          ],
                        ),
                        SliderTheme(
                          data: _rangeTheme(context),
                          child: RangeSlider(
                            min: heightMin,
                            max: heightMax,
                            divisions: heightDivisions,
                            values: heightRange,
                            onChanged: (values) =>
                                setState(() => heightRange = values),
                          ),
                        ),
                      ],
                      if (heightAny) ...[
                        SizedBox(height: 0.8.h),
                        TextWidget(
                          text:
                              "We’ll use ${_heightUnit.toUpperCase()} throughout the app (based on the user’s chosen height unit).",
                          size: 13,
                          color: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ),
                0.25,
                0.55,
              ),

              SizedBox(height: 2.h),

              // Distance preference (unchanged)
              _animated(
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: TextWidget(
                              text: "Preferred Distance (mi)",
                              weight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              const TextWidget(
                                  text: "Any", color: Colors.grey, size: 13),
                              Switch(
                                value: distanceAny,
                                onChanged: (v) =>
                                    setState(() => distanceAny = v),
                              ),
                            ],
                          )
                        ],
                      ),
                      if (!distanceAny) ...[
                        SizedBox(height: 1.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                                text:
                                    "${distanceRange.start.toStringAsFixed(0)} mi"),
                            TextWidget(
                                text:
                                    "${distanceRange.end.toStringAsFixed(0)} mi"),
                          ],
                        ),
                        SliderTheme(
                            data: _rangeTheme(context),
                            child: RangeSlider(
                              min: 0,
                              max: 100,
                              divisions: 10,
                              values: safeValues,
                              onChanged: (values) => setState(() {
                                distanceRange = clampRangeValues(
                                    values: values, min: 0, max: 100);
                              }),
                            )),
                      ],
                    ],
                  ),
                ),
                0.35,
                0.65,
              ),

              SizedBox(height: 2.h),

              // Ethnicity
              _animated(
                _multiSelectCard(
                  title: "Preferred Ethnicities",
                  options: ethnicityOptions,
                  selected: ethnicities,
                  onToggle: (s) => setState(() {
                    if (!ethnicities.add(s)) ethnicities.remove(s);
                  }),
                ),
                0.45,
                0.78,
              ),

              SizedBox(height: 2.h),

              // Languages
              _animated(
                _multiSelectCard(
                  title: "Preferred Languages",
                  options: languageOptions,
                  selected: languages,
                  onToggle: (s) => setState(() {
                    if (!languages.add(s)) languages.remove(s);
                  }),
                ),
                0.55,
                0.88,
              ),

              SizedBox(height: 3.h),
              _animated(
                ButtonWidget(
                  text: 'Next',
                  height: 7,
                  radius: 36,
                  variant: canContinue
                      ? ButtonVariant.gradient
                      : ButtonVariant.solid,
                  gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                  backgroundColor: Colors.grey.shade300,
                  enableShadow: canContinue,
                  onTap: canContinue ? _continue : () {},
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

  Widget _multiSelectCard({
    required String title,
    required List<String> options,
    required Set<String> selected,
    required void Function(String) onToggle,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(text: title, weight: FontWeight.w700),
          SizedBox(height: 1.5.h),
          Wrap(
            spacing: 2.5.w,
            runSpacing: 1.2.h,
            children: options.map((o) {
              final isSelected = selected.contains(o);
              return GestureDetector(
                onTap: () => onToggle(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFECEF) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF6F7D)
                          : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: TextWidget(
                    text: o,
                    size: 13,
                    weight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFFFF6F7D)
                        : const Color(0xFF1E1E1E),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
