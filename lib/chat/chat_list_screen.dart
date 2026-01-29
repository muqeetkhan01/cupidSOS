import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/text_widget.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),

              /// HEADER
              const TextWidget(
                text: "Messages",
                size: 22,
                weight: FontWeight.bold,
              ),
              SizedBox(height: 0.5.h),
              TextWidget(
                text: "Your conversations 💬",
                size: 16,
                color: Colors.grey.shade600,
              ),

              SizedBox(height: 3.h),

              /// CHAT LIST
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    _ChatTile(
                      name: "Sarah Chen",
                      message: "I'm so down! When are you free?",
                      time: "2:48 PM",
                      image:
                          "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
                      unread: 2,
                      online: true,
                    ),
                    _ChatTile(
                      name: "Emily Wong",
                      message: "That K-drama was amazing!",
                      time: "Yesterday",
                      image:
                          "https://images.unsplash.com/photo-1503342217505-b0a15ec3261c",
                      unread: 0,
                      online: true,
                    ),
                    _ChatTile(
                      name: "Jessica Liu",
                      message: "Let's grab hotpot soon 🍜",
                      time: "2 days ago",
                      image:
                          "https://images.unsplash.com/photo-1524250502761-1ac6f2e30d43",
                      unread: 1,
                      online: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= CHAT TILE =================

class _ChatTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final String image;
  final int unread;
  final bool online;

  const _ChatTile({
    required this.name,
    required this.message,
    required this.time,
    required this.image,
    required this.unread,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            /// AVATAR
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(image),
                ),
                if (online)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3DDC84),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(width: 4.w),

            /// NAME + MESSAGE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: name,
                    size: 16,
                    weight: FontWeight.w600,
                  ),
                  SizedBox(height: 0.6.h),
                  TextWidget(
                    text: message,
                    size: 14,
                    color: Colors.grey.shade600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: 2.w),

            /// TIME + UNREAD
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextWidget(
                  text: time,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                SizedBox(height: 1.h),
                if (unread > 0)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF4D6D),
                    ),
                    alignment: Alignment.center,
                    child: TextWidget(
                      text: unread.toString(),
                      size: 11,
                      weight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}