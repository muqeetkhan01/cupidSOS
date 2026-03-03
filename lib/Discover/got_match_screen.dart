// lib/Discover/got_match_screen.dart
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../services/match_service.dart';
import '../widgets/text_widget.dart';

class GotMatchScreen extends StatefulWidget {
  const GotMatchScreen({
    super.key,
    required this.myUid,
    required this.targetUid,
    required this.targetName,
    required this.targetPhotoUrl,
    required this.matchPercentLabel,
  });

  final String myUid;
  final String targetUid;
  final String targetName;
  final String targetPhotoUrl;
  final String matchPercentLabel;

  @override
  State<GotMatchScreen> createState() => _GotMatchScreenState();
}

class _GotMatchScreenState extends State<GotMatchScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  MatchService get _matchService => MatchService(FirebaseFirestore.instance);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (_sending) return;

    setState(() => _sending = true);
    try {
      await _matchService.sendQuickMessage(
        myUid: widget.myUid,
        targetUid: widget.targetUid,
        text: text,
      );
      if (mounted) {
        Get.back(); // close match screen
        Get.snackbar(
          "Sent!",
          "Your message was sent to ${widget.targetName}.",
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(4.w),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.targetPhotoUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          width: 100.w,
          height: 90.h,
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FancyShimmerImage(
                    imageUrl: photo,
                    boxFit: BoxFit.cover,
                  ),
                ),
              ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6F7D).withOpacity(0.85),
                        const Color(0xFFFF6F7D).withOpacity(0.70),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.35, 0.65, 1.0],
                    ),
                  ),
                ),
              ),

              // Blur glass message composer
              Positioned(
                left: 4.w,
                right: 4.w,
                bottom: 2.5.h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextWidget(
                                  text:
                                      "You matched with ${widget.targetName}!",
                                  size: 17,
                                  weight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              _pill("${widget.matchPercentLabel} Match"),
                            ],
                          ),
                          SizedBox(height: 1.2.h),
                          TextWidget(
                            text: "Send a quick message to break the ice 👇",
                            size: 13.5,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          SizedBox(height: 1.5.h),
                          TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (v) => _send(v),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.12),
                              hintText: "Say hi...",
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                onPressed: _sending
                                    ? null
                                    : () => _send(_controller.text),
                                icon: _sending
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.send,
                                        color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(height: 1.2.h),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _quickChip("Hi 👋", () => _send("Hi 👋")),
                              _quickChip("You seem fun 😄",
                                  () => _send("You seem fun 😄")),
                              _quickChip("Coffee this week? ☕",
                                  () => _send("Coffee this week? ☕")),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Center match art
              Positioned(
                bottom: 36.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/images/match1.png',
                    width: 80.w,
                  ),
                ),
              ),

              // Close button
              Positioned(
                top: 1.5.h,
                right: 3.w,
                child: InkWell(
                  onTap: () => Get.back(),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.25),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: TextWidget(
        text: text,
        size: 12,
        weight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _quickChip(String text, VoidCallback onTap) {
    return InkWell(
      onTap: _sending ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: TextWidget(
          text: text,
          size: 13,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
