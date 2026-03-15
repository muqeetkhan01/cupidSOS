import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/ethnicity_question_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

enum HeightUnit { cm, ft }

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

  HeightUnit unit = HeightUnit.cm;

  int selectedCm = 173;
  int selectedInches = 68; // 5'8"

  @override
  void initState() {
    super.initState();

    final savedUnit = flow.heightUnit.value;
    if (savedUnit == "ft") unit = HeightUnit.ft;

    final existingCm = flow.heightCm.value?.round();
    if (existingCm != null) {
      selectedCm = existingCm.clamp(140, 220);
      selectedInches = _cmToInches(selectedCm);
    }

    _scrollController = FixedExtentScrollController(
      initialItem: _initialWheelIndex(),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _controller.forward();
    });
  }

  int _initialWheelIndex() {
    if (unit == HeightUnit.cm) return selectedCm - 140;
    return (selectedInches - _minInches()).clamp(0, _inchCount() - 1);
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

  int _cmToInches(int cm) => (cm / 2.54).round();
  int _inchesToCm(int inches) => (inches * 2.54).round();

  int _minInches() => 54; // 4'6"
  int _maxInches() => 87; // 7'3"
  int _inchCount() => _maxInches() - _minInches() + 1;

  String _toFeetInches(int inches) {
    final feet = inches ~/ 12;
    final inch = inches % 12;
    return "$feet'$inch\"";
  }

  void _setUnit(HeightUnit next) {
    if (unit == next) return;
    setState(() {
      unit = next;

      final cm = _currentCm();
      selectedCm = cm.clamp(140, 220);
      selectedInches =
          _cmToInches(selectedCm).clamp(_minInches(), _maxInches());

      _scrollController.dispose();
      _scrollController = FixedExtentScrollController(
        initialItem: _initialWheelIndex(),
      );
    });
  }

  int _currentCm() {
    if (unit == HeightUnit.cm) return selectedCm;
    return _inchesToCm(selectedInches);
  }

  Future<void> _continue() async {
    flow.heightUnit.value = unit == HeightUnit.ft ? "ft" : "cm";
    flow.heightCm.value = _currentCm().toDouble();

    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EthnicityQuestionScreen()),
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
                    value: 6 / 11,
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
                text: '7 of 11',
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unitToggle() {
    Widget chip(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 5.6.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFFECEF) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    selected ? const Color(0xFFFF6F7D) : Colors.grey.shade300,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: TextWidget(
              text: label,
              weight: FontWeight.w600,
              color:
                  selected ? const Color(0xFFFF6F7D) : const Color(0xFF1E1E1E),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip("Centimeters", unit == HeightUnit.cm,
            () => _setUnit(HeightUnit.cm)),
        SizedBox(width: 3.w),
        chip("Feet", unit == HeightUnit.ft, () => _setUnit(HeightUnit.ft)),
      ],
    );
  }

  Widget _wheel() {
    final itemExtent = 6.5.h;

    return Center(
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
              height: itemExtent,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            ListWheelScrollView.useDelegate(
              controller: _scrollController,
              physics: const FixedExtentScrollPhysics(),
              itemExtent: itemExtent,
              onSelectedItemChanged: (index) {
                setState(() {
                  if (unit == HeightUnit.cm) {
                    selectedCm = 140 + index;
                    selectedInches = _cmToInches(selectedCm)
                        .clamp(_minInches(), _maxInches());
                  } else {
                    selectedInches = _minInches() + index;
                    selectedCm = _inchesToCm(selectedInches).clamp(140, 220);
                  }
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: unit == HeightUnit.cm ? 81 : _inchCount(),
                builder: (_, index) {
                  final isSelected = (unit == HeightUnit.cm)
                      ? (140 + index) == selectedCm
                      : (_minInches() + index) == selectedInches;

                  final label = unit == HeightUnit.cm
                      ? "${(140 + index)} cm"
                      : _toFeetInches(_minInches() + index);

                  return Center(
                    child: TextWidget(
                      text: label,
                      size: isSelected ? 20 : 16,
                      weight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? Colors.black : Colors.grey.shade400,
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
                      "Pick one unit — we’ll use it everywhere across the app.",
                  size: 15,
                  color: Colors.grey,
                ),
                0.2,
                0.35,
              ),
              SizedBox(height: 2.h),
              _animated(_unitToggle(), 0.28, 0.45),
              SizedBox(height: 3.h),
              _animated(_wheel(), 0.35, 0.8),
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
