// lib/Chat/chat_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../services/auth_service.dart';
import '../../widgets/text_widget.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

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
                  text: "Please sign in to see messages.",
                  size: 16,
                  weight: FontWeight.w600,
                ),
              )
            : Padding(
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

                    /// CHAT LIST (REAL)
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _db
                            .collection("threads")
                            .where("participants", arrayContains: myUid)
                            // .orderBy("updatedAt", descending: true)
                            .snapshots(),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return _error("Failed to load chats.");
                          }
                          if (!snap.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final threads = snap.data!.docs
                              .map((d) => ThreadItem.fromDoc(d))
                              .where((t) => t.threadId.isNotEmpty)
                              .where((t) => !t.hiddenFor.contains(myUid))
                              .toList();

                          if (threads.isEmpty) {
                            return _emptyState();
                          }

                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: threads.length,
                            itemBuilder: (context, i) {
                              final t = threads[i];
                              final peerUid = t.peerUid(myUid);
                              if (peerUid == null) return const SizedBox();

                              return Padding(
                                padding: EdgeInsets.only(bottom: 2.h),
                                child: _ThreadTile(
                                  myUid: myUid,
                                  peerUid: peerUid,
                                  thread: t,
                                  onTap: () {
                                    Get.to(
                                      () => ChatScreen(
                                        threadId: t.threadId,
                                        myUid: myUid,
                                        peerUid: peerUid,
                                      ),
                                      transition: Transition.rightToLeft,
                                      duration:
                                          const Duration(milliseconds: 250),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 44, color: Colors.grey),
            SizedBox(height: 1.5.h),
            const TextWidget(
              text: "No conversations yet",
              size: 16,
              weight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 0.8.h),
            TextWidget(
              text: "Match with someone and send a message to start chatting.",
              size: 13.5,
              color: Colors.grey.shade600,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(String text) {
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
}

/// ================= THREAD TILE =================

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.myUid,
    required this.peerUid,
    required this.thread,
    required this.onTap,
  });

  final String myUid;
  final String peerUid;
  final ThreadItem thread;
  final VoidCallback onTap;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection("users_cupid").doc(peerUid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? const <String, dynamic>{};

        final name = ((data["displayName"] as String?) ??
                (data["name"] as String?) ??
                "Unknown")
            .trim();

        final photoUrl = ((data["photoUrl"] as String?) ?? "").trim();
        final avatar = photoUrl.isNotEmpty
            ? photoUrl
            : "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e";

        final subtitle = (thread.lastMessage?.trim().isNotEmpty == true)
            ? thread.lastMessage!.trim()
            : "Say hi 👋";

        final timeLabel = _timeLabel(thread.updatedAt);
        final unread = _unreadCountLike(
          myUid: myUid,
          thread: thread,
        );

        return _ChatTile(
          name: name,
          message: subtitle,
          time: timeLabel,
          image: avatar,
          unread: unread,
          online: true,
          onTap: onTap,
        );
      },
    );
  }

  int _unreadCountLike({
    required String myUid,
    required ThreadItem thread,
  }) {
    // Lightweight unread: if last message isn't mine AND it's newer than my readAt -> show 1 badge.
    final lastFrom = thread.lastMessageFrom;
    final lastAt = thread.lastMessageAt;
    final myReadAt = thread.readAtByUid[myUid];

    final isMine = lastFrom != null && lastFrom == myUid;
    if (isMine) return 0;
    if (lastAt == null) return 0;
    if (myReadAt == null) return 1;
    return lastAt.isAfter(myReadAt) ? 1 : 0;
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return "";
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return "Now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final String image;
  final int unread;
  final bool online;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.message,
    required this.time,
    required this.image,
    required this.unread,
    required this.online,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
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
                    overflow: TextOverflow.ellipsis,
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

/// ================= MODELS =================

class ThreadItem {
  ThreadItem({
    required this.threadId,
    required this.participants,
    required this.updatedAt,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageFrom,
    required this.readAtByUid,
    required this.hiddenFor,
  });

  final String threadId;
  final List<String> participants;
  final DateTime? updatedAt;

  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageFrom;

  final Map<String, DateTime> readAtByUid;
  final List<String> hiddenFor;

  static ThreadItem fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};

    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;

    final parts = (d["participants"] is List)
        ? (d["participants"] as List).whereType<String>().toList()
        : <String>[];

    final readAtRaw = (d["readAt"] is Map) ? (d["readAt"] as Map) : const {};
    final readAt = <String, DateTime>{};
    readAtRaw.forEach((k, v) {
      if (k is String && v is Timestamp) readAt[k] = v.toDate();
    });

    return ThreadItem(
      threadId: (d["threadId"] as String?) ?? doc.id,
      participants: parts,
      updatedAt: ts(d["updatedAt"]),
      lastMessage: d["lastMessage"] as String?,
      lastMessageAt: ts(d["lastMessageAt"]),
      lastMessageFrom: d["lastMessageFrom"] as String?,
      readAtByUid: readAt,
      hiddenFor: (d["hiddenFor"] is List)
          ? (d["hiddenFor"] as List).whereType<String>().toList()
          : <String>[],
    );
  }

  String? peerUid(String myUid) {
    for (final u in participants) {
      if (u != myUid) return u;
    }
    return null;
  }
}
