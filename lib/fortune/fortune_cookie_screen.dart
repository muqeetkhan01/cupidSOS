import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/fortune/fortune_cookie_repository.dart';
import 'package:cupid_app/widgets/button_widget.dart';
import 'package:cupid_app/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class FortuneCookieScreen extends StatefulWidget {
  const FortuneCookieScreen({super.key});

  @override
  State<FortuneCookieScreen> createState() => _FortuneCookieScreenState();
}

class _FortuneCookieScreenState extends State<FortuneCookieScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Future<FortuneCookie> _fortuneFuture;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0,
      upperBound: 1,
    )..repeat(reverse: true);
    _fortuneFuture = FortuneCookieRepository.instance.todayDailyFortune();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openCookie() async {
    if (_opened) return;
    await HapticFeedback.lightImpact();
    await SystemSound.play(SystemSoundType.click);
    if (mounted) {
      setState(() => _opened = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      body: SafeArea(
        child: FutureBuilder<FortuneCookie>(
          future: _fortuneFuture,
          builder: (context, snapshot) {
            final fortune = snapshot.data;

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: CupidColors.pageGradient(context),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(5.w, 1.5.h, 5.w, 4.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topBar(context),
                    SizedBox(height: 2.5.h),
                    const TextWidget(
                      text: 'Fortune Cookie Match',
                      size: 25,
                      weight: FontWeight.w800,
                    ),
                    SizedBox(height: 0.8.h),
                    TextWidget(
                      text: _opened
                          ? 'Your daily fortune is ready.'
                          : 'Tap the glowing cookie to reveal today.',
                      size: 14,
                      color: CupidColors.textSecondary(context),
                    ),
                    SizedBox(height: 3.h),
                    _cookieStage(fortune),
                    SizedBox(height: 3.h),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      child: _opened && fortune != null
                          ? _fortuneScroll(fortune.text)
                          : _closedCopy(snapshot.connectionState),
                    ),
                    SizedBox(height: 3.h),
                    ButtonWidget(
                      text: _opened ? 'Revealed' : 'Crack open',
                      height: 5.8,
                      radius: 30,
                      variant: ButtonVariant.gradient,
                      gradient: const [
                        Color(0xFFFF6F7D),
                        Color(0xFFFFC36A),
                      ],
                      icon: _opened
                          ? Icons.auto_awesome
                          : Icons.touch_app_rounded,
                      onTap: _openCookie,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: CupidColors.surface(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CupidColors.border(context)),
          ),
          child: const TextWidget(
            text: 'Daily',
            size: 12.5,
            weight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _cookieStage(FortuneCookie? fortune) {
    return GestureDetector(
      onTap: _openCookie,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glow = 0.35 + (_pulseController.value * 0.25);
          final scale = _opened ? 1.0 : 1 + (_pulseController.value * 0.025);

          return Transform.scale(
            scale: scale,
            child: Container(
              height: 34.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8BA1).withValues(alpha: glow),
                    blurRadius: 42,
                    spreadRadius: 4,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                child: Image.asset(
                  _opened
                      ? 'assets/images/fortune_cookie_reveal.jpeg'
                      : 'assets/images/fortune_cookie_pending.jpeg',
                  key: ValueKey(_opened),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _closedCopy(ConnectionState state) {
    return Container(
      key: const ValueKey('closed-copy'),
      width: double.infinity,
      padding: EdgeInsets.all(4.5.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CupidColors.border(context)),
        boxShadow: [
          BoxShadow(color: CupidColors.shadow(context), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFC36A), Color(0xFFFF6F7D)],
              ),
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: TextWidget(
              text: state == ConnectionState.waiting
                  ? 'Preparing your fortune...'
                  : 'A fresh love fortune is waiting inside.',
              size: 14,
              weight: FontWeight.w600,
              color: CupidColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fortuneScroll(String text) {
    return Container(
      key: const ValueKey('fortune-scroll'),
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFC36A).withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(color: CupidColors.shadow(context), blurRadius: 14),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextWidget(
            text: 'Today says',
            size: 13,
            weight: FontWeight.w700,
            color: Color(0xFFFF6F7D),
          ),
          SizedBox(height: 1.h),
          TextWidget(
            text: text,
            size: 19,
            weight: FontWeight.w700,
            height: 1.35,
          ),
        ],
      ),
    );
  }
}
