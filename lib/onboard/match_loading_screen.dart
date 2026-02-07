import 'dart:math';
import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/match_result_screen.dart';
import 'package:cupid_app/widgets/bottomNav.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';

class MatchLoadingScreen extends StatefulWidget {
  const MatchLoadingScreen({super.key});

  @override
  State<MatchLoadingScreen> createState() => _MatchLoadingScreenState();
}

class _MatchLoadingScreenState extends State<MatchLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double progress = 0.12;
  String title = 'Scanning the stars ✨';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _simulateProgress();
  }

  Future<void> _simulateProgress() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      progress = 0.5;
      title = 'Finding shared vibes 💫';
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      progress = 0.88;
      title = 'Almost there… 🎯';
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      progress = 1.0;
    });

    /// ✅ AUTO NAVIGATION AT 100%
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final flow = Get.find<AppFlowController>();
    await flow.completeOnboarding();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const CustomCupidBottomNav(
                currentIndex: 0,
              )),
    );
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (_) => const MatchResultScreen()),
    // );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 100.w,
        height: 100.h,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6F7D),
              Color(0xFFD86BCF),
            ],
          ),
        ),
        child: Column(
          children: [
            const Spacer(),

            /// 🔁 ROTATING RING (CENTER AVATAR STATIC)
            SizedBox(
              width: 40.w,
              height: 40.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  /// OUTER RING
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      return Transform.rotate(
                        angle: _controller.value * 2 * pi,
                        child: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.85),
                              width: 4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  /// INNER CIRCLE
                  Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),

                  /// 🐯 STATIC AVATAR
                  const Text(
                    '🐯',
                    style: TextStyle(fontSize: 42),
                  ),

                  /// ROTATING PILL
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      return Transform.rotate(
                        angle: _controller.value * 2 * pi,
                        child: Transform.translate(
                          offset: Offset(0, -18.w),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 0.8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const TextWidget(
                              text: 'Learning',
                              size: 13,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 4.h),

            /// STATUS
            TextWidget(
              text: title,
              size: 18,
              weight: FontWeight.w600,
              color: Colors.white,
            ),

            SizedBox(height: 3.h),

            /// PROGRESS BAR
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  TextWidget(
                    text: '${(progress * 100).round()}% complete',
                    size: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ],
              ),
            ),

            const Spacer(),

            /// EMOJIS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('💗', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Text('✨', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Text('🌙', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Text('💫', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Text('💖', style: TextStyle(fontSize: 20)),
              ],
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}
