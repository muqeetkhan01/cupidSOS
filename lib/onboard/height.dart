import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/ethnicity_question_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class HeightQuestionScreen extends StatefulWidget {
  const HeightQuestionScreen({super.key});

  @override
  State<HeightQuestionScreen> createState() => _HeightQuestionScreenState();
}

class _HeightQuestionScreenState extends State<HeightQuestionScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();

  late final AnimationController _controller;

  late FixedExtentScrollController _scrollController;

  int selectedCm = 173;

  @override
  void initState() {
    super.initState();

    final existing = flow.heightCm.value?.round();
    if (existing != null && existing >= 140 && existing <= 220) {
      selectedCm = existing;
    }

    _scrollController = FixedExtentScrollController(
      initialItem: selectedCm - 140,
    );

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
    _scrollController.dispose();
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
          offset: Offset(0, (1 - anim.value) * 26),
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
                    value: 4 / 10,
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
                text: '4 of 10',
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _toFeetInches(int cm) {
    final inches = (cm / 2.54).round();
    final feet = inches ~/ 12;
    final inch = inches % 12;
    return "$feet'$inch\"";
  }

  Future<void> _continue() async {
    flow.heightCm.value = selectedCm.toDouble();
    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EthnicityQuestionScreen(),
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
                TextWidget(
                  text: 'How tall are you?',
                  size: 18.sp,
                  weight: FontWeight.w500,
                ),
                0.15,
                0.3,
              ),
              SizedBox(height: 0.8.h),
              _animated(
                const TextWidget(
                  text:
                      "Let's keep it real — your height will show on your profile.",
                  size: 15,
                  color: Colors.grey,
                ),
                0.2,
                0.35,
              ),
              SizedBox(height: 6.h),
              _animated(
                Center(
                  child: Container(
                    height: 32.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 6.5.h,
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        ListWheelScrollView.useDelegate(
                          controller: _scrollController,
                          physics: const FixedExtentScrollPhysics(),
                          itemExtent: 6.5.h,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedCm = 140 + index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 81,
                            builder: (_, index) {
                              final cm = 140 + index;
                              final isSelected = cm == selectedCm;

                              return Center(
                                child: TextWidget(
                                  text: "${_toFeetInches(cm)} (${cm}cm)",
                                  size: isSelected ? 20 : 16,
                                  weight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey.shade400,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                0.35,
                0.8,
              ),
              const Spacer(),
              _animated(
                ButtonWidget(
                  text: 'Next',
                  height: 7,
                  radius: 36,
                  variant: ButtonVariant.gradient,
                  gradient: const [
                    Color(0xFFFF6F7D),
                    Color(0xFFD86BCF),
                  ],
                  enableShadow: true,
                  onTap: _continue,
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
