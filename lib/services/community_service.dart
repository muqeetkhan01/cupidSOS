import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityService {
  CommunityService._();

  static final CommunityService instance = CommunityService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('audio_rooms');
  CollectionReference<Map<String, dynamic>> get _feed =>
      _db.collection('cupid_hive_posts');
  CollectionReference<Map<String, dynamic>> get _academy =>
      _db.collection('academy_content');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRooms(
      {required bool includePrivate}) {
    Query<Map<String, dynamic>> q =
        _rooms.orderBy('updatedAt', descending: true);
    if (!includePrivate) {
      q = q.where('isPrivate', isEqualTo: false);
    }
    return q.snapshots();
  }

  Future<String> createRoom({
    required String ownerUid,
    required String title,
    required String type,
    bool isPrivate = false,
    bool premiumOnly = false,
  }) async {
    final doc = _rooms.doc();
    await doc.set({
      'id': doc.id,
      'ownerUid': ownerUid,
      'title': title.trim(),
      'type': type,
      'isPrivate': isPrivate,
      'premiumOnly': premiumOnly,
      'speakers': <String>[ownerUid],
      'listeners': <String>[],
      'handRaises': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> joinAsListener(
      {required String roomId, required String uid}) async {
    await _rooms.doc(roomId).set({
      'listeners': FieldValue.arrayUnion(<String>[uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> leaveRoom({required String roomId, required String uid}) async {
    await _rooms.doc(roomId).set({
      'listeners': FieldValue.arrayRemove(<String>[uid]),
      'speakers': FieldValue.arrayRemove(<String>[uid]),
      'handRaises': FieldValue.arrayRemove(<String>[uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> raiseHand({required String roomId, required String uid}) async {
    await _rooms.doc(roomId).set({
      'handRaises': FieldValue.arrayUnion(<String>[uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> approveSpeaker({
    required String roomId,
    required String moderatorUid,
    required String targetUid,
  }) async {
    final roomSnap = await _rooms.doc(roomId).get();
    final data = roomSnap.data() ?? <String, dynamic>{};
    final ownerUid = (data['ownerUid'] as String? ?? '').trim();
    final speakers =
        (data['speakers'] as List?)?.whereType<String>().toList() ??
            const <String>[];
    final isMod = moderatorUid == ownerUid || speakers.contains(moderatorUid);
    if (!isMod) {
      throw StateError('Only moderators/speakers can approve requests.');
    }

    await _rooms.doc(roomId).set({
      'speakers': FieldValue.arrayUnion(<String>[targetUid]),
      'listeners': FieldValue.arrayRemove(<String>[targetUid]),
      'handRaises': FieldValue.arrayRemove(<String>[targetUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchFeedPosts() {
    return _feed.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAcademyContent() {
    return _academy
        .where('status', isEqualTo: 'scheduled')
        .orderBy('scheduledAt')
        .limit(20)
        .snapshots();
  }

  Future<String> createFeedPost({
    required String uid,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';

    final doc = _feed.doc();
    await doc.set({
      'id': doc.id,
      'uid': uid,
      'text': trimmed,
      'likesCount': 0,
      'commentsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> toggleLike({required String postId, required String uid}) async {
    final postRef = _feed.doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);

    await _db.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      final postSnap = await tx.get(postRef);
      final data = postSnap.data() ?? <String, dynamic>{};
      final oldCount = (data['likesCount'] as num?)?.toInt() ?? 0;

      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.set(
            postRef,
            {
              'likesCount': max(0, oldCount - 1),
              'updatedAt': FieldValue.serverTimestamp()
            },
            SetOptions(merge: true));
      } else {
        tx.set(likeRef, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(
            postRef,
            {
              'likesCount': oldCount + 1,
              'updatedAt': FieldValue.serverTimestamp()
            },
            SetOptions(merge: true));
      }
    });
  }

  Future<void> addComment({
    required String postId,
    required String uid,
    required String comment,
  }) async {
    final trimmed = comment.trim();
    if (trimmed.isEmpty) return;

    final postRef = _feed.doc(postId);
    final commentRef = postRef.collection('comments').doc();

    await _db.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      final data = postSnap.data() ?? <String, dynamic>{};
      final oldCount = (data['commentsCount'] as num?)?.toInt() ?? 0;

      tx.set(commentRef, {
        'id': commentRef.id,
        'uid': uid,
        'comment': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(
          postRef,
          {
            'commentsCount': oldCount + 1,
            'updatedAt': FieldValue.serverTimestamp()
          },
          SetOptions(merge: true));
    });
  }

  Future<Map<String, dynamic>?> getFortuneCookieSuggestion(String uid) async {
    final todayKey = _todayKey();
    final cacheRef = _db
        .collection('users_cupid')
        .doc(uid)
        .collection('daily_features')
        .doc('fortune_cookie');
    final cached = await cacheRef.get();
    final data = cached.data();
    if (data != null && data['dateKey'] == todayKey) {
      return data;
    }

    final users = await _db
        .collection('users_cupid')
        .where('onboardingDone', isEqualTo: true)
        .limit(40)
        .get();
    final candidates = users.docs.where((d) => d.id != uid).toList();
    if (candidates.isEmpty) return null;

    final seed = DateTime.now().year * 10000 +
        DateTime.now().month * 100 +
        DateTime.now().day +
        uid.hashCode;
    final random = Random(seed);
    final selected = candidates[random.nextInt(candidates.length)].data();

    final result = {
      'dateKey': todayKey,
      'targetUid': (selected['uid'] as String? ?? '').trim(),
      'targetName': (selected['displayName'] as String? ??
              selected['name'] as String? ??
              'Mystery Match')
          .trim(),
      'message': _fortuneMessage(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await cacheRef.set(result, SetOptions(merge: true));
    return result;
  }

  Future<Map<String, dynamic>?> getMysteryMatchSuggestion(String uid) async {
    final weekKey = _weekKey();
    final cacheRef = _db
        .collection('users_cupid')
        .doc(uid)
        .collection('daily_features')
        .doc('mystery_match');
    final cached = await cacheRef.get();
    final data = cached.data();
    if (data != null && data['weekKey'] == weekKey) {
      return data;
    }

    final users = await _db
        .collection('users_cupid')
        .where('onboardingDone', isEqualTo: true)
        .limit(80)
        .get();
    final candidates = users.docs.where((d) => d.id != uid).toList();
    if (candidates.isEmpty) return null;

    final now = DateTime.now();
    final seed = now.year * 100 + _weekOfYear(now) + uid.hashCode;
    final random = Random(seed);
    final selected = candidates[random.nextInt(candidates.length)].data();

    final result = {
      'weekKey': weekKey,
      'targetUid': (selected['uid'] as String? ?? '').trim(),
      'targetName': (selected['displayName'] as String? ??
              selected['name'] as String? ??
              'Mystery Match')
          .trim(),
      'message':
          'Behavioral AI picked this match based on vibe overlap and conversation style.',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await cacheRef.set(result, SetOptions(merge: true));
    return result;
  }

  String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  String _weekKey() {
    final now = DateTime.now();
    return '${now.year}-W${_weekOfYear(now).toString().padLeft(2, '0')}';
  }

  int _weekOfYear(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(start).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  String _fortuneMessage() {
    const messages = <String>[
      'Today\'s match aligns with your communication energy.',
      'Your stars say this person could surprise you in a good way.',
      'Shared values detected. Start with a voice note opener.',
      'A calm heart and a curious mind: this match fits both.',
    ];
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
}
