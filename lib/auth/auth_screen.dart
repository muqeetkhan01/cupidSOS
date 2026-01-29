import 'package:cupid_app/onboard/vibe_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;

  bool isSignup = false;

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    // blank → animate in
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _controller.forward();
    });
  }

  void _toggle() {
    setState(() => isSignup = !isSignup);
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  // 🎞️ stagger animation
  Widget _animated({
    required Widget child,
    required double from,
    required double to,
  }) {
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

  Widget _field(
    String hint,
    TextEditingController c, {
    bool obscure = false,
  }) {
    return Container(
      height: 6.5.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 18),
          border: InputBorder.none,
        ),
      ),
    );
  }

  void _goToVibeScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const VibeSelectionScreen(),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 4.h),

                // 💗 LOGO
                _animated(
                  from: 0.0,
                  to: 0.2,
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
                    child: Text(
                      isSignup ? '💖' : '🔐',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),

                SizedBox(height: 3.h),

                // TITLE
                _animated(
                  from: 0.2,
                  to: 0.35,
                  child: TextWidget(
                    text: isSignup ? 'Create Account' : 'Welcome Back',
                    size: 22,
                    weight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 1.h),

                _animated(
                  from: 0.35,
                  to: 0.45,
                  child: TextWidget(
                    text: isSignup
                        ? 'Start your love journey ✨'
                        : 'Login to continue 💫',
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),

                SizedBox(height: 4.h),

                if (isSignup)
                  _animated(
                    from: 0.45,
                    to: 0.55,
                    child: _field('Full Name', nameCtrl),
                  ),

                if (isSignup) SizedBox(height: 2.h),

                _animated(
                  from: isSignup ? 0.55 : 0.45,
                  to: isSignup ? 0.65 : 0.55,
                  child: _field('Email', emailCtrl),
                ),

                SizedBox(height: 2.h),

                _animated(
                  from: isSignup ? 0.65 : 0.55,
                  to: isSignup ? 0.75 : 0.65,
                  child: _field('Password', passwordCtrl, obscure: true),
                ),

                SizedBox(height: 4.h),

                // 🚀 CTA → VIBE SCREEN
                _animated(
                  from: 0.75,
                  to: 0.9,
                  child: ButtonWidget(
                    text: isSignup ? 'Sign Up' : 'Login',
                    variant: ButtonVariant.gradient,
                    gradient: const [
                      Color(0xFFFF6F7D),
                      Color(0xFFD86BCF),
                    ],
                    onTap: _goToVibeScreen,
                  ),
                ),

                SizedBox(height: 2.h),

                // TOGGLE
                _animated(
                  from: 0.9,
                  to: 1.0,
                  child: GestureDetector(
                    onTap: _toggle,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.grey,
                        ),
                        children: [
                          TextSpan(
                            text: isSignup
                                ? 'Already have an account? '
                                : 'Create New Account? ',
                          ),
                          TextSpan(
                            text: isSignup ? 'Login' : 'Sign up',
                            style: const TextStyle(
                              color: Color(0xFFFF6F7D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
