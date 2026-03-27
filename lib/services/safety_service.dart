import 'package:cloud_firestore/cloud_firestore.dart';

class SafetyService {
  SafetyService._();

  static final SafetyService instance = SafetyService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _blockedRef(String uid) {
    return _db.collection('users_cupid').doc(uid).collection('blocked');
  }

  Future<Set<String>> blockedUserIds(String uid) async {
    final snap = await _blockedRef(uid).get();
    return snap.docs.map((doc) => doc.id).toSet();
  }

  Future<void> reportUser({
    required String reporterUid,
    required String targetUid,
    String? threadId,
    required String reason,
    String? details,
    List<String> screenshotUrls = const <String>[],
  }) async {
    await _db.collection('safety_reports').add({
      'reporterUid': reporterUid,
      'targetUid': targetUid,
      'threadId': threadId,
      'reason': reason,
      'details': (details ?? '').trim(),
      'screenshotUrls': screenshotUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }

  Future<void> unmatchUser({
    required String currentUid,
    required String targetUid,
    String? threadId,
    bool hideThread = true,
  }) async {
    final batch = _db.batch();

    batch.delete(
      _db
          .collection('users_cupid')
          .doc(currentUid)
          .collection('matches')
          .doc(targetUid),
    );
    batch.delete(
      _db
          .collection('users_cupid')
          .doc(targetUid)
          .collection('matches')
          .doc(currentUid),
    );

    if (threadId != null && threadId.trim().isNotEmpty && hideThread) {
      batch.set(
        _db.collection('threads').doc(threadId),
        {
          'hiddenFor': FieldValue.arrayUnion(<String>[currentUid]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> blockUser({
    required String currentUid,
    required String targetUid,
    String? threadId,
    bool removeMatch = true,
    bool hideThread = true,
  }) async {
    final batch = _db.batch();

    batch.set(
      _blockedRef(currentUid).doc(targetUid),
      {
        'targetUid': targetUid,
        'threadId': threadId,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (removeMatch) {
      batch.delete(
        _db
            .collection('users_cupid')
            .doc(currentUid)
            .collection('matches')
            .doc(targetUid),
      );
      batch.delete(
        _db
            .collection('users_cupid')
            .doc(targetUid)
            .collection('matches')
            .doc(currentUid),
      );
    }

    if (threadId != null && threadId.trim().isNotEmpty && hideThread) {
      batch.set(
        _db.collection('threads').doc(threadId),
        {
          'hiddenFor': FieldValue.arrayUnion(<String>[currentUid]),
          'blockedBy': FieldValue.arrayUnion(<String>[currentUid]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}
