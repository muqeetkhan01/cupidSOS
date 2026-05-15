// lib/services/match_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchService {
  MatchService(this._db);

  final FirebaseFirestore _db;

  Future<SwipeResult> swipe({
    required String myUid,
    required String targetUid,
    required bool liked,
    required Map<String, dynamic> targetSnapshot,
  }) async {
    // 1) persist my swipe
    await _db
        .collection("users_cupid")
        .doc(myUid)
        .collection("swipes")
        .doc(targetUid)
        .set({
      "targetUid": targetUid,
      "liked": liked,
      "createdAt": FieldValue.serverTimestamp(),
      "snapshot": targetSnapshot,
    }, SetOptions(merge: true));

    final likedByRef = _db
        .collection("users_cupid")
        .doc(targetUid)
        .collection("liked_by")
        .doc(myUid);
    if (liked) {
      await likedByRef.set({
        "uid": myUid,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await likedByRef.delete();
    }

    if (!liked) {
      return const SwipeResult(isMatch: false);
    }

    // 2) check if target already liked me
    final theirSwipeDoc = await _db
        .collection("users_cupid")
        .doc(targetUid)
        .collection("swipes")
        .doc(myUid)
        .get();

    final theyLikedMe = (theirSwipeDoc.data()?["liked"] == true);
    if (!theyLikedMe) {
      return const SwipeResult(isMatch: false);
    }

    // 3) create match on both sides (idempotent via doc id)
    final batch = _db.batch();

    final myMatchRef = _db
        .collection("users_cupid")
        .doc(myUid)
        .collection("matches")
        .doc(targetUid);

    final theirMatchRef = _db
        .collection("users_cupid")
        .doc(targetUid)
        .collection("matches")
        .doc(myUid);

    batch.set(
        myMatchRef,
        {
          "uid": targetUid,
          "createdAt": FieldValue.serverTimestamp(),
          "threadId": threadIdFor(myUid, targetUid),
          "lastMessage": null,
          "lastMessageAt": null,
        },
        SetOptions(merge: true));

    batch.set(
        theirMatchRef,
        {
          "uid": myUid,
          "createdAt": FieldValue.serverTimestamp(),
          "threadId": threadIdFor(myUid, targetUid),
          "lastMessage": null,
          "lastMessageAt": null,
        },
        SetOptions(merge: true));

    await batch.commit();

    return SwipeResult(isMatch: true, threadId: threadIdFor(myUid, targetUid));
  }

  Future<void> sendEliteDirectMessage({
    required String myUid,
    required String targetUid,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final threadId = threadIdFor(myUid, targetUid);
    final threadRef = _db.collection("threads").doc(threadId);
    final msgRef = threadRef.collection("messages").doc();
    final now = FieldValue.serverTimestamp();

    final batch = _db.batch();
    batch.set(
      threadRef,
      {
        "threadId": threadId,
        "participants": [myUid, targetUid],
        "updatedAt": now,
        "createdAt": now,
      },
      SetOptions(merge: true),
    );
    batch.set(msgRef, {
      "id": msgRef.id,
      "threadId": threadId,
      "from": myUid,
      "to": targetUid,
      "text": trimmed,
      "createdAt": now,
      "type": "elite_intro",
    });
    await batch.commit();
  }

  String threadIdFor(String a, String b) {
    final x = a.compareTo(b) <= 0 ? a : b;
    final y = a.compareTo(b) <= 0 ? b : a;
    return "${x}_$y";
  }

  Future<void> sendQuickMessage({
    required String myUid,
    required String targetUid,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final threadId = threadIdFor(myUid, targetUid);
    final threadRef = _db.collection("threads").doc(threadId);
    final msgRef = threadRef.collection("messages").doc();

    final now = FieldValue.serverTimestamp();

    // Create thread + add message + update both users' match lastMessage in a single batch
    final batch = _db.batch();

    batch.set(
        threadRef,
        {
          "threadId": threadId,
          "participants": [myUid, targetUid],
          "updatedAt": now,
          "createdAt": now,
        },
        SetOptions(merge: true));

    batch.set(msgRef, {
      "id": msgRef.id,
      "threadId": threadId,
      "from": myUid,
      "to": targetUid,
      "text": trimmed,
      "createdAt": now,
      "type": "text",
    });

    final myMatchRef = _db
        .collection("users_cupid")
        .doc(myUid)
        .collection("matches")
        .doc(targetUid);

    final theirMatchRef = _db
        .collection("users_cupid")
        .doc(targetUid)
        .collection("matches")
        .doc(myUid);

    batch.set(myMatchRef, {"lastMessage": trimmed, "lastMessageAt": now},
        SetOptions(merge: true));
    batch.set(theirMatchRef, {"lastMessage": trimmed, "lastMessageAt": now},
        SetOptions(merge: true));

    await batch.commit();
  }
}

class SwipeResult {
  const SwipeResult({required this.isMatch, this.threadId});
  final bool isMatch;
  final String? threadId;
}
