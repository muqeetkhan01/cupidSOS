import 'package:cupid_app/onboard/basics_screen.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class VibeCheckScreen extends StatefulWidget {
  const VibeCheckScreen({super.key});

  @override
  State<VibeCheckScreen> createState() => _VibeCheckScreenState();
}

class _VibeCheckScreenState extends State<VibeCheckScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pageController;

  final List<String> vibes = [
    '🧋 Boba',
    '🍜 Ramen',
    '🥟 Dumplings',
    '🍣 Sushi',
    '🍲 Hot Pot',
    '🥡 Takeout',
    '🍛 Curry',
    '🍰 Desserts',
    '☕ Coffee',
    '🍵 Tea',
    '🎮 Gaming',
    '📺 K-Drama',
    '🎬 Anime',
    '🎵 K-Pop',
    '🎤 Karaoke',
    '📚 Manga',
    '🎧 Music',
    '🎨 Art',
    '📸 Photography',
    '🎭 Theater',
    '🏸 Badminton',
    '🏓 Ping Pong',
    '🧘 Yoga',
    '🏋️ Gym',
    '🏃 Running',
    '🚴 Cycling',
    '🏊 Swimming',
    '🎿 Skiing',
    '🥾 Hiking',
    '🧗 Climbing',
    '✨ K-Beauty',
    '👗 Fashion',
    '🀄 Mahjong',
    '🌿 Plants',
    '🐱 Cat Person',
    '🐶 Dog Person',
    '✈️ Travel',
    '🏠 Homebody',
    '📖 Reading',
   
  ];

  final List<String> selected = [];

  bool get isValid => selected.length == 5;

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

  /// 🔥 Page entrance animation
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
          offset: Offset(0, (1 - anim.value) * 28),
          child: child,
        ),
      ),
    );
  }

  Widget _chip(String label) {
    final bool isSelected = selected.contains(label);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selected.remove(label);
          } else if (selected.length < 5) {
            selected.add(label);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFF6F7D),
                    Color(0xFFD86BCF),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD86BCF).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextWidget(
              text: label,
              size: 14,
              weight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black,
            ),
            if (isSelected) ...[
              SizedBox(width: 1.w),
              const Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 1.5.h),

            /// 🔝 Header
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
                    text: 'Step 4 of 7',
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
              child: Column(
                children: const [
                  TextWidget(
                    text: 'Vibe Check 🎯',
                    size: 20,
                    weight: FontWeight.bold,
                  ),
                  SizedBox(height: 8),
                  TextWidget(
                    text: 'Select exactly 5 interests that define you',
                    size: 15,
                    color: Color( 0xFF1E1E1E),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.5.h),

            /// Progress dots
            _animated(
              from: 0.3,
              to: 0.4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < selected.length
                          ? const Color(0xFFD86BCF)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 3.h),

            /// Chips
            Expanded(
              child: _animated(
                from: 0.4,
                to: 0.85,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: vibes.map(_chip).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.h),

            /// CTA BUTTON → BASICS SCREEN
            _animated(
              from: 0.85,
              to: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: ButtonWidget(
                  text: isValid
                      ? 'Continue ✨'
                      : 'Select ${5 - selected.length} more',
                  height: 7,
                  radius: 36,
                  variant: isValid
                      ? ButtonVariant.gradient
                      : ButtonVariant.solid,
                  gradient: isValid
                      ? const [
                          Color(0xFFFF6F7D),
                          Color(0xFFD86BCF),
                        ]
                      : const [
                          Color(0x00000000),
                          Color(0x00000000),
                        ],
                  backgroundColor: isValid
                      ? const Color(0xFFFF6F7D)
                      : Colors.grey.shade300,
                  enableShadow: isValid,
                  onTap: isValid
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BasicsScreen(),
                            ),
                          );
                        }
                      : () {},
                ),
              ),
            ),

            SizedBox(height: 2.5.h),
          ],
        ),
      ),
    );
  }
}
