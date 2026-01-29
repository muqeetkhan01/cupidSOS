import 'package:cupid_app/onboard/show_your_story_screen.dart';
import 'package:flutter/material.dart';
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

/// ✅ PARTNER-APPROVED PROMPTS
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
    question:
        'When my dream job gets stressful, I need a partner who...',
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

  void _goTo(int index) {
    setState(() => activeIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            children: [
              SizedBox(height: 1.5.h),

              /// HEADER
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
                      text: 'Step 6 of 7',
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.h),

              /// TITLE
              _animated(
                from: 0.15,
                to: 0.3,
                child: const Column(
                  children: [
                    TextWidget(
                      text: 'Your Voice Prompt 🎙️',
                      size: 20,
                      weight: FontWeight.bold,
                    ),
                    SizedBox(height: 6),
                    TextWidget(
                      text:
                          'Choose one question and record your voice answer.',
                      size: 15,
                      color: Color(0xFF1E1E1E),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              /// PROMPT NAV (EMOJI SAME AS QUIRK UX)
              _animated(
                from: 0.3,
                to: 0.4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    voicePrompts.length,
                    (i) => GestureDetector(
                      onTap: () => _goTo(i),
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 6),
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == activeIndex
                              ? const Color(0xFFFFECEF)
                              : Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          voicePrompts[i].emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 3.h),

              /// PROMPT CARD
              _animated(
                from: 0.4,
                to: 0.6,
                child: Container(
                  width: double.infinity,
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
                        text:
                            '${current.emoji} ${current.title}',
                        size: 16,
                        weight: FontWeight.w600,
                      ),
                      SizedBox(height: 1.h),
                      TextWidget(
                        text: current.question,
                        size: 15,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 3.h),

              /// RECORD SECTION
              _animated(
                from: 0.6,
                to: 0.85,
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(28),
                    border: Border.all(
                        color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const TextWidget(
                        text: '0:00 / 0:30',
                        size: 14,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 1.5.h),
                      const TextWidget(
                        text: 'Tap to start recording',
                        size: 14,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 3.h),
                      Container(
                        width: 20.w,
                        height: 20.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFF6F7D),
                              Color(0xFFD86BCF),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 4.h),

              /// NEXT
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF6F7D),
                        Color(0xFFD86BCF),
                      ],
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward,
                        color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ShowYourStoryScreen(),
                        ),
                      );
                    },
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