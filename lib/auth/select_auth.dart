import 'package:cupid_app/auth/BirthdayScreen.dart';
import 'package:cupid_app/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // ⏳ small delay so screen appears blank first
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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

              // 💗 Icon Circle
              _animatedItem(
                start: 0.15,
                end: 0.3,
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      4.w,
                    ), // ✅ rounded corners
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('💖', style: TextStyle(fontSize: 28)),
                ),
              ),

              SizedBox(height: 3.h),

              // Title
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

              // Subtitle
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

              // 🍎 Apple
              _animatedItem(
                start: 0.5,
                end: 0.6,
                child: ButtonWidget(
                  text: 'Continue with Apple',
                  backgroundColor: Colors.black,
                  iconAsset: 'assets/images/apple.png', // ✅ Apple icon
                  onTap: () {},
                ),
              ),

              SizedBox(height: 2.h),

              // 🔵 Google
              _animatedItem(
                start: 0.6,
                end: 0.7,
                child: ButtonWidget(
                  text: 'Continue with Google',
                  variant: ButtonVariant.outline,
                  borderColor: Colors.grey.shade300,
                  textColor: Colors.black,
                  enableShadow: false,
                  iconAsset: 'assets/images/google.png', // ✅ Google icon
                  onTap: () {},
                ),
              ),

              SizedBox(height: 2.h),

              // 📱 Phone
              _animatedItem(
                start: 0.7,
                end: 0.8,
                child: ButtonWidget(
                  text: 'Continue with Phone',
                  variant: ButtonVariant.gradient,
                  gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder: (_, __, ___) => const BirthdayScreen(),
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

              // OR
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

              // Email
              _animatedItem(
                start: 0.9,
                end: 1.0,
                child: GestureDetector(
                  onTap: () {
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

              // Footer
              _animatedItem(
                start: 0.9,
                end: 1.0,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms',
                        style: const TextStyle(
                          color: Color(0xFFFF6F7D), // pink highlight
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: Color(0xFFFF6F7D), // pink highlight
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
