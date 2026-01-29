import 'dart:ui';

import 'package:cupid_app/onboard/cupid_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class _InProgressDialog extends StatelessWidget {
  const _InProgressDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 8.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ICON
                Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF6F7D),
                        Color(0xFFD86BCF),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '🛠️',
                    style: TextStyle(fontSize: 26),
                  ),
                ),

                SizedBox(height: 3.h),

                /// TITLE
                const TextWidget(
                  text: 'We’re Building Something Beautiful',
                  size: 18,
                  weight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 1.2.h),

                /// MESSAGE
                const TextWidget(
                  text:
                      'The next screens are currently in progress.\n\nThank you for your patience 💖',
                  size: 14,
                  color: Colors.grey,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 3.h),

                /// CTA
                ButtonWidget(
                  text: 'Got it ✨',
                  height: 6,
                  radius: 28,
                  variant: ButtonVariant.gradient,
                  gradient: const [
                    Color(0xFFFF6F7D),
                    Color(0xFFD86BCF),
                  ],
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 7.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 6.h),

              /// 🎉 WELCOME EMOJI / AVATAR
              Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                  ),
                ),
                child: const Center(
                  child: Text(
                    '💖',
                    style: TextStyle(fontSize: 42),
                  ),
                ),
              ),

              SizedBox(height: 4.h),

              /// 👋 TITLE
              const TextWidget(
                text: 'Welcome to Cupid SOS',
                size: 26,
                weight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 1.5.h),

              /// SUBTITLE
              TextWidget(
                text:
                    'Your journey starts here.\nLet’s find someone who truly gets you.',
                size: 15,
                color: Colors.grey.shade700,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 6.h),

              /// PRIMARY CTA
              ButtonWidget(
                text: 'Go to Home 💕',
                height: 7,
                radius: 36,
                variant: ButtonVariant.gradient,
                gradient: const [
                  Color(0xFFFF6F7D),
                  Color(0xFFD86BCF),
                ],
                enableShadow: true,
                onTap: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.25),
                    builder: (_) => const _InProgressDialog(),
                  );
                },
              ),

              SizedBox(height: 2.h),
              ButtonWidget(
                text: 'Start Over?',
                height: 7,
                radius: 36,
                // variant: ButtonVariant.gradient,
                // gradient: const [
                //   Color(0xFFFF6F7D),
                //   Color(0xFFD86BCF),
                // ],
                enableShadow: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CupidSplashScreen(),
                    ),
                  );
                },
              ),

              SizedBox(height: 2.h),

              /// SECONDARY TEXT
              TextWidget(
                text: '✨ Matches curated just for you',
                size: 14,
                color: Colors.grey.shade600,
              ),

              const Spacer(),

              /// FOOTER EMOJIS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('💗', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 12),
                  Text('✨', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 12),
                  Text('🌙', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 12),
                  Text('💫', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 12),
                  Text('💖', style: TextStyle(fontSize: 18)),
                ],
              ),

              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }
}
