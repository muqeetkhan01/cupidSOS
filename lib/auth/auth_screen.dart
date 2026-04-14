import 'dart:async';

import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/services/auth_service.dart';
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

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final phoneCtrl = TextEditingController();
  final codeCtrl = TextEditingController();

  bool _busy = false;
  String? _verificationId;
  String? _error;

  bool get _isCodeStep =>
      _verificationId != null && _verificationId!.trim().isNotEmpty;

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

  @override
  void dispose() {
    _controller.dispose();
    phoneCtrl.dispose();
    codeCtrl.dispose();
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
            offset: Offset(0, (1 - animation.value) * 24),
            child: child,
          ),
        );
      },
    );
  }

  String _normalizedPhone() {
    final raw = phoneCtrl.text.trim();
    const removable = [' ', '(', ')', '-'];
    var compact = raw;
    for (final token in removable) {
      compact = compact.replaceAll(token, '');
    }
    return compact;
  }

  Future<void> _routeAfterAuth() async {
    try {
      final flow = Get.find<AppFlowController>();
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
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Verification succeeded but navigation failed. Please tap back and try again.',
      );
    }
  }

  Future<void> _submit() async {
    if (_busy) return;

    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (_isCodeStep) {
      final code = codeCtrl.text.trim();
      if (code.length < 6) {
        setState(() => _error = 'Enter the 6-digit code we sent you.');
        return;
      }

      setState(() => _busy = true);
      final err = await AuthService.to
          .signInWithSmsCode(
            verificationId: _verificationId!,
            smsCode: code,
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () =>
                'Verification is taking too long. Please try again.',
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = err;
      });

      if (err == null) {
        await _routeAfterAuth();
      }
      return;
    }

    final phone = _normalizedPhone();
    if (!phone.startsWith('+') || phone.length < 8) {
      setState(
        () => _error = 'Enter your phone number with country code, like +1...',
      );
      return;
    }

    setState(() => _busy = true);
    final err = await AuthService.to
        .sendPhoneCode(
          phoneNumber: phone,
          onCodeSent: (verificationId) {
            if (!mounted) return;
            setState(() => _verificationId = verificationId);
          },
        )
        .timeout(
          const Duration(seconds: 45),
          onTimeout: () => 'Sending code is taking too long. Please try again.',
        );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });

    if (err == null && AuthService.to.currentUser != null) {
      await _routeAfterAuth();
    }
  }

  void _editPhoneNumber() {
    setState(() {
      _verificationId = null;
      codeCtrl.clear();
      _error = null;
    });
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final context = this.context;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 1.4),
        );

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: CupidColors.surface(context),
        border: border(CupidColors.border(context)),
        enabledBorder: border(CupidColors.border(context)),
        focusedBorder: border(const Color(0xFFFF6F7D)),
        labelStyle: TextStyle(color: CupidColors.textSecondary(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caption = _isCodeStep
        ? 'Enter the 6-digit code we texted to ${phoneCtrl.text.trim()}.'
        : 'We’ll text you a quick verification code to get started.';

    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.h),
                _animatedItem(
                  start: 0,
                  end: 0.15,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: _busy ? null : () => Navigator.pop(context),
                  ),
                ),
                SizedBox(height: 4.h),
                _animatedItem(
                  start: 0.15,
                  end: 0.3,
                  child: Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFE2EA), Color(0xFFF5DFFF)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.phone_iphone_rounded,
                      color: Color(0xFFFF6F7D),
                      size: 30,
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                _animatedItem(
                  start: 0.25,
                  end: 0.4,
                  child: TextWidget(
                    text: _isCodeStep
                        ? 'Enter verification code'
                        : 'Sign in with Phone Number',
                    size: 22,
                    weight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                _animatedItem(
                  start: 0.35,
                  end: 0.5,
                  child: TextWidget(
                    text: caption,
                    size: 15,
                    color: CupidColors.textSecondary(context),
                  ),
                ),
                SizedBox(height: 4.h),
                _animatedItem(
                  start: 0.45,
                  end: 0.65,
                  child: _field(
                    label: 'Phone number',
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                SizedBox(height: 1.6.h),
                if (_isCodeStep)
                  _animatedItem(
                    start: 0.55,
                    end: 0.75,
                    child: _field(
                      label: 'Verification code',
                      controller: codeCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                if (_error != null && _error!.trim().isNotEmpty) ...[
                  SizedBox(height: 1.6.h),
                  _animatedItem(
                    start: 0.65,
                    end: 0.82,
                    child: TextWidget(
                      text: _error!,
                      size: 14,
                      color: Colors.red,
                    ),
                  ),
                ],
                SizedBox(height: 3.h),
                _animatedItem(
                  start: 0.75,
                  end: 0.92,
                  child: ButtonWidget(
                    text: _busy
                        ? 'Please wait...'
                        : (_isCodeStep ? 'Verify and Continue' : 'Send Code'),
                    variant: ButtonVariant.gradient,
                    gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                    onTap: _busy ? () {} : _submit,
                  ),
                ),
                if (_isCodeStep) ...[
                  SizedBox(height: 1.6.h),
                  Center(
                    child: GestureDetector(
                      onTap: _busy ? null : _editPhoneNumber,
                      child: TextWidget(
                        text: 'Edit phone number',
                        size: 14,
                        color: CupidColors.textSecondary(context),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 6.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
