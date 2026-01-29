import 'dart:math';
import 'package:cupid_app/Discover/filter.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';

enum ActionType { refresh, reject, boost, like }

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _swipeController;

  Offset _dragOffset = Offset.zero;
  double _rotation = 0;

  int _currentIndex = 0;

  final List<Map<String, dynamic>> _profiles = [
    {
      "name": "Michelle",
      "age": 25,
      "city": "San Francisco",
      "match": "92%",
      "image": "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
      "bio":
          "Tea enthusiast 🍵 | Dog mom 🐶 | Looking for someone to explore new boba spots with",
      "tags": ["Boba", "K-Drama", "Yoga"],
      "zodiac": "Leo",
      "animal": "Rabbit",
    },
    {
      "name": "Emily",
      "age": 24,
      "city": "New York",
      "match": "88%",
      "image": "https://images.unsplash.com/photo-1503342217505-b0a15ec3261c",
      "bio": "Pilates | Matcha | Sunset walks",
      "tags": ["Fitness", "Travel", "Matcha"],
      "zodiac": "Virgo",
      "animal": "Cat",
    },
  ];

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )
      ..addListener(() {
        setState(() {
          _dragOffset =
              Offset.lerp(_dragOffset, _swipeTarget, _swipeController.value)!;
          _rotation = _dragOffset.dx / 300;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextCard();
        }
      });
  }

  Offset _swipeTarget = Offset.zero;

  void _swipe(bool right) {
    _swipeTarget = Offset(right ? 500 : -500, 0);
    _swipeController.forward(from: 0);
  }

  void _nextCard() {
    setState(() {
      _dragOffset = Offset.zero;
      _rotation = 0;
      _currentIndex = (_currentIndex + 1) % _profiles.length;
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profiles[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TextWidget(
                    text: 'Discover',
                    size: 24,
                    weight: FontWeight.bold,
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 400),
                          pageBuilder: (_, __, ___) => const FilterScreen(),
                          transitionsBuilder: (_, animation, __, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.auto_awesome, size: 18),
                          SizedBox(width: 6),
                          TextWidget(text: 'Filters'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// CARD
            Expanded(
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (_, __) {
                  final slide =
                      Tween(begin: const Offset(0, 80), end: Offset.zero)
                          .transform(_entryController.value);

                  return Transform.translate(
                    offset: slide,
                    child: GestureDetector(
                      onPanUpdate: (d) {
                        setState(() {
                          _dragOffset += d.delta;
                          _rotation = _dragOffset.dx / 300;
                        });
                      },
                      onPanEnd: (_) {
                        if (_dragOffset.dx.abs() > 120) {
                          _swipe(_dragOffset.dx > 0);
                        } else {
                          setState(() {
                            _dragOffset = Offset.zero;
                            _rotation = 0;
                          });
                        }
                      },
                      child: Transform.translate(
                        offset: _dragOffset,
                        child: Transform.rotate(
                          angle: _rotation,
                          child: _profileCard(profile),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            /// ACTION BUTTONS
            Padding(
              padding: EdgeInsets.only(
                bottom: 4.h,
                top: 2.h,
                left: 12.w,
                right: 12.w,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _actionButton(
                    type: ActionType.refresh,
                    icon: Icons.refresh,
                    onTap: () {
                      _entryController.forward(from: 0);
                    },
                  ),
                  _actionButton(
                    type: ActionType.reject,
                    icon: Icons.close,
                    onTap: () {
                      _swipe(false);
                    },
                  ),
                  _actionButton(
                    type: ActionType.boost,
                    icon: Icons.flash_on,
                    onTap: () {
                      _swipe(true);
                    },
                  ),
                  _actionButton(
                    type: ActionType.like,
                    icon: Icons.favorite,
                    onTap: () {
                      _swipe(true);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(Map data) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w),
      height: 68.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: DecorationImage(
          image: NetworkImage(data["image"]),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                TextWidget(
                  text: '${data["name"]}, ${data["age"]}',
                  size: 22,
                  weight: FontWeight.bold,
                  color: Colors.white,
                ),
                const Spacer(),
                _matchBadge(data["match"]),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                TextWidget(
                  text: data["city"],
                  size: 13,
                  color: Colors.white70,
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextWidget(
              text: data["bio"],
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: data["tags"]
                  .map<Widget>(
                    (t) => Chip(
                      label: TextWidget(text: t, size: 12),
                      backgroundColor: Colors.white24,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchBadge(String percent) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextWidget(
        text: '$percent match',
        weight: FontWeight.bold,
        color: const Color(0xFFFF6F7D),
      ),
    );
  }

  Widget _actionButton({
    required ActionType type,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool isGradient = type == ActionType.like;
    final bool isBoost = type == ActionType.boost;

    Color? bgColor;
    Gradient? gradient;
    Color iconColor = Colors.grey;

    switch (type) {
      case ActionType.refresh:
        bgColor = Colors.white;
        iconColor = const Color(0xFFFFA000);
        break;

      case ActionType.reject:
        bgColor = Colors.white;
        iconColor = Colors.redAccent;
        break;

      case ActionType.boost:
        bgColor = const Color(0xFFFFC107);
        iconColor = Colors.white;
        break;

      case ActionType.like:
        gradient = const LinearGradient(
          colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconColor = Colors.white;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 14.w,
        height: 14.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gradient == null ? bgColor : null,
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 26),
      ),
    );
  }
}
