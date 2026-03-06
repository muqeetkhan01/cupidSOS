// ==============================
// lib/Discover/filter.dart (PATCH)
// ==============================
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({
    super.key,
    this.initial,
  });

  /// Pass existing filters so the UI opens with previous selections.
  final Map<String, dynamic>? initial;

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  bool heightAny = false;
  bool distanceAny = false;

  RangeValues heightRange = const RangeValues(5.1, 7.0); // feet
  RangeValues distanceRange = const RangeValues(0, 100); // miles

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
    final m = widget.initial;
    if (m == null) return;

    heightAny = (m["heightAny"] as bool?) ?? heightAny;
    distanceAny = (m["distanceAny"] as bool?) ?? distanceAny;

    final hMin = (m["heightMinFt"] as num?)?.toDouble();
    final hMax = (m["heightMaxFt"] as num?)?.toDouble();
    if (hMin != null && hMax != null) heightRange = RangeValues(hMin, hMax);

    final dMin = (m["distanceMinMi"] as num?)?.toDouble();
    final dMax = (m["distanceMaxMi"] as num?)?.toDouble();
    if (dMin != null && dMax != null) distanceRange = RangeValues(dMin, dMax);

    final e = m["ethnicities"];
    if (e is List) ethnicities.addAll(e.whereType<String>());

    final l = m["languages"];
    if (l is List) languages.addAll(l.whereType<String>());
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
                  colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                )
              : null,
          color: selected ? null : Colors.white,
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
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
          weight: FontWeight.w600,
          color: selected ? Colors.white : Colors.black,
        ),
      ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const TextWidget(
          text: 'Filters',
          size: 22,
          weight: FontWeight.bold,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),
                    _sectionHeader(
                      'Preferred Height',
                      showToggle: true,
                      toggle: heightAny,
                      onToggle: () => setState(() => heightAny = !heightAny),
                    ),
                    if (!heightAny) ...[
                      SliderTheme(
                        data: _rangeTheme(context),
                        child: RangeSlider(
                          min: 5.1,
                          max: 7.0,
                          divisions: 19,
                          values: heightRange,
                          onChanged: (values) =>
                              setState(() => heightRange = values),
                        ),
                      ),
                      Row(
                        children: [
                          TextWidget(
                              text:
                                  "${heightRange.start.toStringAsFixed(1)} ft"),
                          const Spacer(),
                          const TextWidget(text: "–"),
                          const Spacer(),
                          TextWidget(
                              text: "${heightRange.end.toStringAsFixed(1)} ft"),
                        ],
                      ),
                    ],
                    SizedBox(height: 3.h),
                    _sectionHeader(
                      'Preferred Distance',
                      showToggle: true,
                      toggle: distanceAny,
                      onToggle: () =>
                          setState(() => distanceAny = !distanceAny),
                    ),
                    if (!distanceAny) ...[
                      SliderTheme(
                        data: _rangeTheme(context),
                        child: RangeSlider(
                          min: 0,
                          max: 200,
                          divisions: 40,
                          values: distanceRange,
                          onChanged: (values) =>
                              setState(() => distanceRange = values),
                        ),
                      ),
                      Row(
                        children: [
                          TextWidget(text: "${distanceRange.start.round()} mi"),
                          const Spacer(),
                          const TextWidget(text: "–"),
                          const Spacer(),
                          TextWidget(text: "${distanceRange.end.round()} mi"),
                        ],
                      ),
                    ],
                    SizedBox(height: 3.h),
                    _sectionHeader('Preferred Ethnicity'),
                    SizedBox(height: 2.h),
                    Wrap(
                      spacing: 3.w,
                      runSpacing: 2.h,
                      children: ethnicityOptions
                          .map((e) => _chip(e, ethnicities))
                          .toList(),
                    ),
                    SizedBox(height: 4.h),
                    _sectionHeader('Preferred Languages'),
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
                text: 'Apply Filters',
                height: 7,
                radius: 36,
                variant: ButtonVariant.gradient,
                gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                enableShadow: true,
                onTap: () {
                  Navigator.pop(context, <String, dynamic>{
                    "heightAny": heightAny,
                    "heightMinFt": heightRange.start,
                    "heightMaxFt": heightRange.end,
                    "distanceAny": distanceAny,
                    "distanceMinMi": distanceRange.start,
                    "distanceMaxMi": distanceRange.end,
                    "ethnicities": ethnicities.toList(),
                    "languages": languages.toList(),
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
