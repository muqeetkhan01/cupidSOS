// lib/Chat/chat_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:videosdk/videosdk.dart';

import '../../profile/safety_center_screen.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/safety_menu_button.dart';

/// =======================================================
/// VideoSDK API (kept in-file per your request)
/// =======================================================
class VideoCallApi {
  static const String token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIwMzU5MjI0ZC0xZTIwLTQyZDMtOWExZC1kYWQ2NzVjMTQwNmIiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIl0sImlhdCI6MTc1OTA5NDk5OSwiZXhwIjoxNzkwNjMwOTk5fQ.6T1MxCWOSAHAK2l8fs3Z6Uun76VqENwj8bmIJ24C9Qk";

  static Future<String> createMeeting() async {
    final res = await http.post(
      Uri.parse("https://api.videosdk.live/v2/rooms"),
      headers: {
        "Authorization": token,
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body);
      return data["roomId"];
    }
    throw Exception("Failed to create meeting: ${res.body}");
  }
}

/// =======================================================
/// Firestore Call Signaling
/// =======================================================
class CallSignalingService {
  CallSignalingService(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> threadRef(String threadId) =>
      _db.collection("threads").doc(threadId);

  /// Start a call: writes activeCall = ringing (meetingId created externally)
  Future<void> startCall({
    required String threadId,
    required String callId,
    required String meetingId,
    required String fromUid,
    required String toUid,
  }) async {
    await threadRef(threadId).set({
      "activeCall": {
        "callId": callId,
        "meetingId": meetingId,
        "fromUid": fromUid,
        "toUid": toUid,
        "status": "ringing", // ringing | accepted | declined | ended | missed
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      },
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> acceptCall({
    required String threadId,
    required String callId,
    required String accepterUid,
  }) async {
    await threadRef(threadId).set({
      "activeCall": {
        "callId": callId,
        "status": "accepted",
        "acceptedBy": accepterUid,
        "updatedAt": FieldValue.serverTimestamp(),
      },
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> declineCall({
    required String threadId,
    required String callId,
    required String declinerUid,
  }) async {
    await threadRef(threadId).set({
      "activeCall": {
        "callId": callId,
        "status": "declined",
        "declinedBy": declinerUid,
        "updatedAt": FieldValue.serverTimestamp(),
      },
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> endCall({
    required String threadId,
    required String callId,
    required String enderUid,
  }) async {
    await threadRef(threadId).set({
      "activeCall": {
        "callId": callId,
        "status": "ended",
        "endedBy": enderUid,
        "updatedAt": FieldValue.serverTimestamp(),
      },
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markMissed({
    required String threadId,
    required String callId,
    required String missedForUid,
  }) async {
    await threadRef(threadId).set({
      "activeCall": {
        "callId": callId,
        "status": "missed",
        "missedFor": missedForUid,
        "updatedAt": FieldValue.serverTimestamp(),
      },
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Optional cleanup: clear activeCall after ended/declined/missed.
  Future<void> clearActiveCall(String threadId) async {
    await threadRef(threadId).set({
      "activeCall": FieldValue.delete(),
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class ActiveCall {
  ActiveCall({
    required this.callId,
    required this.meetingId,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
  });

  final String callId;
  final String meetingId;
  final String fromUid;
  final String toUid;
  final String status;
  final DateTime? createdAt;

  static ActiveCall? fromMap(dynamic v) {
    if (v is! Map) return null;

    DateTime? ts(dynamic x) => x is Timestamp ? x.toDate() : null;

    final callId = (v["callId"] as String?) ?? "";
    final meetingId = (v["meetingId"] as String?) ?? "";
    final fromUid = (v["fromUid"] as String?) ?? "";
    final toUid = (v["toUid"] as String?) ?? "";
    final status = (v["status"] as String?) ?? "";

    if (callId.isEmpty ||
        meetingId.isEmpty ||
        fromUid.isEmpty ||
        toUid.isEmpty) {
      return null;
    }

    return ActiveCall(
      callId: callId,
      meetingId: meetingId,
      fromUid: fromUid,
      toUid: toUid,
      status: status,
      createdAt: ts(v["createdAt"]),
    );
  }
}

/// =======================================================
/// Chat Screen (with incoming call popup)
/// =======================================================
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.threadId,
    required this.myUid,
    required this.peerUid,
  });

  final String threadId;
  final String myUid;
  final String peerUid;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  late final CallSignalingService _callSvc = CallSignalingService(_db);

  final _input = TextEditingController();
  bool _sending = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _threadSub;
  bool _incomingDialogOpen = false;

  DocumentReference<Map<String, dynamic>> get _threadRef =>
      _db.collection("threads").doc(widget.threadId);

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _threadRef.collection("messages");

  @override
  void initState() {
    super.initState();
    _markRead();
    _listenForIncomingCalls();
  }

  @override
  void dispose() {
    _threadSub?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    await _threadRef.set({
      "readAt": {widget.myUid: FieldValue.serverTimestamp()},
    }, SetOptions(merge: true));
  }

  void _listenForIncomingCalls() {
    _threadSub = _threadRef.snapshots().listen((doc) async {
      final data = doc.data() ?? const <String, dynamic>{};
      final call = ActiveCall.fromMap(data["activeCall"]);
      if (!mounted || call == null) return;

      final isForMe = call.toUid == widget.myUid;
      final isRinging = call.status == "ringing";

      if (isForMe && isRinging && !_incomingDialogOpen) {
        _incomingDialogOpen = true;
        await _showIncomingCallDialog(call);
        _incomingDialogOpen = false;
      }
    });
  }

  Future<void> _showIncomingCallDialog(ActiveCall call) async {
    final peerName = await _fetchPeerName(widget.peerUid);

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _IncomingCallDialog(
        name: peerName,
        onDecline: () async {
          await _callSvc.declineCall(
            threadId: widget.threadId,
            callId: call.callId,
            declinerUid: widget.myUid,
          );
          if (mounted) Navigator.pop(context);
        },
        onAccept: () async {
          final ok = await _ensureCallPermissions();
          if (!ok) return;

          await _callSvc.acceptCall(
            threadId: widget.threadId,
            callId: call.callId,
            accepterUid: widget.myUid,
          );

          if (mounted) Navigator.pop(context);

          Get.to(
            () => VideoCallScreen(
              threadId: widget.threadId,
              callId: call.callId,
              meetingId: call.meetingId,
              token: VideoCallApi.token,
              myUid: widget.myUid,
              peerUid: widget.peerUid,
              isCaller: false,
            ),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 220),
          );
        },
      ),
    );
  }

  Future<String> _fetchPeerName(String uid) async {
    try {
      final d = await _db.collection("users_cupid").doc(uid).get();
      final m = d.data() ?? const <String, dynamic>{};
      return ((m["displayName"] as String?) ?? (m["name"] as String?) ?? "User")
          .trim();
    } catch (_) {
      return "User";
    }
  }

  Future<bool> _ensureCallPermissions() async {
    final camBefore = await Permission.camera.status;
    final micBefore = await Permission.microphone.status;

    debugPrint("BEFORE -> cam: $camBefore | mic: $micBefore");

    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();

    debugPrint("AFTER  -> cam: $cam | mic: $mic");

    if (cam.isGranted && mic.isGranted) return true;

    if (cam.isPermanentlyDenied || mic.isPermanentlyDenied) {
      Get.snackbar(
        "Enable permissions",
        "Please allow Camera & Microphone in Settings to start video calls.",
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(4.w),
        mainButton: TextButton(
          onPressed: openAppSettings,
          child: const Text("Open Settings"),
        ),
      );
      return false;
    }

    final missing = <String>[];
    if (!cam.isGranted) missing.add("Camera");
    if (!mic.isGranted) missing.add("Microphone");

    Get.snackbar(
      "Permissions needed",
      "${missing.join(" & ")} permission is required for video calls.",
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(4.w),
    );

    return false;
  }

  Future<void> _startVideoCall() async {
    final ok = await _ensureCallPermissions();
    if (!ok) return;

    try {
      final meetingId = await VideoCallApi.createMeeting();
      final callId = DateTime.now().millisecondsSinceEpoch.toString();

      await _callSvc.startCall(
        threadId: widget.threadId,
        callId: callId,
        meetingId: meetingId,
        fromUid: widget.myUid,
        toUid: widget.peerUid,
      );

      Get.to(
        () => VideoCallScreen(
          threadId: widget.threadId,
          callId: callId,
          meetingId: meetingId,
          token: VideoCallApi.token,
          myUid: widget.myUid,
          peerUid: widget.peerUid,
          isCaller: true,
        ),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 220),
      );
    } catch (e) {
      Get.snackbar(
        "Call failed",
        "$e",
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(4.w),
      );
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      final msgRef = _messagesRef.doc();
      final now = FieldValue.serverTimestamp();

      final batch = _db.batch();

      batch.set(
          _threadRef,
          {
            "threadId": widget.threadId,
            "participants": [widget.myUid, widget.peerUid],
            "updatedAt": now,
            "lastMessage": text,
            "lastMessageAt": now,
            "lastMessageFrom": widget.myUid,
            "readAt": {widget.myUid: now},
          },
          SetOptions(merge: true));

      batch.set(msgRef, {
        "id": msgRef.id,
        "threadId": widget.threadId,
        "from": widget.myUid,
        "to": widget.peerUid,
        "text": text,
        "createdAt": now,
        "type": "text",
      });

      await batch.commit();
      _input.clear();
      await _markRead();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      // Replace your current appBar: AppBar(...) with this.

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(9.h),
        child: Container(
          decoration: BoxDecoration(
            color: CupidColors.scaffold(context),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _db
                    .collection("users_cupid")
                    .doc(widget.peerUid)
                    .snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data() ?? const <String, dynamic>{};

                  final name = ((data["displayName"] as String?) ??
                          (data["name"] as String?) ??
                          "Chat")
                      .trim();

                  final photoUrl = ((data["photoUrl"] as String?) ?? "").trim();
                  final avatarUrl = photoUrl.isNotEmpty
                      ? photoUrl
                      : "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e";

                  // If you later store presence/lastSeen, replace this.
                  final statusText = "Active now";

                  return Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(2.8.w),
                          decoration: BoxDecoration(
                            color: CupidColors.surface(context),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: CupidColors.shadow(context),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: CupidColors.textPrimary(context),
                          ),
                        ),
                      ),

                      SizedBox(width: 3.w),

                      /// Avatar + Online dot
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: NetworkImage(avatarUrl),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3DDC84),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CupidColors.scaffold(context),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(width: 3.w),

                      /// Name + status
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: CupidColors.textPrimary(context),
                              ),
                            ),
                            SizedBox(height: 0.4.h),
                            Text(
                              statusText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: CupidColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Video call button (pill)
                      InkWell(
                        onTap: _startVideoCall,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.2.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFFFF6F7D).withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.videocam_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Call",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 2.w),

                      /// More menu
                      SafetyMenuButton(
                        currentUid: widget.myUid,
                        targetUid: widget.peerUid,
                        threadId: widget.threadId,
                        showUnmatch: true,
                        onOpenSafetyCenter: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SafetyCenterScreen(),
                            ),
                          );
                        },
                        onCompleted: () {
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesRef
                  .orderBy("createdAt", descending: true)
                  .limit(200)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return _center("Failed to load messages.");
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final msgs = snap.data!.docs
                    .map((d) => ChatMessage.fromDoc(d))
                    .where((m) => m.text.trim().isNotEmpty)
                    .toList();

                if (msgs.isEmpty) return _center("Say hi 👋");

                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification) _markRead();
                    return false;
                  },
                  child: ListView.builder(
                    reverse: true,
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                    itemCount: msgs.length,
                    itemBuilder: (context, i) {
                      final m = msgs[i];
                      final isMe = m.from == widget.myUid;
                      return _bubble(m.text, isMe: isMe);
                    },
                  ),
                );
              },
            ),
          ),

          /// INPUT
          Container(
            padding: EdgeInsets.fromLTRB(4.w, 1.2.h, 4.w, 2.2.h),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: "Message...",
                      filled: true,
                      fillColor: CupidColors.surface(context),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.4.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.5.w),
                InkWell(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6F7D).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _center(String text) {
    return Center(
      child: TextWidget(
        text: text,
        size: 14.5,
        color: CupidColors.textSecondary(context),
      ),
    );
  }

  Widget _bubble(String text, {required bool isMe}) {
    final bg = isMe ? const Color(0xFFFF6F7D) : CupidColors.surface(context);
    final fg = isMe ? Colors.white : CupidColors.textPrimary(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 1.2.h),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.3.h),
        constraints: BoxConstraints(maxWidth: 78.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: CupidColors.shadow(context),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String from;
  final String to;
  final String text;
  final DateTime? createdAt;

  static ChatMessage fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final ts = d["createdAt"];
    return ChatMessage(
      id: (d["id"] as String?) ?? doc.id,
      from: (d["from"] as String?) ?? "",
      to: (d["to"] as String?) ?? "",
      text: (d["text"] as String?) ?? "",
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// =======================================================
/// Incoming Call Dialog (Cupid theme)
/// =======================================================
class _IncomingCallDialog extends StatelessWidget {
  const _IncomingCallDialog({
    required this.name,
    required this.onAccept,
    required this.onDecline,
  });

  final String name;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CupidColors.surface(context),
      insetPadding: EdgeInsets.all(6.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18.w,
              height: 18.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                ),
              ),
              child: const Icon(Icons.videocam_rounded,
                  color: Colors.white, size: 34),
            ),
            SizedBox(height: 1.8.h),
            TextWidget(
              text: "Incoming video call",
              size: 18,
              weight: FontWeight.w800,
            ),
            SizedBox(height: 0.8.h),
            TextWidget(
              text: name,
              size: 15,
              color: CupidColors.textSecondary(context),
            ),
            SizedBox(height: 2.2.h),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onDecline,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 1.6.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xFFFF4D6D),
                      ),
                      child: const Center(
                        child: TextWidget(
                          text: "Decline",
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: InkWell(
                    onTap: onAccept,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 1.6.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                        ),
                      ),
                      child: const Center(
                        child: TextWidget(
                          text: "Accept",
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
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

/// =======================================================
/// Video Call Screen (Cupid theme + signaling aware)
/// =======================================================
// lib/Chat/chat_screen.dart (replace VideoCallScreen + participant tile section)
// Requires: videosdk ^3.7.0, videosdk_webrtc, permission_handler, get, responsive_sizer

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.threadId,
    required this.callId,
    required this.meetingId,
    required this.token,
    required this.myUid,
    required this.peerUid,
    required this.isCaller,
  });

  final String threadId;
  final String callId;
  final String meetingId;
  final String token;
  final String myUid;
  final String peerUid;
  final bool isCaller;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  late final CallSignalingService _callSvc = CallSignalingService(_db);

  Room? _room;

  final Map<String, Participant> _participants = {};
  bool _micEnabled = true;
  bool _camEnabled = true;
  bool _speakerOn = true;

  Timer? _timer;
  int _seconds = 0;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _threadSub;
  Timer? _missedTimer;

  // For flip camera
  List<dynamic> _videoDevices = const [];
  int _activeDeviceIndex = 0;

  @override
  void initState() {
    super.initState();
    _initRoom();
    _startTimer();
    _listenCallState();

    if (widget.isCaller) {
      _missedTimer = Timer(const Duration(seconds: 30), () async {
        final doc = await _db.collection("threads").doc(widget.threadId).get();
        final call = ActiveCall.fromMap(doc.data()?["activeCall"]);
        if (call != null &&
            call.callId == widget.callId &&
            call.status == "ringing") {
          await _callSvc.markMissed(
            threadId: widget.threadId,
            callId: widget.callId,
            missedForUid: widget.peerUid,
          );
        }
      });
    }
  }

  Participant? get _localParticipant => _room?.localParticipant;
  Future<void> _initRoom() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();

    if (!cam.isGranted || !mic.isGranted) {
      if (!mounted) return;
      Get.snackbar(
        "Permissions needed",
        "Camera & Microphone permissions are required for video calls.",
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(4.w),
      );
      Navigator.pop(context);
      return;
    }

    final room = VideoSDK.createRoom(
      roomId: widget.meetingId,
      token: widget.token,
      displayName: "User",
      micEnabled: _micEnabled,
      camEnabled: _camEnabled,
      defaultCameraIndex: 0,
    );

    _room = room;
    _setMeetingListeners(room);
    room.join();
  }

  void _setMeetingListeners(Room room) {
    room.on(Events.roomJoined, () async {
      if (!mounted) return;
      setState(() {
        _participants[room.localParticipant.id] = room.localParticipant;
      });
      await _loadVideoDevices();
    });

    room.on(Events.participantJoined, (p) {
      if (!mounted) return;
      setState(() => _participants[p.id] = p);
    });

    room.on(Events.participantLeft, (id, _) {
      if (!mounted) return;
      setState(() => _participants.remove(id));
    });

    room.on(Events.roomLeft, () {
      _participants.clear();
      if (mounted) Navigator.pop(context);
    });
  }

  void _toggleMic() {
    final room = _room;
    if (room == null) return;
    _micEnabled ? room.muteMic() : room.unmuteMic();
    setState(() => _micEnabled = !_micEnabled);
  }

  void _toggleCam() {
    final room = _room;
    if (room == null) return;
    _camEnabled ? room.disableCam() : room.enableCam();
    setState(() => _camEnabled = !_camEnabled);
  }

  Future<void> _toggleSpeaker() async {
    final room = _room;
    if (room == null) return;
    setState(() => _speakerOn = !_speakerOn);
    try {
      final dynamic anyRoom = room;
      if (anyRoom.setSpeakerphoneOn is Function) {
        await anyRoom.setSpeakerphoneOn(_speakerOn);
      }
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    final room = _room;
    if (room == null) return;
    // ... keep your changeCam logic, but use `room.changeCam(...)`
  }

// 6) in dispose/end call, guard leave:
  @override
  void dispose() {
    _missedTimer?.cancel();
    _threadSub?.cancel();
    _timer?.cancel();
    _room?.leave();
    super.dispose();
  }

  Future<void> _endCall() async {
    await _callSvc.endCall(
      threadId: widget.threadId,
      callId: widget.callId,
      enderUid: widget.myUid,
    );
    Future.delayed(const Duration(seconds: 2), () {
      _callSvc.clearActiveCall(widget.threadId);
    });
    _room?.leave();
  }

  void _listenCallState() {
    _threadSub = _db
        .collection("threads")
        .doc(widget.threadId)
        .snapshots()
        .listen((doc) {
      final call = ActiveCall.fromMap(doc.data()?["activeCall"]);
      if (!mounted) return;
      if (call == null || call.callId != widget.callId) return;

      if (call.status == "declined" ||
          call.status == "ended" ||
          call.status == "missed") {
        Get.snackbar(
          "Call ended",
          call.status == "declined"
              ? "They declined the call."
              : call.status == "missed"
                  ? "No answer."
                  : "Call ended.",
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(4.w),
        );
        _room!.leave();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
    });
  }

  Participant? get _remoteParticipant {
    // pick first non-local
    for (final p in _participants.values) {
      if (_localParticipant != null && p.id != _localParticipant!.id) {
        return p;
      }
    }
    return null;
  }

  Future<void> _loadVideoDevices() async {
    try {
      // VideoSDK versions differ; we use dynamic to avoid compile errors.
      final dynamic anySDK = VideoSDK;

      dynamic devices;
      if (anySDK.getVideoDevices is Function) {
        devices = await anySDK.getVideoDevices();
      } else if (anySDK.getCameras is Function) {
        devices = await anySDK.getCameras();
      } else {
        devices = const [];
      }

      if (!mounted) return;

      setState(() {
        _videoDevices = (devices is List) ? devices : const [];
        _activeDeviceIndex = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _videoDevices = const []);
    }
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final local = _localParticipant;
    final remote = _remoteParticipant;
    final roomReady = _room != null;
    if (!roomReady) {
      return Scaffold(
        backgroundColor: CupidColors.scaffold(context),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      body: SafeArea(
        child: Stack(
          children: [
            // -------------------------
            // Remote full screen (WhatsApp style)
            // -------------------------
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: CupidColors.pageGradient(context),
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: remote == null
                    ? _WaitingRemote(isCaller: widget.isCaller)
                    : _VideoTile(
                        participant: remote,
                        borderRadius: 0,
                        showName: false,
                      ),
              ),
            ),

            // -------------------------
            // Local PiP (bottom-right)
            // -------------------------
            if (local != null)
              Positioned(
                right: 4.w,
                bottom: 18.h, // above control bar
                child: SizedBox(
                  width: 32.w,
                  height: 22.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      color: Colors.black,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _camEnabled
                                ? _VideoTile(
                                    participant: local,
                                    borderRadius: 18,
                                    showName: false,
                                  )
                                : const Center(
                                    child: Icon(Icons.videocam_off,
                                        color: Colors.white70, size: 28),
                                  ),
                          ),
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "You",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // -------------------------
            // Top pills
            // -------------------------
            Positioned(
              top: 1.2.h,
              left: 4.w,
              right: 4.w,
              child: Row(
                children: [
                  _pill(icon: Icons.videocam_rounded, label: "Video Call"),
                  SizedBox(width: 2.w),
                  _pill(
                    icon: Icons.timer_outlined,
                    label: _formatTimer(_seconds),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _endCall,
                    child: Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: CupidColors.surface(context),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: CupidColors.shadow(context),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close,
                          color: Color(0xFFFF6F7D), size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // -------------------------
            // Bottom control bar (no overflow)
            // -------------------------
            Positioned(
              left: 0,
              right: 0,
              bottom: 1.8.h,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.4.h),
                    decoration: BoxDecoration(
                      color: CupidColors.surface(context),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: CupidColors.shadow(context),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _controlIcon(
                          icon: _micEnabled ? Icons.mic : Icons.mic_off,
                          label: "Mic",
                          active: _micEnabled,
                          onTap: _toggleMic,
                        ),
                        _controlIcon(
                          icon:
                              _camEnabled ? Icons.videocam : Icons.videocam_off,
                          label: "Cam",
                          active: _camEnabled,
                          onTap: _toggleCam,
                        ),
                        _controlIcon(
                          icon: Icons.cameraswitch,
                          label: "Flip",
                          active: true,
                          onTap: _switchCamera,
                        ),
                        _controlIcon(
                          icon: _speakerOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          label: "Speaker",
                          active: _speakerOn,
                          onTap: _toggleSpeaker,
                        ),
                        _controlIcon(
                          icon: Icons.shield_rounded,
                          label: "Safety",
                          active: true,
                          onTap: () {
                            Get.snackbar(
                              "Safety",
                              "Add: Report, Block, Unmatch",
                              snackPosition: SnackPosition.BOTTOM,
                              margin: EdgeInsets.all(4.w),
                            );
                          },
                        ),

                        // End call (fixed size, no overflow)
                        InkWell(
                          onTap: _endCall,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 14.w,
                            height: 14.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF4D6D),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF4D6D).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.call_end,
                                color: Colors.white, size: 26),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.9.h),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF181B22).withOpacity(0.92)
            : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: CupidColors.shadow(context),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFF6F7D)),
          SizedBox(width: 2.w),
          TextWidget(
            text: label,
            size: 13,
            weight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  Widget _controlIcon({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    // smaller controls avoid overflow on small screens
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 12.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.5.w,
              height: 10.5.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade300, Colors.grey.shade200],
                      ),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(height: 0.6.h),
            TextWidget(
              text: label,
              size: 10.5,
              color: CupidColors.textSecondary(context),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingRemote extends StatelessWidget {
  const _WaitingRemote({required this.isCaller});

  final bool isCaller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 12),
          Text(
            isCaller ? "Calling..." : "Connecting...",
            style: TextStyle(
              color: CupidColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders participant video if available; else placeholder.
class _VideoTile extends StatefulWidget {
  const _VideoTile({
    required this.participant,
    required this.borderRadius,
    required this.showName,
  });

  final Participant participant;
  final double borderRadius;
  final bool showName;

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  Stream? _videoStream;

  @override
  void initState() {
    super.initState();

    widget.participant.streams.forEach((_, st) {
      if (st.kind == 'video' && st.renderer != null) {
        _videoStream = st;
      }
    });

    widget.participant.on(Events.streamEnabled, (st) {
      if (st.kind == 'video' && st.renderer != null) {
        setState(() => _videoStream = st);
      }
    });

    widget.participant.on(Events.streamDisabled, (st) {
      if (st.kind == 'video') {
        setState(() => _videoStream = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _videoStream != null && _videoStream?.renderer != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: hasVideo
                  ? RTCVideoView(
                      _videoStream?.renderer as RTCVideoRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : const Center(
                      child:
                          Icon(Icons.person, size: 84, color: Colors.white70),
                    ),
            ),
            if (widget.showName)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    widget.participant.displayName.isEmpty
                        ? "User"
                        : widget.participant.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatefulWidget {
  const _ParticipantTile(this.participant);

  final Participant participant;

  @override
  State<_ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<_ParticipantTile> {
  Stream? _videoStream;

  @override
  void initState() {
    super.initState();

    widget.participant.streams.forEach((_, st) {
      if (st.kind == 'video' && st.renderer != null) {
        _videoStream = st;
      }
    });

    widget.participant.on(Events.streamEnabled, (st) {
      if (st.kind == 'video' && st.renderer != null) {
        setState(() => _videoStream = st);
      }
    });

    widget.participant.on(Events.streamDisabled, (st) {
      if (st.kind == 'video') {
        setState(() => _videoStream = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _videoStream != null && _videoStream?.renderer != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: hasVideo
                  ? RTCVideoView(
                      _videoStream?.renderer as RTCVideoRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : const Center(
                      child:
                          Icon(Icons.person, size: 84, color: Colors.white70),
                    ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.participant.displayName.isEmpty
                      ? "User"
                      : widget.participant.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
