// lib/auth/auth_screen.dart
// Fix: do NOT hardcode VibeSelectionScreen after login/signup.
// Route with AppFlowController.getPostAuthRoute().

import 'package:cupid_app/config/flow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

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

  Future<void> _submit() async {
    flow.clearError();

    final email = emailCtrl.text.trim();
    final pass = passwordCtrl.text.trim();
    final name = nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      flow.error.value = "Email and password are required";
      return;
    }

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

    final next = await flow.getPostAuthRoute();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => next,
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

  // NOTE: UI below unchanged except button action now calls _submit()

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
                TextWidget(
                  text: isSignup ? "Create account" : "Welcome back",
                  size: 22,
                  weight: FontWeight.bold,
                ),
                SizedBox(height: 2.h),
                if (isSignup)
                  _field(
                    label: "Name",
                    controller: nameCtrl,
                  ),
                _field(
                  label: "Email",
                  controller: emailCtrl,
                ),
                _field(
                  label: "Password",
                  controller: passwordCtrl,
                  obscure: true,
                ),
                SizedBox(height: 2.h),
                Obx(() {
                  final err = flow.error.value;
                  if (err == null || err.isEmpty)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: TextWidget(
                      text: err,
                      size: 14,
                      color: Colors.red,
                    ),
                  );
                }),
                Obx(() {
                  final busy = flow.isBusy.value;
                  return ButtonWidget(
                    text: busy
                        ? "Please wait..."
                        : (isSignup ? "Sign up" : "Log in"),
                    variant: ButtonVariant.gradient,
                    gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                    onTap: busy ? () {} : _submit,
                  );
                }),
                SizedBox(height: 2.h),
                GestureDetector(
                  onTap: _toggle,
                  child: TextWidget(
                    text: isSignup
                        ? "Already have an account? Log in"
                        : "New here? Create account",
                    size: 15,
                    color: const Color(0xFFFF6F7D),
                    weight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    const borderColor = Color(0xFFFF6F7D);

    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 1.6),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: border(Colors.grey.shade300), // fallback
          enabledBorder: border(borderColor), // ✅ enabled
          focusedBorder: border(borderColor), // ✅ focused
        ),
      ),
    );
  }
}
