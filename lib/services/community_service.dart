import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupid_app/fortune/fortune_cookie_repository.dart';

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
    String? meetingId,
    String? category,
    String? vibe,
    String? focus,
    List<String> vibeTags = const <String>[],
    bool isPrivate = false,
    bool premiumOnly = false,
    bool verifiedOnly = false,
  }) async {
    final doc = _rooms.doc();
    await doc.set({
      'id': doc.id,
      'ownerUid': ownerUid,
      'title': title.trim(),
      'type': type,
      if ((meetingId ?? '').trim().isNotEmpty) 'meetingId': meetingId!.trim(),
      if ((category ?? '').trim().isNotEmpty) 'category': category!.trim(),
      if ((vibe ?? '').trim().isNotEmpty) 'vibe': vibe!.trim(),
      if ((focus ?? '').trim().isNotEmpty) 'focus': focus!.trim(),
      if (vibeTags.isNotEmpty) 'vibeTags': vibeTags,
      'isPrivate': isPrivate,
      'premiumOnly': premiumOnly,
      'verifiedOnly': verifiedOnly,
      'status': 'live',
      'speakers': <String>[ownerUid],
      'listeners': <String>[],
      'handRaises': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<List<Map<String, dynamic>>> findHiveVibeUsers({
    required String currentUid,
    required List<String> vibeTags,
    int limit = 12,
  }) async {
    final tags = vibeTags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .take(10)
        .toList(growable: false);
    if (tags.isEmpty) return const <Map<String, dynamic>>[];

    final snap = await _db
        .collection('users_cupid')
        .where('interests', arrayContainsAny: tags)
        .limit(30)
        .get();

    final scored = snap.docs
        .where((doc) => doc.id != currentUid)
        .map((doc) {
          final data = doc.data();
          final interests =
              (data['interests'] as List?)?.whereType<String>().toList() ??
                  const <String>[];
          final overlap =
              interests.where((interest) => tags.contains(interest)).toList();
          return <String, dynamic>{
            'uid': doc.id,
            'displayName':
                ((data['displayName'] as String?) ?? (data['name'] as String?))
                    ?.trim(),
            'photoUrl': (data['photoUrl'] as String? ?? '').trim(),
            'photoVerified': data['photoVerified'] == true,
            'interests': interests,
            'overlap': overlap,
            'score': overlap.length,
          };
        })
        .where((user) => (user['score'] as int) > 0)
        .toList();

    scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return scored.take(limit).toList(growable: false);
  }

  Future<void> joinAsListener(
      {required String roomId, required String uid}) async {
    await _rooms.doc(roomId).set({
      'listeners': FieldValue.arrayUnion(<String>[uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> attachMeetingId({
    required String roomId,
    required String meetingId,
  }) async {
    await _rooms.doc(roomId).set({
      'meetingId': meetingId.trim(),
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

  Future<void> endRoom({
    required String roomId,
    required String ownerUid,
  }) async {
    final snap = await _rooms.doc(roomId).get();
    if ((snap.data()?['ownerUid'] as String? ?? '') != ownerUid) return;
    await _rooms.doc(roomId).set({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
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
    if (data != null &&
        data['dateKey'] == todayKey &&
        data['fortuneText'] is String) {
      return data;
    }

    final userSnap = await _db.collection('users_cupid').doc(uid).get();
    final userData = userSnap.data() ?? const <String, dynamic>{};
    final assignment = await _assignFortune(uid, userData);

    final users = await _db
        .collection('users_cupid')
        .where('onboardingDone', isEqualTo: true)
        .limit(40)
        .get();
    final candidates = users.docs.where((d) => d.id != uid).toList();
    if (candidates.isEmpty) {
      final result = <String, dynamic>{
        'dateKey': todayKey,
        'targetUid': '',
        'targetName': '',
        'message': 'Your daily encouragement is ready.',
        'fortuneText': assignment.cookie.text,
        'cookieId': assignment.cookie.id,
        'pool': assignment.pool,
        'matchedTags': assignment.tags,
        'createdAt': Timestamp.now(),
      };
      await cacheRef.set(result, SetOptions(merge: true));
      return result;
    }

    final selectedDoc = _bestCandidate(
      ownerUid: uid,
      owner: userData,
      candidates: candidates,
      seed: todayKey,
    );
    final selected = selectedDoc.data();

    final result = {
      'dateKey': todayKey,
      'targetUid': (selected['uid'] as String? ?? selectedDoc.id).trim(),
      'targetName': (selected['displayName'] as String? ??
              selected['name'] as String? ??
              'Mystery Match')
          .trim(),
      'message': _matchReason(userData, selected),
      'fortuneText': assignment.cookie.text,
      'cookieId': assignment.cookie.id,
      'pool': assignment.pool,
      'matchedTags': assignment.tags,
      'createdAt': Timestamp.now(),
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

    await _db.collection('users_cupid').doc(uid).set({
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final ownerSnap = await _db.collection('users_cupid').doc(uid).get();
    final owner = ownerSnap.data() ?? const <String, dynamic>{};
    final users = await _db
        .collection('users_cupid')
        .where('onboardingDone', isEqualTo: true)
        .limit(80)
        .get();
    final activeCutoff = DateTime.now().subtract(const Duration(days: 7));
    final candidates = users.docs.where((d) {
      if (d.id == uid) return false;
      final data = d.data();
      final active = data['lastActiveAt'] ?? data['updatedAt'];
      return active is Timestamp && active.toDate().isAfter(activeCutoff);
    }).toList();
    if (candidates.isEmpty) return null;

    final selectedDoc = _bestCandidate(
      ownerUid: uid,
      owner: owner,
      candidates: candidates,
      seed: weekKey,
    );
    final selected = selectedDoc.data();

    final result = {
      'weekKey': weekKey,
      'targetUid': (selected['uid'] as String? ?? selectedDoc.id).trim(),
      'targetName': (selected['displayName'] as String? ??
              selected['name'] as String? ??
              'Mystery Match')
          .trim(),
      'message':
          'Picked from your strongest value, vibe, and conversation-style overlaps.',
      'status': 'sealed',
      'createdAt': Timestamp.now(),
    };

    await cacheRef.set(result, SetOptions(merge: true));
    return result;
  }

  Future<Map<String, dynamic>?> openMysteryMatch(String uid) async {
    final ref = _db
        .collection('users_cupid')
        .doc(uid)
        .collection('daily_features')
        .doc('mystery_match');
    final snap = await ref.get();
    final data = snap.data();
    if (data == null || data['weekKey'] != _weekKey()) return null;

    final existingExpiry = data['expiresAt'];
    if (existingExpiry is Timestamp) {
      return {...data, 'status': _mysteryStatus(data)};
    }

    final openedAt = DateTime.now();
    final update = <String, dynamic>{
      'openedAt': Timestamp.fromDate(openedAt),
      'expiresAt': Timestamp.fromDate(openedAt.add(const Duration(hours: 24))),
      'status': 'open',
    };
    await ref.set(update, SetOptions(merge: true));
    return {...data, ...update};
  }

  Future<void> sendMysteryMessage({
    required String uid,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final mysteryRef = _db
        .collection('users_cupid')
        .doc(uid)
        .collection('daily_features')
        .doc('mystery_match');
    final mysterySnap = await mysteryRef.get();
    final mystery = mysterySnap.data() ?? const <String, dynamic>{};
    if (_mysteryStatus(mystery) != 'open') {
      throw StateError('This Mystery Match is no longer open.');
    }

    final targetUid = (mystery['targetUid'] as String? ?? '').trim();
    if (targetUid.isEmpty) throw StateError('Mystery Match is unavailable.');
    final ids = <String>[uid, targetUid]..sort();
    final threadId = '${ids[0]}_${ids[1]}';
    final threadRef = _db.collection('threads').doc(threadId);
    final messageRef = threadRef.collection('messages').doc();
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    batch.set(
        threadRef,
        {
          'threadId': threadId,
          'participants': ids,
          'createdAt': now,
          'updatedAt': now,
          'source': 'mystery_match',
        },
        SetOptions(merge: true));
    batch.set(messageRef, {
      'id': messageRef.id,
      'threadId': threadId,
      'from': uid,
      'to': targetUid,
      'text': trimmed,
      'type': 'mystery_intro',
      'createdAt': now,
    });
    batch.set(
        mysteryRef,
        {
          'status': 'messaged',
          'messageSentAt': now,
        },
        SetOptions(merge: true));
    await batch.commit();
  }

  String mysteryStatus(Map<String, dynamic> mystery) => _mysteryStatus(mystery);

  String _mysteryStatus(Map<String, dynamic> mystery) {
    if (mystery['messageSentAt'] != null || mystery['status'] == 'messaged') {
      return 'messaged';
    }
    final expiresAt = mystery['expiresAt'];
    if (expiresAt is Timestamp && DateTime.now().isAfter(expiresAt.toDate())) {
      return 'expired';
    }
    if (expiresAt is Timestamp) return 'open';
    return 'sealed';
  }

  Future<_FortuneAssignment> _assignFortune(
    String uid,
    Map<String, dynamic> user,
  ) async {
    final fortunes = await FortuneCookieRepository.instance.dailyFortunes();
    if (fortunes.isEmpty) throw StateError('No daily fortunes are available.');

    final history = await _db
        .collection('users_cupid')
        .doc(uid)
        .collection('fortune_history')
        .limit(365)
        .get();
    final readIds = history.docs
        .map((doc) => (doc.data()['cookieId'] as num?)?.toInt())
        .whereType<int>()
        .toSet();

    final cycle = (_daysSinceEpoch(DateTime.now()) + _stableHash(uid)) % 3;
    final desiredPool = switch (cycle) {
      0 => 'value',
      1 => 'vibe',
      _ => 'wildcard',
    };
    final unread = fortunes.where((f) => !readIds.contains(f.id)).toList();
    final source = unread.isEmpty ? fortunes : unread;
    var matching = source
        .where((fortune) => _fortunePool(fortune.text) == desiredPool)
        .toList();
    if (matching.isEmpty) matching = source;

    final tags = _profileTags(user, desiredPool);
    matching.sort((a, b) {
      final aScore = _fortuneTagScore(a.text, tags);
      final bScore = _fortuneTagScore(b.text, tags);
      if (aScore != bScore) return bScore.compareTo(aScore);
      return a.id.compareTo(b.id);
    });
    final bestScore = _fortuneTagScore(matching.first.text, tags);
    final best = matching
        .where((fortune) => _fortuneTagScore(fortune.text, tags) == bestScore)
        .toList();
    final index = _stableHash('$uid:${_todayKey()}') % best.length;
    final selected = best[index];

    await _db
        .collection('users_cupid')
        .doc(uid)
        .collection('fortune_history')
        .doc(_todayKey())
        .set({
      'cookieId': selected.id,
      'pool': desiredPool,
      'tags': tags,
      'servedAt': FieldValue.serverTimestamp(),
    });
    return _FortuneAssignment(selected, desiredPool, tags);
  }

  QueryDocumentSnapshot<Map<String, dynamic>> _bestCandidate({
    required String ownerUid,
    required Map<String, dynamic> owner,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> candidates,
    required String seed,
  }) {
    final ranked = candidates.map((doc) {
      final data = doc.data();
      var score = _profileOverlap(owner, data) * 1000;
      score += _stableHash('$ownerUid:$seed:${doc.id}') % 100;
      return (doc: doc, score: score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return ranked.first.doc;
  }

  int _profileOverlap(Map<String, dynamic> a, Map<String, dynamic> b) {
    var score = 0;
    for (final key in ['vibeType', 'culturalIdentity', 'datingGoal']) {
      final left = (a[key] as String? ?? '').trim().toLowerCase();
      final right = (b[key] as String? ?? '').trim().toLowerCase();
      if (left.isNotEmpty && left == right) score += 4;
    }
    final aInterests = (a['interests'] as List?)
            ?.whereType<String>()
            .map((e) => e.toLowerCase())
            .toSet() ??
        const <String>{};
    final bInterests = (b['interests'] as List?)
            ?.whereType<String>()
            .map((e) => e.toLowerCase())
            .toSet() ??
        const <String>{};
    score += aInterests.intersection(bInterests).length * 2;
    final aAnswers = a['compatibilityAnswers'];
    final bAnswers = b['compatibilityAnswers'];
    if (aAnswers is Map && bAnswers is Map) {
      for (final key in aAnswers.keys.whereType<String>()) {
        final av = aAnswers[key];
        final bv = bAnswers[key];
        if (av is num && bv is num) {
          score += max(0, 4 - (av - bv).abs().round());
        }
      }
    }
    return score;
  }

  String _matchReason(Map<String, dynamic> owner, Map<String, dynamic> match) {
    final ownerAnswers = owner['compatibilityAnswers'];
    final matchAnswers = match['compatibilityAnswers'];
    if (ownerAnswers is Map && matchAnswers is Map) {
      for (final key in ['communication_direct', 'conflict_calm']) {
        final a = ownerAnswers[key];
        final b = matchAnswers[key];
        if (a is num && b is num && (a - b).abs() <= 1) {
          return "Today's match aligns with your communication energy.";
        }
      }
    }
    final culture = (owner['culturalIdentity'] as String? ?? '').trim();
    if (culture.isNotEmpty && culture == match['culturalIdentity']) {
      return "Today's match shares your cultural rhythm.";
    }
    return "Today's match overlaps with your values and relationship pace.";
  }

  List<String> _profileTags(Map<String, dynamic> user, String pool) {
    final tags = <String>[];
    final answers = user['compatibilityAnswers'];
    if (pool == 'value' && answers is Map) {
      final ranked = answers.entries
          .where((e) => e.key is String && e.value is num)
          .toList()
        ..sort((a, b) => (b.value as num).compareTo(a.value as num));
      tags.addAll(ranked.take(3).map((e) => (e.key as String).toLowerCase()));
    } else if (pool == 'vibe') {
      for (final key in ['culturalIdentity', 'vibeType', 'ethnicity']) {
        final value = (user[key] as String? ?? '').trim().toLowerCase();
        if (value.isNotEmpty) tags.add(value);
      }
      tags.addAll((user['interests'] as List?)
              ?.whereType<String>()
              .map((e) => e.toLowerCase()) ??
          const <String>[]);
    } else {
      tags.addAll(const ['confidence', 'action', 'timing']);
    }
    return tags.isEmpty ? const ['universal'] : tags;
  }

  int _fortuneTagScore(String text, List<String> tags) {
    final normalized = text.toLowerCase();
    var score = 0;
    for (final tag in tags) {
      for (final token in tag.split(RegExp(r'[_\s-]+'))) {
        if (token.length > 3 && normalized.contains(token)) score++;
      }
    }
    return score;
  }

  String _fortunePool(String text) {
    final value = text.toLowerCase();
    const vibeWords = [
      'culture',
      'tradition',
      'family',
      'home',
      'journey',
      'adventure',
      'world'
    ];
    const valueWords = [
      'trust',
      'honest',
      'listen',
      'communication',
      'patience',
      'respect',
      'growth',
      'heart',
      'relationship'
    ];
    if (vibeWords.any(value.contains)) return 'vibe';
    if (valueWords.any(value.contains)) return 'value';
    return 'wildcard';
  }

  int _daysSinceEpoch(DateTime date) =>
      DateTime(date.year, date.month, date.day)
          .difference(DateTime(2020))
          .inDays;

  int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
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
}

class _FortuneAssignment {
  const _FortuneAssignment(this.cookie, this.pool, this.tags);

  final FortuneCookie cookie;
  final String pool;
  final List<String> tags;
}
