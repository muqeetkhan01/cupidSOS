import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';
import 'preferences_screen.dart';

class EthnicityQuestionScreen extends StatefulWidget {
  const EthnicityQuestionScreen({super.key});

  @override
  State<EthnicityQuestionScreen> createState() =>
      _EthnicityQuestionScreenState();
}

class _EthnicityQuestionScreenState extends State<EthnicityQuestionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  String? selected;

  /// ✅ CORRECT ETHNICITY OPTIONS
  final List<String> options = const [
    'Asian',
    'Black / African Descent',
    'Hispanic / Latino',
    'Middle Eastern',
    'South Asian',
    'White / Caucasian',
    'Mixed / Multiracial',
    'Prefer not to say',
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

  /// 🔥 Entrance animation
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

  /// 🔝 TOP HEADER (PROGRESS CENTERED)
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
                    value: 12 / 18,
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
                text: '2/3',
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// OPTION TILE
  Widget _optionCard(String text) {
    final bool isSelected = selected == text;

    return GestureDetector(
      onTap: () => setState(() => selected = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.2.h),
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFF6F7D),
                    Color(0xFFD86BCF),
                  ],
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
                  text: 'ABOUT YOU',
                  size: 13,
                  weight: FontWeight.w700,
                  color: Color(0xFFFF6F7D),
                ),
                0.15,
                0.3,
              ),
              SizedBox(height: 1.2.h),
              _animated(
                const TextWidget(
                  text: 'What is your ethnicity?',
                  size: 18,
                  weight: FontWeight.w600,
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
                  onTap: selected != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PreferencesScreen(),
                            ),
                          );
                        }
                      : () {},
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
