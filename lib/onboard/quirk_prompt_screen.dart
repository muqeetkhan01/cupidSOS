import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/voice_prompt_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class CulturalVibe {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<QuirkItem> prompts;

  const CulturalVibe({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.prompts,
  });
}

class QuirkItem {
  final String emoji;
  final String question;

  const QuirkItem({required this.emoji, required this.question});
}

const List<CulturalVibe> culturalVibes = [
  CulturalVibe(
    title: "Third Culture Kid",
    subtitle: "Born in one place, raised in another.",
    icon: Icons.public,
    prompts: [
      QuirkItem(emoji: "🌍", question: "A culture shock I’ll never forget…"),
      QuirkItem(emoji: "🍜", question: "The meal that always feels like home…"),
      QuirkItem(emoji: "🧳", question: "My accent changes when I…"),
    ],
  ),
  CulturalVibe(
    title: "Homebody Heritage",
    subtitle: "Traditions, family, roots.",
    icon: Icons.home,
    prompts: [
      QuirkItem(emoji: "🫶", question: "A family tradition I actually love…"),
      QuirkItem(emoji: "🎉", question: "My favorite cultural celebration is…"),
      QuirkItem(emoji: "🍲", question: "The dish I’d cook to impress you…"),
    ],
  ),
  CulturalVibe(
    title: "City Blend",
    subtitle: "Modern life, mixed influences.",
    icon: Icons.location_city,
    prompts: [
      QuirkItem(emoji: "☕", question: "My ideal weekend looks like…"),
      QuirkItem(emoji: "🎧", question: "My playlist says I’m…"),
      QuirkItem(emoji: "🕺", question: "The song that makes me dance…"),
    ],
  ),
];

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
      backgroundColor: const Color(0xFFFDF7F5),
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
              const TextWidget(
                text:
                    "Choose the label that defines “home” for you so matches know what you’re about.",
                size: 15,
                color: Colors.grey,
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
                          color:
                              selected ? const Color(0xFFFFECEF) : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFFF6F7D)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFFF6F7D).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(vibe.icon,
                                  color: const Color(0xFFFF6F7D)),
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: vibe.title,
                                    size: 16,
                                    weight: FontWeight.w600,
                                  ),
                                  SizedBox(height: 0.5.h),
                                  TextWidget(
                                    text: vibe.subtitle,
                                    size: 13,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? const Color(0xFFFF6F7D)
                                  : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                    gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
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
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }
}

enum QuirkMode { type }

class QuirkPromptScreen extends StatefulWidget {
  final List<QuirkItem> prompts;
  const QuirkPromptScreen({super.key, required this.prompts});

  @override
  State<QuirkPromptScreen> createState() => _QuirkPromptScreenState();
}

class _QuirkPromptScreenState extends State<QuirkPromptScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();

  late final AnimationController _pageController;
  late final AnimationController _ctaController;

  final TextEditingController _textCtrl = TextEditingController();

  int activeEmoji = 0;

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

    // ✅ Prefill from saved value (resume support)
    final existing = flow.quirkText.value;
    if (existing != null && existing.trim().isNotEmpty) {
      _textCtrl.text = existing;
    }
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

  Future<void> _continue() async {
    flow.quirkText.value = _textCtrl.text.trim();
    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const VoicePromptScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));

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

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompts[activeEmoji];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      text: 'Step 8 of 10',
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              _animated(
                from: 0.15,
                to: 0.3,
                child: TextWidget(
                  text: "Drop a cultural quirk ✨",
                  size: 18.sp,
                  weight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              TextWidget(
                text: "${prompt.emoji}  ${prompt.question}",
                size: 15,
                color: Colors.grey.shade700,
              ),
              SizedBox(height: 3.h),
              _animated(
                from: 0.3,
                to: 0.4,
                child: TextField(
                  controller: _textCtrl,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Type your answer…",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              _animated(
                from: 0.45,
                to: 0.75,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.prompts.length, (i) {
                    final selected = i == activeEmoji;
                    return GestureDetector(
                      onTap: () => setState(() => activeEmoji = i),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? const Color(0xFFFF6F7D)
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: 4.h),
              _animated(
                from: 0.75,
                to: 1,
                child: ButtonWidget(
                  text: 'Continue',
                  height: 7,
                  radius: 36,
                  variant:
                      isValid ? ButtonVariant.gradient : ButtonVariant.solid,
                  gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                  backgroundColor: Colors.grey.shade300,
                  enableShadow: isValid,
                  onTap: isValid ? _continue : () {},
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
