import 'package:cupid_app/onboard/vibe_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  final mmCtrl = TextEditingController();
  final ddCtrl = TextEditingController();
  final yyyyCtrl = TextEditingController();

  final mmFocus = FocusNode();
  final ddFocus = FocusNode();
  final yyyyFocus = FocusNode();

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

    // rebuild on focus change
    mmFocus.addListener(() => setState(() {}));
    ddFocus.addListener(() => setState(() {}));
    yyyyFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    mmCtrl.dispose();
    ddCtrl.dispose();
    yyyyCtrl.dispose();
    mmFocus.dispose();
    ddFocus.dispose();
    yyyyFocus.dispose();
    super.dispose();
  }

  Widget _animatedItem({
    required Widget child,
    required double start,
    required double end,
  }) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * 28),
          child: child,
        ),
      ),
    );
  }

  Widget _dateField({
    required String hint,
    required TextEditingController controller,
    required FocusNode focus,
    required int maxLength,
  }) {
    final bool isActive = focus.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22.w,
      height: 6.5.h,
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isActive
            ? const Color(0xFFD86BCF).withOpacity(0.08)
            : Colors.transparent,
        border: Border.all(
          color: isActive ? const Color(0xFFD86BCF) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: focus,
        maxLength: maxLength,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        cursorColor: const Color(0xFFD86BCF), // ✅ purple cursor
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: isActive
              ? const Color(0xFFD86BCF) // ✅ purple text when active
              : Colors.grey.shade600,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(
            color: isActive
                ? const Color(0xFFD86BCF).withOpacity(0.4)
                : Colors.grey.shade400,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
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
            children: [
              SizedBox(height: 1.5.h),

              // 🔙 Back + Step
              _animatedItem(
                start: 0.0,
                end: 0.15,
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
                    const TextWidget(
                      text: 'Step 2 of 7',
                      size: 14,
                      color: Colors.grey,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 6.h),

              // 📅 Icon
              _animatedItem(
                start: 0.15,
                end: 0.3,
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD86BCF).withOpacity(0.12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFFD86BCF),
                    size: 34,
                  ),
                ),
              ),

              SizedBox(height: 4.h),

              _animatedItem(
                start: 0.3,
                end: 0.45,
                child: const TextWidget(
                  text: "When’s your birthday? 🎂",
                  size: 24,
                  weight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 1.2.h),

              _animatedItem(
                start: 0.45,
                end: 0.6,
                child: TextWidget(
                  text: "We'll unlock your cosmic soul badges",
                  size: 15,
                  color: Colors.grey.shade600,
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 5.h),

              // 🔢 REAL INPUT FIELDS
              _animatedItem(
                start: 0.6,
                end: 0.75,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _dateField(
                      hint: 'MM',
                      controller: mmCtrl,
                      focus: mmFocus,
                      maxLength: 2,
                    ),
                    _dateField(
                      hint: 'DD',
                      controller: ddCtrl,
                      focus: ddFocus,
                      maxLength: 2,
                    ),
                    _dateField(
                      hint: 'YYYY',
                      controller: yyyyCtrl,
                      focus: yyyyFocus,
                      maxLength: 4,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 5.h),

              _animatedItem(
                start: 0.75,
                end: 1.0,
                child: ButtonWidget(
                  text: '✨ Reveal My Signs',
                  height: 7,
                  radius: 36,
                  variant: ButtonVariant.gradient,
                  gradient: const [
                    Color(0xFFFF6F7D),
                    Color(0xFFD86BCF),
                  ],
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 450),
                        pageBuilder: (_, __, ___) =>
                            const VibeSelectionScreen(),
                        transitionsBuilder: (_, animation, __, child) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          );

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                      ),
                    );

                    // validate date here later
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
