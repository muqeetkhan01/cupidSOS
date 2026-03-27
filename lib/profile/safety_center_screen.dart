import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../config/app_theme.dart';
import '../../widgets/text_widget.dart';

class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: CupidColors.scaffold(context),
        elevation: 0,
        title: const TextWidget(
          text: 'Safety on Cupid SOS',
          size: 18,
          weight: FontWeight.w700,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SafetyCard(
              title: 'How to report',
              body:
                  'Use the menu on a profile or inside chat to report, block, or unmatch. Reports are private and reviewed silently by the team.',
            ),
            _SafetyCard(
              title: 'Dating safety tips',
              body:
                  'Take your time, meet in public, tell a friend your plans, and avoid sharing personal information too quickly.',
            ),
            _SafetyCard(
              title: 'Community guidelines',
              body:
                  'Keep it real, lead with kindness, be genuine, and honor connection. If something feels off, trust yourself and report it.',
            ),
            _SafetyCard(
              title: 'You’re in control',
              body:
                  'Blocking removes the connection immediately. Reporting helps protect the community. Unmatching offers a soft exit when you simply want to move on.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  final String title;
  final String body;

  const _SafetyCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.5.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CupidColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(text: title, size: 16, weight: FontWeight.w700),
          SizedBox(height: 0.8.h),
          TextWidget(
            text: body,
            size: 14,
            color: CupidColors.textSecondary(context),
          ),
        ],
      ),
    );
  }
}
