// lib/widgets/bottomNav.dart (or wherever this file lives)

import 'package:cupid_app/Discover/discover_screen.dart';
import 'package:cupid_app/chat/chat_list_screen.dart';
import 'package:cupid_app/community/community_hub_screen.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/match/matches_screen.dart';
import 'package:cupid_app/profile/profile_screen.dart';
import 'package:cupid_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/text_widget.dart';

class CustomCupidBottomNav extends StatefulWidget {
  final int currentIndex;
  const CustomCupidBottomNav({super.key, required this.currentIndex});

  @override
  State<CustomCupidBottomNav> createState() => _CustomCupidBottomNavState();
}

class _CustomCupidBottomNavState extends State<CustomCupidBottomNav> {
  late int _currentIndex;

  final auth = AuthService.to;

  /// PAGES
  final List<Widget> _pages = const [
    DiscoverScreen(), // 0
    CommunityHubScreen(), // 1
    MatchesScreen(), // 2
    ChatListScreen(), // 3
    ProfileScreen(), // 4
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;

    // Rebuild on auth state changes so profile pic updates
    ever(auth.firebaseUser, (_) {
      if (mounted) setState(() {});
    });
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    final picUrl = user?.photoURL; // ✅ FirebaseAuth photoURL

    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(left: 3.5.w, right: 3.5.w, bottom: 1.4.h),
        child: Container(
          height: 9.6.h,
          padding: EdgeInsets.symmetric(horizontal: 1.8.w, vertical: 0.8.h),
          decoration: BoxDecoration(
            color: CupidColors.navBar(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: CupidColors.shadow(context),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _navItem(
                  index: 0,
                  label: "Discover",
                  activeIcon: Icons.explore_rounded,
                  inactiveIcon: Icons.explore_outlined,
                ),
              ),
              Expanded(
                child: _navItem(
                  index: 1,
                  label: "Community",
                  activeIcon: Icons.graphic_eq_rounded,
                  inactiveIcon: Icons.graphic_eq_outlined,
                ),
              ),
              Expanded(
                child: _navItem(
                  index: 2,
                  label: "Matches",
                  activeIcon: Icons.favorite_rounded,
                  inactiveIcon: Icons.favorite_border_rounded,
                ),
              ),
              Expanded(
                child: _navItem(
                  index: 3,
                  label: "Chat",
                  activeIcon: Remix.chat_1_fill,
                  inactiveIcon: Remix.chat_1_line,
                  badge: 3,
                ),
              ),
              Expanded(
                child: _navItem(
                  index: 4,
                  label: "Me",
                  picUrl: picUrl,
                  isPic: true,
                  activeIcon: Remix.user_fill,
                  inactiveIcon: Remix.user_line,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    int? badge,
    bool isPic = false,
    String? picUrl,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 7.9.h,
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 0.6.h),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF6F7D).withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 260),
                    scale: 1.2,
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.translationValues(
                        0,
                        isSelected ? -3 : 0,
                        0,
                      ),
                      child: isPic
                          ? _profileIconOrPhoto(
                              isSelected: isSelected,
                              activeIcon: activeIcon,
                              inactiveIcon: inactiveIcon,
                              picUrl: picUrl,
                            )
                          : Icon(
                              isSelected ? activeIcon : inactiveIcon,
                              size: 18.5.sp,
                              color: isSelected
                                  ? const Color(0xFFFF6F7D)
                                  : CupidColors.textSecondary(context),
                            ),
                    ),
                  ),
                  if (badge != null && badge > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF4D6D),
                        ),
                        alignment: Alignment.center,
                        child: TextWidget(
                          text: badge.toString(),
                          size: 10,
                          color: Colors.white,
                          weight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 0.6.h),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: isSelected ? 1 : 0.7,
                child: TextWidget(
                  text: label,
                  size: 11.4,
                  weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFFFF6F7D)
                      : CupidColors.textSecondary(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileIconOrPhoto({
    required bool isSelected,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String? picUrl,
  }) {
    final url = (picUrl ?? "").trim();

    if (url.isEmpty) {
      return CircleAvatar(
        backgroundColor: !isSelected
            ? const Color(0xFFFF6F7D)
            : CupidColors.surface(context),
        radius: 12.5.sp,
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          size: 12.sp,
          color: isSelected ? const Color(0xFFFF6F7D) : Colors.white,
        ),
      );
    }

    return CircleAvatar(
      radius: 12.5.sp,
      backgroundImage: NetworkImage(url),
      backgroundColor: CupidColors.surfaceMuted(context),
      onBackgroundImageError: (_, __) {},
    );
  }
}
