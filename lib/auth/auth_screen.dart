// lib/auth/auth_screen.dart
import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/vibe_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  final flow = Get.find<AppFlowController>();

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

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _controller.forward();
    });
  }

  void _toggle() {
    setState(() => isSignup = !isSignup);
    flow.clearError();
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

  _submit() async {
    flow.clearError();

    final email = emailCtrl.text.trim();
    final pass = passwordCtrl.text.trim();
    final name = nameCtrl.text.trim();

    if (isSignup) {
      if (name.isEmpty) {
        flow.error.value = "Name is required";
        return;
      }
      final ok = await flow.signup(name: name, email: email, password: pass);
      if (!ok) return;
    } else {
      final ok = await flow.login(email: email, password: pass);
      if (!ok) return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const VibeSelectionScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  // keep your existing _animated + _field widgets ...

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

                // ... keep your existing UI ...

                Obx(() {
                  final err = flow.error.value;
                  if (err == null) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(top: 1.5.h),
                    child: Text(
                      err,
                      style: TextStyle(color: Colors.red, fontSize: 15.sp),
                    ),
                  );
                }),

                SizedBox(height: 3.h),

                Obx(() {
                  final busy = flow.isBusy.value;
                  return ButtonWidget(
                    text: busy
                        ? "Please wait..."
                        : (isSignup ? "Create Account" : "Login"),
                    onTap: busy ? null : _submit(),
                  );
                }),

                SizedBox(height: 2.h),

                GestureDetector(
                  onTap: _toggle,
                  child: TextWidget(
                    text: isSignup
                        ? "Already have an account? Login"
                        : "Don't have an account? Sign up",
                    size: 15,
                    color: Colors.pink,
                    weight: FontWeight.w600,
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
