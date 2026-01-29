import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),

              /// HEADER
              const TextWidget(
                text: 'Matches',
                size: 22,
                weight: FontWeight.bold,
              ),
              const SizedBox(height: 6),
              const TextWidget(
                text: 'Your connections await 💕',
                size: 18,
                color: Colors.grey,
              ),

              SizedBox(height: 3.h),

              /// ❤️ LIKED YOU
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  TextWidget(
                    text: '❤️ Liked You (3)',
                    size: 16,
                    weight: FontWeight.w500,
                  ),
                  TextWidget(
                    text: 'Upgrade to see',
                    size: 14,
                    color: Color(0xFFFF6F7D),
                  ),
                ],
              ),

              SizedBox(height: 1.5.h),

              /// BLURRED LIKES ROW
              SizedBox(
                height: 10.h,
                child: Row(
                  children: [
                    _blurCard(),
                    _blurCard(),
                    _blurCard(),
                    _seeAllCard(),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              /// ✅ MUTUAL MATCHES
              const TextWidget(
                text: '✅ Mutual Matches',
                size: 16,
                weight: FontWeight.w500,
              ),

              SizedBox(height: 1.5.h),

              _matchTile(
                name: 'Sarah Chen',
                percent: '94%',
                subtitle: 'Sent you a message...',
                time: '23:45:12',
                hasMessage: true,
              ),

              SizedBox(height: 1.5.h),

              _matchTile(
                name: 'Emily Wong',
                percent: '88%',
                subtitle: 'Active 1h ago',
                hasMessage: false,
              ),

              SizedBox(height: 1.5.h),

              _matchTile(
                name: 'Jessica Liu',
                percent: '91%',
                subtitle: 'Sent you a message...',
                hasMessage: true,
              ),

              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= COMPONENTS =================

  static Widget _blurCard() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              Colors.pink.shade200.withOpacity(0.6),
              Colors.pink.shade100.withOpacity(0.6),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.favorite, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  static Widget _seeAllCard() {
    return Container(
      width: 20.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          TextWidget(
            text: '+3',
            size: 20,
            weight: FontWeight.bold,
            color: Colors.white,
          ),
          SizedBox(height: 4),
          TextWidget(
            text: 'See all',
            size: 13,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  static Widget _matchTile({
    required String name,
    required String percent,
    required String subtitle,
    String? time,
    required bool hasMessage,
  }) {
    return Container(
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          /// AVATAR
          Stack(
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e',
                ),
              ),
              Positioned(
                bottom: 0,
                right: 5,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
              ),
              if (hasMessage)
                Positioned(
                  top: 2,
                  right:0 ,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(width: 3.w),

          /// INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextWidget(
                      text: name,
                      weight: FontWeight.bold,
                    ),
                    const SizedBox(width: 6),
                    TextWidget(
                      text: percent,
                      size: 14,
                      color: const Color(0xFFFF6F7D),
                      weight: FontWeight.bold,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextWidget(
                  text: subtitle,
                  size: 13,
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          /// TIMER
          if (time != null)
            Column(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: Color(0xFFFFA000)),
                const SizedBox(height: 4),
                TextWidget(
                  text: time,
                  size: 13,
                  color: const Color(0xFFFFA000),
                  weight: FontWeight.bold,
                ),
                const TextWidget(
                  text: 'spark left',
                  size: 11,
                  color: Colors.grey,
                ),
              ],
            ),
        ],
      ),
    );
  }
}