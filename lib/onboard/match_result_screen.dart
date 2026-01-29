import 'package:cupid_app/home/home.dart';
import 'package:cupid_app/onboard/match_loading_screen.dart';
import 'package:cupid_app/widgets/bottomNav.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class MatchResultScreen extends StatefulWidget {
  const MatchResultScreen({super.key});

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _voiceBubble() {
    final bars = List.generate(
      18,
      (i) => Container(
        width: 3,
        height: (i % 6 + 2) * 3.5,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6F7D),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );

    return Container(
      margin: EdgeInsets.only(bottom: 1.2.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          /// PLAY BUTTON
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
              ),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white),
          ),

          SizedBox(width: 3.w),

          /// WAVEFORM
          Expanded(
            child: Row(
              children: bars,
            ),
          ),

          SizedBox(width: 3.w),

          /// DURATION
          const TextWidget(
            text: '0:12',
            size: 12,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _textBubble([bool x = false]) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F4), Color(0xFFFFE6EC)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: 'Sarah’s Opening Move',
            size: 13,
            weight: FontWeight.w600,
            color: Color(0xFFFF6F7D),
          ),
          SizedBox(height: 8),
          TextWidget(
            text: x
                ? "What’s one quality in a partner that makes you feel truly safe being yourself?"
                : "Quick question — are you more of a deep-talks-at-midnight or spontaneous-adventures kind of person?",
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _animated(Widget child, double from, double to) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 3.h),

              /// MATCH PILL
              Center(
                child: _animated(
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.9.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFF7E7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome,
                            size: 18, color: Color(0xFF2E7D32)),
                        SizedBox(width: 6),
                        TextWidget(
                          text: "It's a Match!",
                          size: 14,
                          weight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                  ),
                  0,
                  0.1,
                ),
              ),

              SizedBox(height: 2.h),

              /// TITLE
              _animated(
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    TextWidget(
                      text: 'Congratulations!',
                      size: 22,
                      weight: FontWeight.bold,
                      color: Color(0xFFFF6F7D),
                    ),
                    SizedBox(width: 6),
                    Text('🎉', style: TextStyle(fontSize: 24)),
                  ],
                ),
                0.1,
                0.25,
              ),

              SizedBox(height: 3.h),

              /// ================= MATCH CARD =================
              _animated(
                _matchCard(),
                0.25,
                0.6,
              ),

              SizedBox(height: 2.h),

              /// 24H SPARK
              _animated(_sparkTimer(), 0.6, 0.7),

              SizedBox(height: 2.h),
              SizedBox(height: 2.h),

              /// 💬 TEXTS TITLE
              Row(
                children: const [
                  Icon(Icons.chat, size: 18, color: Color(0xFFFF6F7D)),
                  SizedBox(width: 8),
                  TextWidget(
                    text: 'Texts',
                    size: 16,
                    weight: FontWeight.bold,
                  ),
                ],
              ),

              SizedBox(height: 1.5.h),

              _animated(_textBubble(), 0.7, 0.8),
              SizedBox(height: 1.h),
              _animated(_textBubble(true), 0.7, 0.8),
              SizedBox(height: 1.h),

              SizedBox(height: 2.h),

              /// 🎧 VOICE TITLE
              Row(
                children: const [
                  Icon(Icons.graphic_eq, size: 18, color: Color(0xFFFF6F7D)),
                  SizedBox(width: 8),
                  TextWidget(
                    text: 'Voice',
                    size: 16,
                    weight: FontWeight.bold,
                  ),
                ],
              ),

              SizedBox(height: 1.5.h),

              _voiceBubble(),
              _voiceBubble(),
              _voiceBubble(),

              SizedBox(height: 3.h),

              /// CTA
              ButtonWidget(
                text: 'Reply to Opening Move',
                height: 7,
                radius: 36,
                variant: ButtonVariant.gradient,
                gradient: const [
                  Color(0xFFFF6F7D),
                  Color(0xFFD86BCF),
                ],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomCupidBottomNav(
                              currentIndex: 0,
                            )),
                  );
                },
              ),

              SizedBox(height: 2.h),

              Center(
                child: const TextWidget(
                  text: "Don't let this spark fade ✨",
                  size: 14,
                  color: Colors.grey,
                ),
              ),

              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= MATCH CARD =================

Widget _matchCard() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Stack(
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e',
                height: 42.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(top: 14, right: 14, child: _circleBadge('94%')),
              Positioned(
                  bottom: 16, right: 16, child: _circleIcon(Icons.favorite)),
              Positioned(
                bottom: 20,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextWidget(
                      text: 'Sarah Chen, 26',
                      size: 20,
                      weight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    SizedBox(height: 0.8.h),
                    Row(
                      children: [
                        _tag('✓ Verified'),
                        SizedBox(width: 6),
                        _tag('🐯 Tiger'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// ================= HELPERS =================

Widget _circleBadge(String text) => Container(
      padding: EdgeInsets.all(3.w),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFF4D6D),
      ),
      child: TextWidget(
          text: text, size: 14, weight: FontWeight.bold, color: Colors.white),
    );

Widget _circleIcon(IconData icon) => Container(
      padding: EdgeInsets.all(2.5.w),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFF4D6D),
      ),
      child: Icon(icon, color: Colors.white),
    );

Widget _tag(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: TextWidget(text: text, size: 12, color: Colors.white),
    );

Widget _sparkTimer() => Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12),
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.access_time, color: Color(0xFFFFA000)),
          SizedBox(width: 12),
          Expanded(
            child: TextWidget(
              text: '24-Hour Spark ⚡\nReply within 24 hours to keep the match!',
              size: 14,
            ),
          ),
          TextWidget(
            text: '23:59:59',
            weight: FontWeight.bold,
            color: Color(0xFFFF4D6D),
          ),
        ],
      ),
    );

Widget _openingMove() => Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const TextWidget(
        text:
            'Sarah’s Opening Move:\n\n"I wash my rice exactly 3 times — grandma’s rules! 🍚 How about you?"',
        size: 14,
      ),
    );

/// 🎧 VOICE NOTE WITH WAVEFORM
Widget _voiceNote() {
  final bars = List.generate(
    20,
    (i) => Container(
      width: 3,
      height: (i % 5 + 2) * 4.0,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6F7D),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );

  return Container(
    margin: EdgeInsets.only(bottom: 1.h),
    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
      ],
    ),
    child: Row(
      children: [
        const Icon(Icons.play_arrow, color: Color(0xFFFF6F7D)),
        SizedBox(width: 2.w),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: bars,
          ),
        ),
        SizedBox(width: 2.w),
        const TextWidget(
          text: '0:12',
          size: 12,
          color: Colors.grey,
        ),
      ],
    ),
  );
}
