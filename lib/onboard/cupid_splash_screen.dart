import 'dart:math';
import 'package:cupid_app/auth/select_auth.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';


class CupidSplashScreen extends StatefulWidget {
  const CupidSplashScreen({super.key});

  @override
  State<CupidSplashScreen> createState() => _CupidSplashScreenState();
}

class _CupidSplashScreenState extends State<CupidSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  // 👉 Right → Left transition
  Route _slideRightToLeft(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 100.w,
        height: 100.h,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
          ),
        ),
        child: Column(
          children: [
            const Spacer(),

            /// 💗 Rotating Logo + Orbit Icons
            AnimatedBuilder(
              animation: _rotationController,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * pi,
                  child: child,
                );
              },
              child: SizedBox(
                width: 34.w,
                height: 34.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft circle
                    Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                    ),

                    // Heart
                    Image.asset(
                      'assets/images/heart.png',
                      width: 15.w,
                      height: 15.w,
                      color: Colors.white,
                    ),

                    // Top left
                    Positioned(
                      top: 2.w,
                      left: 2.w,
                      child: Image.asset(
                        'assets/images/star_yellow.png',
                        width: 5.w,
                      ),
                    ),

                    // Top right
                    Positioned(
                      top: 3.w,
                      right: 1.w,
                      child: Image.asset(
                        'assets/images/sparkle_white.png',
                        width: 6.w,
                      ),
                    ),

                    // Bottom left
                    Positioned(
                      bottom: 5.w,
                      left: 0.w,
                      child: Image.asset(
                        'assets/images/star_yellow.png',
                        width: 5.w,
                      ),
                    ),

                    // Bottom right
                    Positioned(
                      bottom: 3.w,
                      right: 1.w,
                      child: Image.asset(
                        'assets/images/sparkle_white.png',
                        width: 6.w,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 4.h),

            TextWidget(
              text: 'Cupid SOS',
              size: 28,
              weight: FontWeight.bold,
              color: Colors.white,
            ),

            SizedBox(height: 1.5.h),

            TextWidget(
              text: 'Your Cultural Love Signal 💘',
              size: 17,
              color: Colors.white.withOpacity(0.95),
            ),

            SizedBox(height: 4.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: TextWidget(
                text:
                    'Find someone who understands your traditions,\nvalues, and vibe',
                size: 14,
                textAlign: TextAlign.center,
                color: Colors.white.withOpacity(0.85),
              ),
            ),

            SizedBox(height: 5.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: ButtonWidget(
                text: 'Get Started',
                height: 7,
                radius: 32,
                backgroundColor: Colors.white,
                textColor: const Color(0xFFFF6F7D),
                onTap: () {
                  Navigator.push(
                    context,
                    _slideRightToLeft(const SignupScreen()),
                  );
                },
              ),
            ),

            SizedBox(height: 2.h),

            TextWidget(
              text: '✨ 4-minute setup • Find your match today',
              size: 14,
              color: Colors.white.withOpacity(0.85),
            ),

            const Spacer(),

            // 🌍 Cultural Emojis
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🥢', style: TextStyle(fontSize: 18.sp)),
                SizedBox(width: 2.w),
                Text('🧧', style: TextStyle(fontSize: 18.sp)),
                SizedBox(width: 2.w),
                Text('🏺', style: TextStyle(fontSize: 18.sp)),
                SizedBox(width: 2.w),
                Text('👩‍❤️‍👨', style: TextStyle(fontSize: 18.sp)),
                SizedBox(width: 2.w),
                Text('🧋', style: TextStyle(fontSize: 18.sp)),
              ],
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}