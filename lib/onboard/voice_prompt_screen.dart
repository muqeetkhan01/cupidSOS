import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/show_your_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';

class VoicePromptItem {
  final String emoji;
  final String title;
  final String question;

  const VoicePromptItem({
    required this.emoji,
    required this.title,
    required this.question,
  });
}

const List<VoicePromptItem> voicePrompts = [
  VoicePromptItem(
    emoji: '🏮',
    title: 'The Worthy Argument',
    question:
        'What is one thing in a relationship that is actually worth fighting for?',
  ),
  VoicePromptItem(
    emoji: '🛠️',
    title: 'Repairing the House',
    question:
        'When things get tough, are you the type to fix it or start over?',
  ),
  VoicePromptItem(
    emoji: '💼',
    title: 'Stress Support',
    question: 'When my dream job gets stressful, I need a partner who...',
  ),
  VoicePromptItem(
    emoji: '💛',
    title: 'The Extra Mile',
    question:
        'To me, the best way to show someone they are worth the effort is...',
  ),
];

class VoicePromptScreen extends StatefulWidget {
  const VoicePromptScreen({super.key});

  @override
  State<VoicePromptScreen> createState() => _VoicePromptScreenState();
}

class _VoicePromptScreenState extends State<VoicePromptScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();

  late final AnimationController _pageController;
  int activeIndex = 0;

  VoicePromptItem get current => voicePrompts[activeIndex];

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // ✅ Resume selection if already saved
    final saved = flow.voicePromptText.value;
    if (saved != null && saved.isNotEmpty) {
      final idx = voicePrompts.indexWhere(
        (p) => p.question == saved || p.title == saved,
      );
      if (idx >= 0) activeIndex = idx;
    }

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _pageController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
    flow.voicePromptText.value = current.question;
    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShowYourStoryScreen()),
    );
  }

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
              SizedBox(height: 1.5.h),
              _animated(
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
                      text: 'Step 9 of 10',
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
                from: 0,
                to: 0.15,
              ),
              SizedBox(height: 2.h),
              _animated(
                child: TextWidget(
                  text: "Pick a voice prompt 🎙️",
                  size: 18.sp,
                  weight: FontWeight.w600,
                ),
                from: 0.15,
                to: 0.3,
              ),
              SizedBox(height: 1.h),
              _animated(
                child: TextWidget(
                  text: "Choose one — you can record later.",
                  size: 15,
                  color: Colors.grey.shade600,
                ),
                from: 0.2,
                to: 0.35,
              ),
              SizedBox(height: 3.h),
              Expanded(
                child: ListView.separated(
                  itemCount: voicePrompts.length,
                  separatorBuilder: (_, __) => SizedBox(height: 1.6.h),
                  itemBuilder: (_, index) {
                    final p = voicePrompts[index];
                    final selected = index == activeIndex;

                    return GestureDetector(
                      onTap: () => setState(() => activeIndex = index),
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
                            Text(p.emoji, style: const TextStyle(fontSize: 24)),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: p.title,
                                    size: 16,
                                    weight: FontWeight.w600,
                                  ),
                                  SizedBox(height: 0.5.h),
                                  TextWidget(
                                    text: p.question,
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
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: _continue,
                  ),
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
