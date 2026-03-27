// lib/Matches/matches_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../services/auth_service.dart';
import '../../services/safety_service.dart';
import '../../widgets/text_widget.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get _myUid => AuthService.to.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final myUid = _myUid;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: myUid == null
            ? const Center(
                child: TextWidget(
                  text: "Please sign in to see matches.",
                  size: 16,
                  weight: FontWeight.w600,
                ),
              )
            : FutureBuilder<Set<String>>(
                future: SafetyService.instance.blockedUserIds(myUid),
                builder: (context, blockedSnap) {
                  final blockedIds = blockedSnap.data ?? <String>{};
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _db
                        .collection("users_cupid")
                        .doc(myUid)
                        .collection("matches")
                        .orderBy("lastMessageAt", descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return _errorState("Failed to load matches.");
                      }
                      if (!snap.hasData ||
                          blockedSnap.connectionState ==
                              ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snap.data!.docs;
                      final matches = docs
                          .map((d) => MatchItem.fromDoc(d))
                          .where((m) => m.uid.isNotEmpty)
                          .where((m) => !blockedIds.contains(m.uid))
                          .toList();

                      return SingleChildScrollView(
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

                            /// ❤️ LIKED YOU (still static placeholder)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                TextWidget(
                                  text: '❤️ Liked You',
                                  size: 16,
                                  weight: FontWeight.w500,
                                ),
                              ],
                            ),

                            SizedBox(height: 1.5.h),

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
                            TextWidget(
                              text: 'Mutual Matches (${matches.length})',
                              size: 16,
                              weight: FontWeight.w500,
                            ),

                            SizedBox(height: 1.5.h),

                            if (matches.isEmpty) _emptyMutualState(),

                            for (final m in matches) ...[
                              _dynamicMatchTile(
                                myUid: myUid,
                                match: m,
                                onTap: () {},
                              ),
                              SizedBox(height: 1.5.h),
                            ],

                            SizedBox(height: 12.h),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _dynamicMatchTile({
    required String myUid,
    required MatchItem match,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection("users_cupid").doc(match.uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? const <String, dynamic>{};

        final name = ((data["displayName"] as String?) ??
                (data["name"] as String?) ??
                "Unknown")
            .trim();

        final photoUrl = ((data["photoUrl"] as String?) ?? "").trim();
        final hero = photoUrl.isNotEmpty
            ? photoUrl
            : "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e";

        final subtitle = (match.lastMessage?.trim().isNotEmpty == true)
            ? match.lastMessage!.trim()
            : "Say hi 👋";

        final hasMessage = match.lastMessage?.trim().isNotEmpty == true;

        return _matchTile(
          name: name,
          percent: match.matchPercentLabel ?? "",
          subtitle: subtitle,
          time: null,
          hasMessage: hasMessage,
          avatarUrl: hero,
          onTap: onTap,
        );
      },
    );
  }

  Widget _emptyMutualState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          TextWidget(
            text: "No mutual matches yet",
            size: 16,
            weight: FontWeight.w700,
          ),
          SizedBox(height: 6),
          TextWidget(
            text: "Keep swiping — when it’s mutual, it’ll show here.",
            size: 13,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _errorState(String text) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: TextWidget(
          text: text,
          size: 15,
          color: Colors.redAccent,
          textAlign: TextAlign.center,
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
            text: '+',
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
    required String avatarUrl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
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
                CircleAvatar(
                  radius: 35,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: FancyShimmerImage(
                      imageUrl: avatarUrl,
                      height: 70,
                      width: 70,
                      boxFit: BoxFit.cover,
                    ),
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
                    right: 0,
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
                      Flexible(
                        child: TextWidget(
                          text: name,
                          weight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (percent.trim().isNotEmpty)
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
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            /// TIMER (optional)
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
      ),
    );
  }
}

class MatchItem {
  MatchItem({
    required this.uid,
    required this.threadId,
    required this.createdAt,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.matchPercentLabel,
  });

  final String uid;
  final String threadId;
  final DateTime? createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  /// Optional: store it when you create match (or compute client-side later).
  final String? matchPercentLabel;

  static MatchItem fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};

    DateTime? tsToDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return MatchItem(
      uid: (d["uid"] as String?) ?? doc.id,
      threadId: (d["threadId"] as String?) ?? "",
      createdAt: tsToDate(d["createdAt"]),
      lastMessage: d["lastMessage"] as String?,
      lastMessageAt: tsToDate(d["lastMessageAt"]),
      matchPercentLabel: d["matchPercentLabel"] as String?,
    );
  }
}
