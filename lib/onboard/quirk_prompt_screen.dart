import 'package:cupid_app/onboard/show_your_story_screen.dart';
import 'package:cupid_app/onboard/voice_prompt_screen.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

enum QuirkMode { type, voice }

class QuirkItem {
  final String emoji;
  final String question;

  const QuirkItem({required this.emoji, required this.question});
}

class QuirkPromptScreen extends StatefulWidget {
  const QuirkPromptScreen({super.key});

  @override
  State<QuirkPromptScreen> createState() => _QuirkPromptScreenState();
}

class _QuirkPromptScreenState extends State<QuirkPromptScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pageController;
  late final AnimationController _ctaController;
  QuirkMode mode = QuirkMode.type;

  final TextEditingController _textCtrl = TextEditingController();

  bool _ctaAnimated = false;
  int activeEmoji = 0;

  final List<QuirkItem> quirks = const [
    QuirkItem(emoji: '🏠', question: 'My ideal Sunday looks like...'),
    QuirkItem(emoji: '🥢', question: 'A food I could eat forever is...'),
    QuirkItem(emoji: '👨‍👩‍👧', question: 'Family matters most when...'),
    QuirkItem(emoji: '💭', question: 'I knew I was ready for love when...'),
  ];

  bool get isValid => _textCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ctaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _pageController.forward();
    });

    _textCtrl.addListener(() {
      if (isValid && !_ctaAnimated) {
        _ctaAnimated = true;
        _ctaController.forward();
      }
      if (!isValid && _ctaAnimated) {
        _ctaAnimated = false;
        _ctaController.reverse();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ctaController.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Widget _animated({
    required Widget child,
    required double from,
    required double to,
  }) {
    final anim = CurvedAnimation(
      parent: _pageController,
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

  void _goToEmoji(int index) {
    setState(() {
      activeEmoji = index;
      _textCtrl.clear();
    });
  }

  Widget _emojiToggle(int index) {
    final selected = index == activeEmoji;

    return GestureDetector(
      onTap: () => _goToEmoji(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                )
              : null,
          color: selected ? null : Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD86BCF).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Text(quirks[index].emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = quirks[activeEmoji];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            children: [
              SizedBox(height: 1.5.h),

              _animated(
                from: 0,
                to: 0.15,
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
                    const TextWidget(
                      text: 'Step 5 of 7',
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.h),

              _animated(
                from: 0.15,
                to: 0.3,
                child: const Column(
                  children: [
                    TextWidget(
                      text: 'Your Quirk Prompt 💬',
                      size: 20,
                      weight: FontWeight.bold,
                    ),
                    SizedBox(height: 6),
                    TextWidget(
                      text: 'This becomes your "Opening Move" icebreaker',
                      size: 15,
                      color: Color(0xFF1E1E1E),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              /// EMOJI TOGGLES
              _animated(
                from: 0.3,
                to: 0.4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    quirks.length,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _emojiToggle(i),
                    ),
                  ),
                ),
              ),

              /// 🔹 SKIP / NEXT (EMOJI NAV)
              Padding(
                padding: EdgeInsets.only(top: 1.5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: activeEmoji < quirks.length - 1
                          ? () => _goToEmoji(activeEmoji + 1)
                          : null,
                      child: TextWidget(
                        text: 'Skip',
                        size: 14,
                        color: activeEmoji > 0
                            ? const Color(0xFFFF6F7D)
                            : Colors.grey.shade400,
                      ),
                    ),
                    GestureDetector(
                      onTap: activeEmoji < quirks.length - 1
                          ? () => _goToEmoji(activeEmoji + 1)
                          : null,
                      child: TextWidget(
                        text: 'Next',
                        size: 14,
                        color: activeEmoji < quirks.length - 1
                            ? const Color(0xFFFF6F7D)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              /// PROMPT CARD
              _animated(
                from: 0.4,
                to: 0.65,
                child: Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: '${current.emoji} ${current.question}',
                        size: 17,
                        weight: FontWeight.w500,
                      ),
                      SizedBox(height: 2.h),

                      /// TYPE / VOICE TOGGLE (ADDED)
                      // Row(
                      //   children: [
                      //     _modeToggle(
                      //       QuirkMode.type,
                      //       Icons.chat_bubble_outline,
                      //       'Type',
                      //       () {},
                      //     ),
                      //     SizedBox(width: 2.w),
                      //     _modeToggle(
                      //       QuirkMode.voice,
                      //       Icons.mic_none,
                      //       'Voice',
                      //       () {
                      //         MaterialPageRoute(
                      //           builder: (context) => const VoicePromptScreen(),
                      //         );
                      //       },
                      //     ),
                      //   ],
                      // ),

                      // SizedBox(height: 2.h),

                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isValid
                                ? const Color(0xFFFF6F7D)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _textCtrl,
                              maxLength: 150,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Finish the sentence...',
                                counterText: '',
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextWidget(
                                  text: '${_textCtrl.text.length}/150',
                                  size: 13,
                                  color: Colors.grey,
                                ),
                                if (_textCtrl.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: _textCtrl.clear,
                                    child: const TextWidget(
                                      text: 'Clear',
                                      size: 13,
                                      color: Color(0xFFFF6F7D),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// PREVIEW
              if (isValid)
                Padding(
                  padding: EdgeInsets.only(top: 2.5.h),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF3D8), Color(0xFFFFE8C2)],
                      ),
                    ),
                    child: TextWidget(
                      text: 'Preview on your profile:\n"${_textCtrl.text}"',
                      size: 15,
                      color: const Color(0xFF8A5A2B),
                    ),
                  ),
                ),

              SizedBox(height: 5.h),

              /// CTA
              AnimatedBuilder(
                animation: _ctaController,
                builder: (_, __) {
                  final scale = 1 + (_ctaController.value * 0.04);
                  return Transform.scale(
                    scale: scale,
                    child: ButtonWidget(
                      text: 'Continue ✨',
                      height: 7,
                      radius: 36,
                      variant: isValid
                          ? ButtonVariant.gradient
                          : ButtonVariant.solid,
                      gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                      backgroundColor: Colors.grey.shade300,
                      enableShadow: isValid,
                      onTap: isValid
                          ? () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(
                                    milliseconds: 500,
                                  ),
                                  pageBuilder: (_, __, ___) =>
                                      const ShowYourStoryScreen(),
                                  transitionsBuilder:
                                      (_, animation, __, child) {
                                    final tween = Tween(
                                      begin: const Offset(0, 0.06),
                                      end: Offset.zero,
                                    ).chain(
                                      CurveTween(
                                        curve: Curves.easeOutCubic,
                                      ),
                                    );

                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                          : () {},
                    ),
                  );
                },
              ),

              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeToggle(QuirkMode m, IconData icon, String label, ontap) {
    final selected = mode == m;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => mode = m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 5.5.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? const Color(0xFFFFECEF) : const Color(0xFFF1F1F1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? const Color(0xFFFF6F7D) : Colors.grey,
              ),
              SizedBox(width: 1.w),
              TextWidget(
                text: label,
                size: 14,
                weight: FontWeight.w600,
                color: selected ? const Color(0xFFFF6F7D) : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
