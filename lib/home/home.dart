import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../config/app_theme.dart';
import '../../fortune/fortune_cookie_repository.dart';
import '../../fortune/fortune_cookie_screen.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _fadeSlide(Widget child, double from, double to) {
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 22),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),

              /// HEADER
              _fadeSlide(
                Row(
                  children: [
                    Expanded(
                      // ✅ prevents overflow
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: 'Good evening 👋',
                            size: 16,
                            color: CupidColors.textSecondary(context),
                          ),
                          SizedBox(height: 2),
                          TextWidget(
                            text: 'Welcome back!',
                            size: 22,
                            weight: FontWeight.bold,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      width: 10.w, // 🔻 reduced from 11.w
                      height: 10.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                0,
                0.15,
              ),

              SizedBox(height: 3.h),

              /// FORTUNE CARD
              _fadeSlide(_fortuneCard(), 0.15, 0.3),

              SizedBox(height: 2.h),

              /// TOP MATCHES
              _fadeSlide(
                _sectionHeader('Top Matches for You', 'See all'),
                0.3,
                0.4,
              ),
              SizedBox(height: 1.5.h),
              _fadeSlide(_topMatches(), 0.35, 0.55),

              /// SOS ACTIONS
              _fadeSlide(_sosActions(), 0.5, 0.65),

              SizedBox(height: 3.h),

              /// ACTIVE SPARKS
              _fadeSlide(
                const TextWidget(
                  text: '⏱ Active Sparks',
                  size: 17,
                  weight: FontWeight.w500,
                ),
                0.6,
                0.7,
              ),
              SizedBox(height: 1.2.h),
              _fadeSlide(_activeSparks(), 0.7, 0.85),

              SizedBox(height: 3.h),

              /// FUN ZONE
              _fadeSlide(
                const TextWidget(
                  text: 'Cupid Fun Zone 🎮',
                  size: 17,
                  weight: FontWeight.w500,
                ),
                0.8,
                0.9,
              ),
              SizedBox(height: 1.5.h),
              _fadeSlide(_funZone(), 0.9, 1),

              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== COMPONENTS =====================

  Widget _fortuneCard() {
    return FutureBuilder<FortuneCookie>(
      future: FortuneCookieRepository.instance.todayDailyFortune(),
      builder: (context, snapshot) {
        final preview =
            snapshot.data?.text ?? 'Your daily cosmic match is ready.';

        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF1DC), Color(0xFFF5E8FF)],
            ),
            boxShadow: [
              BoxShadow(color: CupidColors.shadow(context), blurRadius: 14),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextWidget(
                      text: 'Fortune Cookie Match',
                      size: 16,
                      weight: FontWeight.bold,
                    ),
                    const SizedBox(height: 6),
                    TextWidget(
                      text: preview,
                      size: 13.5,
                      color: CupidColors.textSecondary(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.8.h),
                    ButtonWidget(
                      text: 'Open',
                      height: 5.2,
                      width: 35,
                      radius: 30,
                      variant: ButtonVariant.gradient,
                      gradient: const [Color(0xFFFF6F7D), Color(0xFFFFB25F)],
                      icon: Icons.auto_awesome_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FortuneCookieScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/fortune_cookie_pending.jpeg',
                  width: 28.w,
                  height: 28.w,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextWidget(text: '✨ $title', size: 16, weight: FontWeight.bold),
        TextWidget(text: action, size: 14, color: const Color(0xFFFF6F7D)),
      ],
    );
  }

  /// 🔥 FIXED TOP MATCHES
  Widget _topMatches() {
    return SizedBox(
      height: 26.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _MatchCard(name: 'Sarah, 26', percent: '94%'),
          _MatchCard(name: 'Emily, 24', percent: '88%'),
          _MatchCard(name: 'Jessica, 27', percent: '91%'),
        ],
      ),
    );
  }

  /// 🔥 BORDER ADDED
  Widget _sosActions() {
    return Row(
      children: const [
        Expanded(
          child: _ActionCard(
            icon: Icons.flash_on,
            title: 'SOS Arrow 💘',
            subtitle: 'Send a flirty signal',
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _ActionCard(
            icon: Icons.videocam,
            title: 'SOS Call',
            subtitle: 'Instant video request',
          ),
        ),
      ],
    );
  }

  Widget _activeSparks() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: CupidColors.shadow(context), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(text: 'Sarah Chen', weight: FontWeight.bold),
                TextWidget(
                  text: 'Waiting for your reply...',
                  size: 13,
                  color: CupidColors.textSecondary(context),
                ),
              ],
            ),
          ),
          TextWidget(
            text: '23:45:12',
            size: 14,
            color: Color(0xFFFF9800),
            weight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  /// 🔥 HEIGHT INCREASED
  Widget _funZone() {
    return Row(
      children: const [
        Expanded(
          child: _FunCard(
            title: 'Hotpot or Not 🍲',
            subtitle: 'Cultural icebreaker',
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _FunCard(title: 'Mahjong Match 🀄', subtitle: 'Coming soon'),
        ),
      ],
    );
  }
}

/// ===================== SMALL WIDGETS =====================

class _MatchCard extends StatelessWidget {
  final String name;
  final String percent;
  const _MatchCard({required this.name, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.w,
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          Container(
            height: 18.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TextWidget(
                  text: percent,
                  weight: FontWeight.bold,
                  color: const Color(0xFFFF6F7D),
                ),
              ),
            ),
          ),
          SizedBox(height: 1.h),
          TextWidget(text: name, weight: FontWeight.w500),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CupidColors.border(context)),
        boxShadow: [
          BoxShadow(color: CupidColors.shadow(context), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFECEF),
            child: Icon(icon, color: const Color(0xFFFF6F7D)),
          ),
          SizedBox(height: 1.h),
          TextWidget(text: title, weight: FontWeight.bold),
          TextWidget(
            text: subtitle,
            size: 13,
            color: CupidColors.textSecondary(context),
          ),
        ],
      ),
    );
  }
}

class _FunCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FunCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16.h, // ✅ increased height (important)
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: title.contains('Hotpot')
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE6D6), // peach
                  Color(0xFFFFF1E8),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF1E6FF), // lavender
                  Color(0xFFF8F2FF),
                ],
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🎮 ICON (TOP LEFT)
          Text(
            title.contains('Hotpot') ? '🍲' : '🀄',
            style: const TextStyle(fontSize: 26),
          ),

          SizedBox(height: 1.5.h),

          /// TITLE
          TextWidget(
            text: title.replaceAll(RegExp(r'[🍲🀄]'), '').trim(),
            size: 16,
            weight: FontWeight.bold,
          ),

          SizedBox(height: 0.6.h),

          /// SUBTITLE
          TextWidget(
            text: subtitle,
            size: 13,
            color: CupidColors.textSecondary(context),
          ),
        ],
      ),
    );
  }
}
