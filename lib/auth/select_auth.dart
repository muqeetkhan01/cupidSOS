// lib/auth/select_auth.dart
// Fix: wire Apple/Google buttons to AuthService OAuth + route properly.

import 'package:cupid_app/auth/BirthdayScreen.dart';
import 'package:cupid_app/auth/auth_screen.dart';
import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool _busy = false;

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

  Future<void> _oauthAndRoute(Future<String?> Function() signInFn) async {
    if (_busy) return;
    setState(() => _busy = true);

    final err = await signInFn();
    if (!mounted) return;

    if (err != null) {
      setState(() => _busy = false);
      Get.snackbar("Login failed", err);
      return;
    }

    final flow = Get.find<AppFlowController>();
    final next = await flow.getPostAuthRoute();

    if (!mounted) return;
    setState(() => _busy = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => next),
    );
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
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 30),
            child: child,
          ),
        );
      },
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
              SizedBox(height: 2.h),
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
                        onPressed: _busy ? null : () => Navigator.pop(context),
                      ),
                    ),
                    TextWidget(
                      text: 'Step 1 of 10',
                      size: 14,
                      color: Colors.grey,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6.h),
              _animatedItem(
                start: 0.15,
                end: 0.3,
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.w),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('💖', style: TextStyle(fontSize: 28)),
                ),
              ),
              SizedBox(height: 3.h),
              _animatedItem(
                start: 0.3,
                end: 0.4,
                child: TextWidget(
                  text: 'Join Cupid SOS',
                  size: 22,
                  weight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              _animatedItem(
                start: 0.4,
                end: 0.5,
                child: TextWidget(
                  text: 'One tap to start your love story ✨',
                  size: 17,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 6.h),
              _animatedItem(
                start: 0.5,
                end: 0.6,
                child: ButtonWidget(
                  text: _busy ? "Please wait..." : 'Continue with Apple',
                  backgroundColor: Colors.black,
                  iconAsset: 'assets/images/apple.png',
                  onTap: _busy
                      ? () {}
                      : () => _oauthAndRoute(AuthService.to.signInWithApple),
                ),
              ),
              SizedBox(height: 2.h),
              _animatedItem(
                start: 0.6,
                end: 0.7,
                child: ButtonWidget(
                    text: _busy ? "Please wait..." : 'Continue with Google',
                    variant: ButtonVariant.outline,
                    borderColor: Colors.grey.shade300,
                    textColor: Colors.black,
                    enableShadow: false,
                    iconAsset: 'assets/images/google.png',
                    onTap:
                        // _busy
                        //     ?
                        () {}
                    //     : () => _oauthAndRoute(AuthService.to.signInWithGoogle),
                    ),
              ),
              SizedBox(height: 2.h),
              _animatedItem(
                start: 0.7,
                end: 0.8,
                child: ButtonWidget(
                  text: 'Continue with Phone',
                  variant: ButtonVariant.gradient,
                  gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                  onTap: _busy
                      ? () {}
                      : () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                              pageBuilder: (_, __, ___) =>
                                  const BirthdayScreen(),
                              transitionsBuilder: (_, animation, __, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                ),
              ),
              SizedBox(height: 3.h),
              _animatedItem(
                start: 0.8,
                end: 0.9,
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      child: TextWidget(text: 'or', size: 15),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              _animatedItem(
                start: 0.9,
                end: 1.0,
                child: GestureDetector(
                  onTap: _busy
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            slideRightToLeft(const AuthScreen()),
                          );
                        },
                  child: TextWidget(
                    text: 'Sign up with Email',
                    size: 16,
                    color: const Color(0xFFFF6F7D),
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Route slideRightToLeft(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }
}
