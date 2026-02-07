// lib/onboard/cupid_splash_screen.dart

import 'dart:math';

import 'package:cupid_app/auth/select_auth.dart';
import 'package:cupid_app/config/flow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

class CupidSplashScreen extends StatefulWidget {
  const CupidSplashScreen({super.key});

  @override
  State<CupidSplashScreen> createState() => _CupidSplashScreenState();
}

class _CupidSplashScreenState extends State<CupidSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  bool _routing = false;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _maybeAutoRoute();
  }

  Future<void> _maybeAutoRoute() async {
    if (_routing) return;
    _routing = true;

    final flow = Get.find<AppFlowController>();

    // If user is already logged in, route immediately.
    if (flow.isLoggedIn) {
      final next = await flow.getPostAuthRoute();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => next),
      );
    }

    _routing = false;
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

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
                    Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Image.asset(
                      'assets/images/heart.png',
                      width: 15.w,
                      height: 15.w,
                      color: Colors.white,
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
            const Spacer(),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}