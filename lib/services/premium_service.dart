import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

enum SubscriptionTier { standard, gold, elite }

class PremiumSnapshot {
  const PremiumSnapshot({
    required this.tier,
    required this.coins,
    required this.sosArrowFreeRemaining,
    required this.sosCallFreeRemaining,
  });

  final SubscriptionTier tier;
  final int coins;
  final int sosArrowFreeRemaining;
  final int sosCallFreeRemaining;

  bool get isGoldOrHigher =>
      tier == SubscriptionTier.gold || tier == SubscriptionTier.elite;
  bool get isElite => tier == SubscriptionTier.elite;

  bool get unlimitedLikes => isGoldOrHigher;
  bool get priorityPlacement => isGoldOrHigher;
  bool get advancedFilters => isGoldOrHigher;
  bool get messageBeforeMatch => isElite;
}

class PremiumService {
  PremiumService._();

  static final PremiumService instance = PremiumService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int _freeSosArrowPerDay = 1;
  static const int _freeSosCallPerDay = 1;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _db.collection('users_cupid').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> get _payments =>
      _db.collection('payments');

  String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  SubscriptionTier _tierFrom(dynamic value) {
    final raw = (value as String? ?? '').trim().toLowerCase();
    switch (raw) {
      case 'gold':
        return SubscriptionTier.gold;
      case 'elite':
        return SubscriptionTier.elite;
      default:
        return SubscriptionTier.standard;
    }
  }

  String _tierKey(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.gold:
        return 'gold';
      case SubscriptionTier.elite:
        return 'elite';
      case SubscriptionTier.standard:
        return 'standard';
    }
  }

  Future<void> ensureDefaults(String uid) async {
    await _userRef(uid).set(
      {
        'subscriptionTier': 'standard',
        'coins': FieldValue.increment(0),
        'dailyUsage': const <String, dynamic>{},
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  PremiumSnapshot _snapshotFromData(Map<String, dynamic> data) {
    final tier = _tierFrom(data['subscriptionTier']);
    final coinsValue = data['coins'];
    final coins = coinsValue is num ? coinsValue.toInt() : 0;

    final usage = data['dailyUsage'];
    String arrowDate = '';
    int arrowUsed = 0;
    String callDate = '';
    int callUsed = 0;

    if (usage is Map) {
      final arrow = usage['sosArrow'];
      if (arrow is Map) {
        arrowDate = (arrow['date'] as String? ?? '').trim();
        final used = arrow['used'];
        if (used is num) arrowUsed = used.toInt();
      }
      final call = usage['sosCall'];
      if (call is Map) {
        callDate = (call['date'] as String? ?? '').trim();
        final used = call['used'];
        if (used is num) callUsed = used.toInt();
      }
    }

    final today = _todayKey();
    final arrowRemaining = arrowDate == today
        ? (_freeSosArrowPerDay - arrowUsed).clamp(0, _freeSosArrowPerDay)
        : _freeSosArrowPerDay;
    final callRemaining = callDate == today
        ? (_freeSosCallPerDay - callUsed).clamp(0, _freeSosCallPerDay)
        : _freeSosCallPerDay;

    return PremiumSnapshot(
      tier: tier,
      coins: coins,
      sosArrowFreeRemaining: arrowRemaining,
      sosCallFreeRemaining: callRemaining,
    );
  }

  Stream<PremiumSnapshot> watch(String uid) {
    return _userRef(uid).snapshots().map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      return _snapshotFromData(data);
    });
  }

  Future<PremiumSnapshot> fetch(String uid) async {
    final doc = await _userRef(uid).get();
    final data = doc.data() ?? <String, dynamic>{};
    return _snapshotFromData(data);
  }

  Future<void> upgradeTier(String uid, SubscriptionTier tier) async {
    await _userRef(uid).set(
      {
        'subscriptionTier': _tierKey(tier),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> addCoins(String uid, int amount) async {
    if (amount <= 0) return;
    await _userRef(uid).set(
      {
        'coins': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> purchaseCoinsPackage({
    required String uid,
    required int coins,
    required double amountUsd,
    String gateway = 'in_app_purchase',
    String? packageId,
  }) async {
    if (coins <= 0) return;
    final now = FieldValue.serverTimestamp();
    final paymentRef = _payments.doc();

    final batch = _db.batch();
    batch.set(
      _userRef(uid),
      {
        'coins': FieldValue.increment(coins),
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
    batch.set(
      paymentRef,
      {
        'id': paymentRef.id,
        'uid': uid,
        'kind': 'coins',
        'coins': coins,
        'amountUsd': amountUsd,
        'subscriptionTier': null,
        'gateway': gateway,
        'packageId': packageId,
        'status': 'completed',
        'createdAt': now,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> purchaseSubscription({
    required String uid,
    required SubscriptionTier tier,
    required double amountUsd,
    String gateway = 'in_app_purchase',
    String billingCycle = 'monthly',
  }) async {
    if (tier == SubscriptionTier.standard) return;
    final now = FieldValue.serverTimestamp();
    final paymentRef = _payments.doc();

    final batch = _db.batch();
    batch.set(
      _userRef(uid),
      {
        'subscriptionTier': _tierKey(tier),
        'subscriptionBillingCycle': billingCycle,
        'subscriptionGateway': gateway,
        'subscriptionUpdatedAt': now,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
    batch.set(
      paymentRef,
      {
        'id': paymentRef.id,
        'uid': uid,
        'kind': 'subscription',
        'coins': 0,
        'amountUsd': amountUsd,
        'subscriptionTier': _tierKey(tier),
        'billingCycle': billingCycle,
        'gateway': gateway,
        'status': 'completed',
        'createdAt': now,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<bool> spendCoins(String uid, int amount) async {
    if (amount <= 0) return true;

    return _db.runTransaction((tx) async {
      final ref = _userRef(uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      final currentCoins =
          (data['coins'] is num) ? (data['coins'] as num).toInt() : 0;
      if (currentCoins < amount) return false;

      final ledgerRef = _db.collection('coin_ledger').doc();
      tx.set(
        ref,
        {
          'coins': currentCoins - amount,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        ledgerRef,
        {
          'id': ledgerRef.id,
          'uid': uid,
          'delta': -amount,
          'reason': 'spend',
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
      return true;
    });
  }

  Future<bool> consumeDailyFreeUsage({
    required String uid,
    required String featureKey,
    required int freePerDay,
  }) async {
    if (freePerDay <= 0) return false;

    return _db.runTransaction((tx) async {
      final ref = _userRef(uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};

      final dailyUsage = Map<String, dynamic>.from(
          data['dailyUsage'] as Map? ?? const <String, dynamic>{});
      final usageMap = Map<String, dynamic>.from(
          dailyUsage[featureKey] as Map? ?? const <String, dynamic>{});

      final today = _todayKey();
      final storedDate = (usageMap['date'] as String? ?? '').trim();
      int used =
          storedDate == today ? ((usageMap['used'] as num?)?.toInt() ?? 0) : 0;

      if (used >= freePerDay) {
        return false;
      }

      used += 1;
      dailyUsage[featureKey] = {
        'date': today,
        'used': used,
      };

      tx.set(
        ref,
        {
          'dailyUsage': dailyUsage,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    });
  }

  Future<bool> canMessageBeforeMatch(String uid) async {
    final snap = await fetch(uid);
    return snap.messageBeforeMatch;
  }

  Future<void> bootstrapCurrentUserIfNeeded() async {
    final uid = AuthService.to.currentUser?.uid;
    if (uid == null) return;
    await ensureDefaults(uid);
  }
}
