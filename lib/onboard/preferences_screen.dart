import 'package:flutter/material.dart';
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
  late final AnimationController _controller;

  bool heightAny = false;
  bool distanceAny = false;

  double heightValue = 0.45;
  double distanceValue = 0.25;

  final Set<String> ethnicities = {};
  final Set<String> languages = {};

  final ethnicityOptions = [
    'Asian',
    'Black / African Descent',
    'Hispanic / Latino',
    'Middle Eastern',
    'South Asian',
    'White / Caucasian',
    'Mixed / Multiracial',
    'Other',
  ];

  final languageOptions = [
    'English',
    'Mandarin Chinese',
    'Cantonese',
    'Korean',
    'Japanese',
    'Vietnamese',
    'Hindi',
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

  /// 🔝 TOP PROGRESS HEADER (3 / 3)
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
                    value: 1, // 3 / 3
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
                text: '3/3',
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

  @override
  Widget build(BuildContext context) {
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
                    if (!heightAny)
                      _slider(
                        value: heightValue,
                        onChanged: (v) => setState(() => heightValue = v),
                      ),
                    SizedBox(height: 3.h),
                    _sectionHeader(
                      'Preferred Distance *',
                      showToggle: true,
                      toggle: distanceAny,
                      onToggle: () =>
                          setState(() => distanceAny = !distanceAny),
                    ),
                    if (!distanceAny)
                      _slider(
                        value: distanceValue,
                        onChanged: (v) => setState(() => distanceValue = v),
                      ),
                    SizedBox(height: 3.h),
                    _sectionHeader('Preferred Ethnicity *'),
                    Text('What is your preferred ethnicity in a partner?'),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.5.h),
              child: ButtonWidget(
                text: 'Continue ✨',
                height: 7,
                radius: 36,
                variant: ButtonVariant.gradient,
                gradient: const [
                  Color(0xFFFF6F7D),
                  Color(0xFFD86BCF),
                ],
                enableShadow: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QuirkPromptScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
