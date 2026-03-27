import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/show_your_story_screen.dart';
import 'package:cupid_app/onboard/voice_prompt_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class CulturalVibeScreen extends StatefulWidget {
  const CulturalVibeScreen({super.key});

  @override
  State<CulturalVibeScreen> createState() => _CulturalVibeScreenState();
}

class _CulturalVibeScreenState extends State<CulturalVibeScreen> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              TextWidget(
                text: "What’s your cultural vibe?",
                size: 18.sp,
                weight: FontWeight.w500,
              ),
              SizedBox(height: 1.h),
              TextWidget(
                text:
                    "Choose the label that defines “home” for you so matches know what you’re about.",
                size: 15,
                color: CupidColors.textSecondary(context),
              ),
              SizedBox(height: 4.h),
              Expanded(
                child: ListView.separated(
                  itemCount: culturalVibes.length,
                  separatorBuilder: (_, __) => SizedBox(height: 1.6.h),
                  itemBuilder: (_, index) {
                    final vibe = culturalVibes[index];
                    final selected = selectedIndex == index;

                    return GestureDetector(
                      onTap: () => setState(() => selectedIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: selected
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF30212B)
                                  : const Color(0xFFFFECEF))
                              : CupidColors.surface(context),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFFF6F7D)
                                : CupidColors.border(context),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(vibe.emoji,
                                style: const TextStyle(fontSize: 26)),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: vibe.title,
                                    weight: FontWeight.w600,
                                  ),
                                  SizedBox(height: 4),
                                  TextWidget(
                                    text: vibe.description,
                                    size: 13,
                                    color: CupidColors.textSecondary(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShowYourStoryScreen(),
                        ),
                      );
                    },
                    child: const TextWidget(
                      text: 'Skip',
                      color: Color(0xFFFF6F7D),
                    ),
                  ),
                  ButtonWidget(
                    text: 'Continue',
                    height: 4.5,
                    width: 30,
                    radius: 36,
                    variant: selectedIndex != null
                        ? ButtonVariant.gradient
                        : ButtonVariant.solid,
                    gradient: const [
                      Color(0xFFFF6F7D),
                      Color(0xFFD86BCF),
                    ],
                    backgroundColor: Colors.grey.shade300,
                    enableShadow: selectedIndex != null,
                    onTap: selectedIndex != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuirkPromptScreen(
                                  prompts:
                                      culturalVibes[selectedIndex!].prompts,
                                ),
                              ),
                            );
                          }
                        : () {},
                  ),
                ],
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }
}

class CulturalVibe {
  final String title;
  final String description;
  final String emoji;
  final List<QuirkItem> prompts;

  const CulturalVibe({
    required this.title,
    required this.description,
    required this.emoji,
    required this.prompts,
  });
}

final List<CulturalVibe> culturalVibes = [
  CulturalVibe(
    title: 'Local',
    description: 'Born and raised here, regardless of parents’ origin.',
    emoji: '🏠',
    prompts: [
      QuirkItem(
          emoji: '🏡',
          question: 'What makes this place feel like home to you?'),
      QuirkItem(emoji: '🍜', question: 'A local food I’ll always defend is…'),
      QuirkItem(
          emoji: '🗺️',
          question: 'My favorite spot only locals know about is…'),
      QuirkItem(emoji: '🎉', question: 'A local tradition I actually love is…'),
      QuirkItem(emoji: '💬', question: 'Growing up here taught me…'),
    ],
  ),
  CulturalVibe(
    title: 'Studying Abroad',
    description: 'Currently studying outside your home country.',
    emoji: '🎓',
    prompts: [
      QuirkItem(emoji: '✈️', question: 'Moving abroad taught me…'),
      QuirkItem(emoji: '📚', question: 'The biggest culture shock I had was…'),
      QuirkItem(emoji: '☕', question: 'Studying abroad made me addicted to…'),
      QuirkItem(emoji: '👀', question: 'Something I miss from home is…'),
      QuirkItem(emoji: '💭', question: 'Living abroad changed how I see…'),
    ],
  ),
  CulturalVibe(
    title: 'Living Abroad',
    description: 'Living or working outside your home country.',
    emoji: '🌍',
    prompts: [
      QuirkItem(emoji: '🏙️', question: 'Living abroad feels like…'),
      QuirkItem(emoji: '🍽️', question: 'A food I learned to love abroad is…'),
      QuirkItem(emoji: '🤝', question: 'The hardest part of living abroad is…'),
      QuirkItem(emoji: '📞', question: 'Calling home usually means…'),
      QuirkItem(
          emoji: '✨', question: 'Living abroad taught me independence by…'),
    ],
  ),
  CulturalVibe(
    title: '1.5 Generation',
    description: 'Immigrated as a child or teen.',
    emoji: '🧳',
    prompts: [
      QuirkItem(
          emoji: '👶', question: 'Growing up between cultures felt like…'),
      QuirkItem(emoji: '🏫', question: 'School was different because…'),
      QuirkItem(emoji: '🗣️', question: 'At home we spoke…'),
      QuirkItem(emoji: '😅', question: 'Something people assume about me is…'),
      QuirkItem(
          emoji: '💡', question: 'Being 1.5 gen taught me adaptability by…'),
    ],
  ),
  CulturalVibe(
    title: 'Second Generation',
    description: 'Born and raised here, parents from another country.',
    emoji: '🌱',
    prompts: [
      QuirkItem(emoji: '🏠', question: 'Home felt different because…'),
      QuirkItem(emoji: '🍲', question: 'My comfort food growing up was…'),
      QuirkItem(emoji: '🧠', question: 'Balancing cultures taught me…'),
      QuirkItem(emoji: '🎭', question: 'Around family vs friends, I’m…'),
      QuirkItem(emoji: '💬', question: 'I learned identity means…'),
    ],
  ),
  CulturalVibe(
    title: 'Other / Prefer Not to Say',
    description: 'None of the above fits.',
    emoji: '✨',
    prompts: [
      QuirkItem(
          emoji: '🪞',
          question: 'Culture means something different to me because…'),
      QuirkItem(emoji: '🧩', question: 'I don’t fit one box because…'),
      QuirkItem(emoji: '🌈', question: 'My background is best described as…'),
      QuirkItem(emoji: '💭', question: 'What shaped me most was…'),
      QuirkItem(emoji: '🫶', question: 'I connect with people through…'),
    ],
  ),
];

enum QuirkMode { type, voice }

class QuirkItem {
  final String emoji;
  final String question;

  const QuirkItem({required this.emoji, required this.question});
}

class QuirkPromptScreen extends StatefulWidget {
  const QuirkPromptScreen({super.key, this.prompts});

  final List<QuirkItem>? prompts;

  @override
  State<QuirkPromptScreen> createState() => _QuirkPromptScreenState();
}

class _QuirkPromptScreenState extends State<QuirkPromptScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();
  late final AnimationController _pageController;
  late final AnimationController _ctaController;
  QuirkMode mode = QuirkMode.type;

  final TextEditingController _textCtrl = TextEditingController();

  bool _ctaAnimated = false;
  int activeEmoji = 0;

  bool get isValid => _textCtrl.text.trim().isNotEmpty;

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
          color: selected ? null : CupidColors.surface(context),
          border: Border.all(color: CupidColors.border(context)),
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

  late final List<QuirkItem> quirks;

  List<QuirkItem> _defaultPrompts() {
    final culture = (flow.culturalIdentity.value ?? '').trim();
    for (final vibe in culturalVibes) {
      if (vibe.title == culture) return vibe.prompts;
    }
    return culturalVibes.last.prompts;
  }

  @override
  void initState() {
    super.initState();

    quirks = widget.prompts == null || widget.prompts!.isEmpty
        ? _defaultPrompts()
        : widget.prompts!;

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

    _textCtrl.text = (flow.quirkText.value ?? '').trim();
    if (_textCtrl.text.isNotEmpty) {
      _ctaAnimated = true;
      _ctaController.value = 1;
    }

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
  Widget build(BuildContext context) {
    final current = quirks[activeEmoji];

    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
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
                    const TextWidget(text: '16 of 19', size: 14, color: null),
                  ],
                ),
              ),

              SizedBox(height: 4.h),

              _animated(
                from: 0.15,
                to: 0.3,
                child: Column(
                  children: [
                    TextWidget(
                      text: 'Your Quik Prompt 💬',
                      size: 20,
                      weight: FontWeight.bold,
                    ),
                    SizedBox(height: 6),
                    TextWidget(
                      text: 'This becomes your "Opening Move" icebreaker',
                      size: 15,
                      color: CupidColors.textPrimary(context),
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
                            : CupidColors.textSecondary(context),
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
                            : CupidColors.textSecondary(context),
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
                    color: CupidColors.surface(context),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: CupidColors.shadow(context),
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
                                : CupidColors.border(context),
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
                                  color: CupidColors.textSecondary(context),
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
                      backgroundColor: CupidColors.border(context),
                      enableShadow: isValid,
                      onTap: isValid
                          ? () async {
                              flow.quirkText.value = _textCtrl.text.trim();
                              await flow.saveOnboardingProgress();
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(
                                    milliseconds: 500,
                                  ),
                                  pageBuilder: (_, __, ___) =>
                                      const VoicePromptScreen(),
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
            color: selected
                ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF30212B)
                    : const Color(0xFFFFECEF))
                : CupidColors.surfaceMuted(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? const Color(0xFFFF6F7D)
                    : CupidColors.textSecondary(context),
              ),
              SizedBox(width: 1.w),
              TextWidget(
                text: label,
                size: 14,
                weight: FontWeight.w600,
                color: selected
                    ? const Color(0xFFFF6F7D)
                    : CupidColors.textSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
