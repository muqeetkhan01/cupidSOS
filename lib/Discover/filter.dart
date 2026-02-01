import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  bool heightAny = false;
  bool distanceAny = false;
  RangeValues heightRange = const RangeValues(5.1, 6.0); // default full range
  double selectedDistanceMi = 100; // default
  RangeValues distanceRange = const RangeValues(0, 100); // default

  double heightValue = 0.45;
  double distanceValue = 0.25;

  final Set<String> ethnicities = {};
  final Set<String> languages = {};

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
    'Other',
  ];

  final languageOptions = [
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
    "Odia"
  ];

  /// ================= HELPERS =================

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

  Widget _slider({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(0xFFFF6F7D),
        inactiveTrackColor: const Color(0xFFFF6F7D).withOpacity(0.25),
        thumbColor: const Color(0xFFFF6F7D),
        overlayColor: const Color(0xFFFF6F7D).withOpacity(0.12),
      ),
      child: Slider(value: value, onChanged: onChanged),
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

  /// ================= UI =================

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
                            min: 5.1,
                            max: 6.0,
                            divisions: 11,
                            values: heightRange,
                            onChanged: (values) {
                              setState(() => heightRange = values);
                            },
                          )),
                      Row(
                        children: [
                          TextWidget(
                            text: "${heightRange.start.toStringAsFixed(1)} ft",
                          ),
                          Spacer(),
                          TextWidget(
                            text: "  –  ",
                          ),
                          Spacer(),
                          TextWidget(
                            text: "${heightRange.end.toStringAsFixed(1)} ft",
                          )
                        ],
                      )
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
                            min: 0,
                            max: 200,
                            divisions: 20,
                            values: distanceRange,
                            onChanged: (values) {
                              setState(() => distanceRange = values);
                            },
                          )),
                      Row(
                        children: [
                          TextWidget(
                            text:
                                "${distanceRange.start.round().toStringAsFixed(1)} mi",
                          ),
                          Spacer(),
                          TextWidget(
                            text: "  –  ",
                          ),
                          Spacer(),
                          TextWidget(
                            text:
                                "${distanceRange.end.round().toStringAsFixed(1)} mi",
                          )
                        ],
                      )
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

            /// APPLY BUTTON (SAME AS ONBOARDING)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.5.h),
              child: ButtonWidget(
                text: 'Apply Filters',
                height: 7,
                radius: 36,
                variant: ButtonVariant.gradient,
                gradient: const [
                  Color(0xFFFF6F7D),
                  Color(0xFFD86BCF),
                ],
                enableShadow: true,
                onTap: () {
                  Navigator.pop(context, {
                    "heightAny": heightAny,
                    "heightValue": heightValue,
                    "distanceAny": distanceAny,
                    "distanceValue": distanceValue,
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
