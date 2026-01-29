import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';
import 'big_three_screen.dart';

enum VibeType { taurus, tiger }

class VibeSelectionScreen extends StatefulWidget {
  const VibeSelectionScreen({super.key});

  @override
  State<VibeSelectionScreen> createState() => _VibeSelectionScreenState();
}

class _VibeSelectionScreenState extends State<VibeSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pageController;
  late final AnimationController _selectController;

  VibeType? selected;

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _pageController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _selectController.dispose();
    super.dispose();
  }

  // Page entrance animation
  Widget _animatedItem({
    required Widget child,
    required double start,
    required double end,
  }) {
    final anim = CurvedAnimation(
      parent: _pageController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
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

  Widget _vibeCard({
    required VibeType type,
    required String title,
    required String subtitle,
    required String meta,
    required String emoji,
  }) {
    final bool isSelected = selected == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selected = type;
          _selectController.forward(from: 0);
        });
      },
      child: AnimatedBuilder(
        animation: _selectController,
        builder: (_, __) {
          final double fill = isSelected ? _selectController.value : 0;

          return Container(
            height: 12.h,
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : const Color(0xFFD86BCF).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  // 🔥 Gradient fill animation (TOP → BOTTOM)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: FractionallySizedBox(
                        heightFactor: fill,
                        widthFactor: 1,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFF6F7D),
                                Color(0xFFD86BCF),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    child: Row(
                      children: [
                        Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: isSelected
                                ? Colors.white.withOpacity(0.25)
                                : Colors.white,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            emoji,
                            style: TextStyle(fontSize: 26.sp),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextWidget(
                                text: title,
                                size: 17,
                                weight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                              SizedBox(height: 0.4.h),
                              TextWidget(
                                text: subtitle,
                                size: 14,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.grey.shade700,
                              ),
                              SizedBox(height: 0.2.h),
                              TextWidget(
                                text: meta,
                                size: 13,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.grey.shade500,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF6F7D),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
              _animatedItem(
                start: 0,
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
                      text: 'Step 1 of 10',
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6.h),
              _animatedItem(
                start: 0.15,
                end: 0.3,
                child: TextWidget(
                  text: '✨ YOUR SOUL AURA ✨',
                  size: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 1.5.h),
              _animatedItem(
                start: 0.3,
                end: 0.45,
                child: TextWidget(
                  text: 'Which vibe is more YOU? 🌙',
                  size: 18,
                  weight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 1.h),
              _animatedItem(
                start: 0.45,
                end: 0.55,
                child: TextWidget(
                  text: 'This becomes your glowing profile badge',
                  size: 14,
                  color: Colors.grey.shade600,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 5.h),
              _animatedItem(
                start: 0.55,
                end: 0.75,
                child: Column(
                  children: [
                    _vibeCard(
                      type: VibeType.taurus,
                      title: 'Taurus',
                      subtitle: 'Grounded Soul',
                      meta: 'Western • Apr 20 – May 20',
                      emoji: '♉️',
                    ),
                    _vibeCard(
                      type: VibeType.tiger,
                      title: 'Tiger',
                      subtitle: 'Brave',
                      meta: 'Chinese Zodiac • Born in 1998',
                      emoji: '🐯',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _animatedItem(
                start: 0.75,
                end: 1,
                child: ButtonWidget(
                  text: 'Continue ✨',
                  height: 7,
                  radius: 36,
                  variant: selected != null
                      ? ButtonVariant.gradient
                      : ButtonVariant.solid,
                  gradient: selected != null
                      ? const [
                          Color(0xFFFF6F7D),
                          Color(0xFFD86BCF),
                        ]
                      : null,
                  backgroundColor: Colors.grey.shade300,
                  enableShadow: selected != null,
                  onTap: selected == null
                      ? () {}
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BigThreeScreen(),
                            ),
                          );
                        },
                ),
              ),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }
}
