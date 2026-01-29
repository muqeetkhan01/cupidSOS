import 'package:cupid_app/onboard/height.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';
import 'ethnicity_question_screen.dart';

enum Gender { woman, man, other }

class BasicsScreen extends StatefulWidget {
  const BasicsScreen({super.key});

  @override
  State<BasicsScreen> createState() => _BasicsScreenState();
}

class _BasicsScreenState extends State<BasicsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  final TextEditingController nameCtrl = TextEditingController();
  Gender? gender;

  bool get isValid => nameCtrl.text.trim().isNotEmpty && gender != null;

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

    nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    nameCtrl.dispose();
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

  Widget _header(BuildContext context) {
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
                    value: 3 / 22,
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
                text: '5 of 10',
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderChip(Gender g, String label) {
    final selected = gender == g;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = g),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 6.5.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? const Color(0xFFFFECEF) : Colors.white,
            border: Border.all(
              color: selected ? const Color(0xFFFF6F7D) : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: TextWidget(
            text: label,
            weight: FontWeight.w600,
            color: selected ? const Color(0xFFFF6F7D) : const Color(0xFF1E1E1E),
          ),
        ),
      ),
    );
  }

  Widget _inputField({required String hint}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: nameCtrl,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.1.h),
          border: InputBorder.none,
        ),
      ),
    );
  }

  DateTime? selectedDob;

  String get dobText {
    if (selectedDob == null) return 'Select your birthday';
    return "${selectedDob!.day.toString().padLeft(2, '0')} / "
        "${selectedDob!.month.toString().padLeft(2, '0')} / "
        "${selectedDob!.year}";
  }

  Widget _birthdayField(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();

        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(now.year - 22),
          firstDate: DateTime(1900),
          lastDate: DateTime(now.year - 18),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFFFF6F7D), // header & selection
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6F7D),
                  ),
                ),
                dialogTheme: DialogThemeData(backgroundColor: Colors.white),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          setState(() => selectedDob = picked);
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              text: dobText,
              color: selectedDob == null ? Colors.grey.shade400 : Colors.black,
            ),
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
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
              _animated(_header(context), 0, 0.15),
              SizedBox(height: 2.h),
              _animated(
                TextWidget(
                  text: 'The Basics',
                  size: 18.sp,
                  weight: FontWeight.w500,
                ),
                0.15,
                0.3,
              ),
              SizedBox(height: 0.6.h),
              _animated(
                const TextWidget(
                  text: 'Just a few details to get started.',
                  size: 15,
                  color: Colors.grey,
                ),
                0.2,
                0.35,
              ),
              SizedBox(height: 4.h),
              _animated(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextWidget(
                      text: 'FULL NAME',
                      size: 12,
                      weight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 1.h),
                    _inputField(hint: 'What do friends call you?'),
                  ],
                ),
                0.3,
                0.5,
              ),
              SizedBox(height: 3.h),
              _animated(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextWidget(
                      text: 'BIRTHDAY',
                      size: 12,
                      weight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 1.h),
                    _birthdayField(context),
                  ],
                ),
                0.45,
                0.65,
              ),
              SizedBox(height: 3.h),
              _animated(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextWidget(
                      text: 'GENDER',
                      size: 12,
                      weight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 1.5.h),
                    Row(
                      children: [
                        _genderChip(Gender.woman, 'Woman'),
                        SizedBox(width: 3.w),
                        _genderChip(Gender.man, 'Man'),
                        SizedBox(width: 3.w),
                        _genderChip(Gender.other, 'Other'),
                      ],
                    ),
                  ],
                ),
                0.6,
                0.85,
              ),
              const Spacer(),
              _animated(
                ButtonWidget(
                  text: 'Next Step',
                  height: 7,
                  radius: 36,
                  variant:
                      isValid ? ButtonVariant.gradient : ButtonVariant.solid,
                  gradient: const [
                    Color(0xFFFF6F7D),
                    Color(0xFFD86BCF),
                  ],
                  backgroundColor: Colors.grey.shade300,
                  enableShadow: isValid,
                  onTap: isValid
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HeightQuestionScreen(),
                            ),
                          );
                        }
                      : () {},
                ),
                0.85,
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
