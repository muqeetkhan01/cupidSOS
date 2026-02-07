import 'package:cupid_app/Discover/discover_screen.dart';
import 'package:cupid_app/chat/chat_list_screen.dart';
import 'package:cupid_app/config/colors.dart';
import 'package:cupid_app/match/matches_screen.dart';
import 'package:cupid_app/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';

class CustomCupidBottomNav extends StatefulWidget {
  final int currentIndex;
  const CustomCupidBottomNav({super.key, required this.currentIndex});

  @override
  State<CustomCupidBottomNav> createState() => _CustomCupidBottomNavState();
}

class _CustomCupidBottomNavState extends State<CustomCupidBottomNav>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  /// PAGES
  final List<Widget> _pages = const [
    DiscoverScreen(), // 0
    MatchesScreen(), // 1
    ChatListScreen(), // 2
    ProfileScreen(), // 3
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 2.h),
        child: Container(
          height: 9.h,
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navItem(
                index: 0,
                label: "Discover",
                activeIcon: Icons.explore_rounded,
                inactiveIcon: Icons.explore_outlined,
              ),
              _navItem(
                index: 1,
                label: "Matches",
                activeIcon: Icons.favorite_rounded,
                inactiveIcon: Icons.favorite_border_rounded,
              ),
              _navItem(
                index: 2,
                label: "Chat",
                activeIcon: Remix.chat_1_fill,
                inactiveIcon: Remix.chat_1_line,
                badge: 3,
              ),
              _navItem(
                index: 3,
                label: "Me",
                picUrl: currentUser?.photoUrl,
                isPic: true,
                activeIcon: Remix.user_fill,
                inactiveIcon: Remix.user_line,
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
        padding: const EdgeInsets.all(5.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: 18.w,
          padding: EdgeInsets.symmetric(vertical: 1.h),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF6F7D).withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 260),
                    scale: isSelected ? 1.2 : 1.2,
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      transform:
                          Matrix4.translationValues(0, isSelected ? -3 : 0, 0),
                      child: picUrl == null && isPic
                          ? CircleAvatar(
                              backgroundColor: !isSelected
                                  ? const Color(0xFFFF6F7D)
                                  : Colors.white,
                              radius: 15.sp,
                              child: Icon(
                                isSelected ? activeIcon : inactiveIcon,
                                size: 15.sp,
                                color: isSelected
                                    ? const Color(0xFFFF6F7D)
                                    : Colors.white,
                              ),
                            )
                          : picUrl != null && isPic
                              ? CircleAvatar(
                                  radius: 15.sp,
                                  backgroundImage: NetworkImage(picUrl),
                                )
                              : Icon(
                                  isSelected ? activeIcon : inactiveIcon,
                                  size: 20.sp,
                                  color: isSelected
                                      ? const Color(0xFFFF6F7D)
                                      : Colors.grey.shade500,
                                ),
                      //  Icon(
                      //   isSelected ? activeIcon : inactiveIcon,
                      //   size: 20.sp,
                      //   color: isSelected
                      //       ? const Color(0xFFFF6F7D)
                      //       : Colors.grey.shade500,
                      // ),
                    ),
                  ),

                  /// BADGE
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
                  size: 14.sp,
                  weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFFFF6F7D)
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
