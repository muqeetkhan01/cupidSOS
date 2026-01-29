import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  TextWidget(
                    text: 'Profile',
                    size: 20,
                    weight: FontWeight.bold,
                  ),
                  Icon(Icons.settings_outlined),
                ],
              ),

              SizedBox(height: 3.h),

              /// PROFILE CARD
              _profileCard(),

              SizedBox(height: 3.h),

              /// PREMIUM
              _premiumCard(),

              SizedBox(height: 2.h),

              /// INTERESTS
              const TextWidget(
                text: 'My Interests',
                size: 16,
               
              ),
              SizedBox(height: 1.5.h),
              _interests(),

              SizedBox(height: 3.h),

              /// OPTIONS
              _optionTile(
                icon: Icons.workspace_premium_rounded,
                title: 'Upgrade to Gold',
                trailing: '2× visibility',
                trailingColor: const Color(0xFFFF6F7D),
              ),
              _optionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
              ),
              _optionTile(
                icon: Icons.verified_user_outlined,
                title: 'Verification',
                trailing: 'Get verified',
                trailingColor: const Color(0xFFFF6F7D),
              ),
              _optionTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
              ),
              _optionTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
              ),

              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== PROFILE CARD =====================

  Widget _profileCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          /// TOP ROW
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1502685104226-ee32379fefbe',
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF6F7D),
                      ),
                      child: const Icon(Icons.edit,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 4.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  TextWidget(
                    text: 'Alex, 28',
                    size: 18,
                    weight: FontWeight.w500,
                  ),
                  SizedBox(height: 4),
                  TextWidget(
                    text: 'San Francisco, CA',
                    size: 14,
                    color: Colors.grey,
                    weight: FontWeight.w500,
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 2.h),

          /// STATS
          Row(
            children: const [
              Expanded(child: _StatBox('12', 'Matches', Icons.favorite)),
              SizedBox(width: 12),
              Expanded(child: _StatBox('48', 'Likes', Icons.flash_on)),
              SizedBox(width: 12),
              Expanded(child: _StatBox('156', 'Views', Icons.remove_red_eye)),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== PREMIUM =====================

  Widget _premiumCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF1CC),
            Color(0xFFFFF1CC),
          ],
        ),
      ),
      child: Row(
        children: const [
          CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFFFC107),
            child: Icon(Icons.workspace_premium, color: Colors.white),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: 'Unlock Premium',
                  size: 18,
                  weight: FontWeight.w500,
                ),
                SizedBox(height: 4),
                TextWidget(
                  text: 'See who liked you & unlimited matches',
                  size: 13,
                  color: Colors.black54,
                    weight: FontWeight.bold,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  // ===================== INTERESTS =====================

  Widget _interests() {
    final items = ['Boba 🧋', 'K-Drama 📺', 'Badminton 🏸', 'Gaming 🎮', 'Hot Pot 🍲'];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (e) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextWidget(
                text: e,
                size: 15,
                color: const Color(0xFFFF6F7D),
                weight: FontWeight.w500,
              ),
            ),
          )
          .toList(),
    );
  }

  // ===================== OPTIONS =====================

  Widget _optionTile({
    required IconData icon,
    required String title,
    String? trailing,
    Color? trailingColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.6.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: Icon(icon, color: Colors.black87 , size: 26,),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: TextWidget(
                text: title,
                size: 15,
                weight: FontWeight.w500,
              ),
            ),
            if (trailing != null)
              TextWidget(
                text: trailing,
                size: 13,
                color: trailingColor ?? Colors.grey,
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// ===================== SMALL WIDGET =====================

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatBox(this.value, this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFF6F7D)),
          SizedBox(height: 6),
          TextWidget(
            text: value,
            size: 16,
            weight: FontWeight.bold,
          ),
          TextWidget(
            text: label,
            size: 12,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}