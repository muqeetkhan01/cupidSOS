import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupid_app/community/audio_room_screen.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/services/auth_service.dart';
import 'package:cupid_app/services/community_service.dart';
import 'package:cupid_app/services/premium_service.dart';
import 'package:cupid_app/widgets/button_widget.dart';
import 'package:cupid_app/widgets/subscription_review_dialog.dart';
import 'package:cupid_app/widgets/text_widget.dart';
import 'package:cupid_app/video_call/join.dart' show createMeeting;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen>
    with TickerProviderStateMixin {
  final _community = CommunityService.instance;
  final _premium = PremiumService.instance;

  late final TabController _tabs;

  Map<String, dynamic>? _fortune;
  Map<String, dynamic>? _mystery;
  bool _loadingDaily = true;
  bool _hasFortuneAlert = false;

  late final AnimationController _cookiePulse;

  final Map<String, List<String>> _gamePrompts = const {
    'Hotpot or Not': [
      'Surprise your match with a late-night dumpling run?',
      'First date should include family-style sharing?',
      'Voice-note confession beats texting?',
    ],
    'This or That': [
      'Sunrise coffee or midnight dessert?',
      'Plan the date or embrace the surprise?',
      'City lights or quiet cabin?',
    ],
    'Red Flag Radar': [
      'They are kind to you but rude to the server.',
      'They never ask a follow-up question.',
      'They need a full day to cool down after conflict.',
    ],
  };
  String _gameMode = 'Hotpot or Not';
  int _gameIndex = 0;
  String? _gameResult;
  int _selectedCoinPackage = 500;

  List<String> get _currentGamePrompts => _gamePrompts[_gameMode]!;

  List<String> get _currentGameOptions => switch (_gameMode) {
        'This or That' => const ['First', 'Second'],
        'Red Flag Radar' => const ['Red flag', 'Talk it out'],
        _ => const ['Hotpot', 'Not'],
      };

  String? get _uid => AuthService.to.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 4, vsync: this, initialIndex: widget.initialTab.clamp(0, 3));
    _cookiePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _initData();
  }

  Future<void> _initData() async {
    final uid = _uid;
    if (uid == null) return;
    await _premium.ensureDefaults(uid);
    await _loadDailyCards(uid);
  }

  Future<void> _loadDailyCards(String uid) async {
    setState(() => _loadingDaily = true);
    final fortune = await _community.getFortuneCookieSuggestion(uid);
    final mystery = await _community.getMysteryMatchSuggestion(uid);
    if (!mounted) return;
    setState(() {
      _fortune = fortune;
      _mystery = mystery;
      _loadingDaily = false;
      _hasFortuneAlert = _hasFortuneAlert || (fortune != null);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _cookiePulse.dispose();
    super.dispose();
  }

  Future<void> _createRoom({
    required String type,
    required bool premiumOnly,
    String? category,
    String? vibe,
    String? focus,
    List<String> vibeTags = const <String>[],
    bool verifiedOnly = false,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final titleCtrl = TextEditingController(
      text: type == 'hive' && (category ?? '').trim().isNotEmpty
          ? '$category Vibe Check'
          : type == 'academy'
              ? 'Cupid Academy Live'
              : type == 'circle'
                  ? 'Cupid Circle Room'
                  : 'Cupid Vows Blessing Room',
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Room'),
          content: TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: 'Room title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                if (premiumOnly) {
                  final snap = await _premium.fetch(uid);
                  if (!snap.isGoldOrHigher) {
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (mounted) showSubscriptionReviewDialog(context);
                    return;
                  }
                }

                if (verifiedOnly) {
                  final profile = await FirebaseFirestore.instance
                      .collection('users_cupid')
                      .doc(uid)
                      .get();
                  final verified = profile.data()?['photoVerified'] == true;
                  if (!verified) {
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _showSnack('Photo verification is required for this Hive.');
                    return;
                  }
                }

                try {
                  final meetingId = await createMeeting();
                  final roomId = await _community.createRoom(
                    ownerUid: uid,
                    title: title,
                    type: type,
                    category: category,
                    vibe: vibe,
                    focus: focus,
                    vibeTags: vibeTags,
                    meetingId: meetingId,
                    isPrivate: type == 'circle' || type == 'vows',
                    premiumOnly: premiumOnly,
                    verifiedOnly: verifiedOnly,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AudioRoomScreen(
                        meetingId: meetingId,
                        title: title,
                        displayName:
                            AuthService.to.currentUser?.displayName ?? 'Host',
                        startAsSpeaker: true,
                      ),
                    ),
                  );
                  await _community.endRoom(roomId: roomId, ownerUid: uid);
                } catch (_) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnack('Could not start live audio. Please try again.');
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showHostRoomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: CupidColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.5.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: TextWidget(
                  text: 'Host a room',
                  size: 19,
                  weight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 1.8.h),
              _roomTypeOption(
                icon: Icons.public_rounded,
                title: 'Cupid Academy',
                subtitle: 'Public expert-led relationship room',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _createRoom(type: 'academy', premiumOnly: false);
                },
              ),
              _roomTypeOption(
                icon: Icons.groups_2_rounded,
                title: 'Cupid Circle',
                subtitle: 'Invite-only room for families and moderators',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _createRoom(type: 'circle', premiumOnly: false);
                },
              ),
              _roomTypeOption(
                icon: Icons.workspace_premium_rounded,
                title: 'Cupid Vows',
                subtitle: 'Premium private room',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _createRoom(type: 'vows', premiumOnly: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roomTypeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: CupidColors.surfaceMuted(context),
        leading: Icon(icon, color: const Color(0xFFFF6F7D)),
        title: TextWidget(text: title, size: 14.5, weight: FontWeight.w700),
        subtitle: TextWidget(
          text: subtitle,
          size: 12.2,
          color: CupidColors.textSecondary(context),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Future<void> _joinRoom(Map<String, dynamic> room) async {
    final uid = _uid;
    if (uid == null) return;

    final premiumOnly = room['premiumOnly'] == true;
    if (premiumOnly) {
      final snap = await _premium.fetch(uid);
      if (!snap.isGoldOrHigher) {
        if (mounted) showSubscriptionReviewDialog(context);
        return;
      }
    }

    final verifiedOnly = room['verifiedOnly'] == true;
    if (verifiedOnly) {
      final profile = await FirebaseFirestore.instance
          .collection('users_cupid')
          .doc(uid)
          .get();
      if (profile.data()?['photoVerified'] != true) {
        _showSnack('Photo verification is required for this Hive.');
        return;
      }
    }

    final roomId = (room['id'] as String? ?? '').trim();
    if (roomId.isEmpty) return;
    try {
      var meetingId = (room['meetingId'] as String? ?? '').trim();
      if (meetingId.isEmpty) {
        meetingId = await createMeeting();
        await _community.attachMeetingId(
          roomId: roomId,
          meetingId: meetingId,
        );
      }
      await _community.joinAsListener(roomId: roomId, uid: uid);
      if (!mounted) return;
      final speakers =
          (room['speakers'] as List?)?.whereType<String>().toSet() ??
              const <String>{};
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AudioRoomScreen(
            meetingId: meetingId,
            title: (room['title'] as String? ?? 'Cupid Audio Room').trim(),
            displayName:
                AuthService.to.currentUser?.displayName ?? 'Cupid member',
            startAsSpeaker: speakers.contains(uid),
            onRaiseHand: () => _community.raiseHand(roomId: roomId, uid: uid),
          ),
        ),
      );
      await _community.leaveRoom(roomId: roomId, uid: uid);
    } catch (_) {
      _showSnack('Could not join live audio. Please try again.');
    }
  }

  Future<void> _showRoomActions(Map<String, dynamic> room) async {
    final uid = _uid;
    if (uid == null) return;

    final roomId = (room['id'] as String? ?? '').trim();
    if (roomId.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: CupidColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 2.4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: (room['title'] as String? ?? 'Audio Room').trim(),
                size: 18,
                weight: FontWeight.w700,
              ),
              SizedBox(height: 0.8.h),
              TextWidget(
                text:
                    'Use listener/speaker controls for Cupid Academy, Circle, and Vows.',
                size: 13,
                color: CupidColors.textSecondary(context),
              ),
              SizedBox(height: 1.8.h),
              ButtonWidget(
                text: 'Raise Hand',
                height: 5.8,
                radius: 30,
                variant: ButtonVariant.solid,
                backgroundColor: CupidColors.surfaceMuted(context),
                textColor: CupidColors.textPrimary(context),
                onTap: () async {
                  await _community.raiseHand(roomId: roomId, uid: uid);
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  _showSnack('Hand raised. Moderator can move you to speaker.');
                },
              ),
              SizedBox(height: 1.h),
              ButtonWidget(
                text: 'Approve First Hand Raise (Moderator)',
                height: 5.8,
                radius: 30,
                variant: ButtonVariant.solid,
                backgroundColor: CupidColors.surfaceMuted(context),
                textColor: CupidColors.textPrimary(context),
                onTap: () async {
                  final handRaises = (room['handRaises'] as List?)
                          ?.whereType<String>()
                          .toList() ??
                      const <String>[];
                  if (handRaises.isEmpty) {
                    _showSnack('No raised hands right now.');
                    return;
                  }
                  try {
                    await _community.approveSpeaker(
                      roomId: roomId,
                      moderatorUid: uid,
                      targetUid: handRaises.first,
                    );
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    _showSnack('Listener promoted to speaker.');
                  } catch (e) {
                    _showSnack(e.toString());
                  }
                },
              ),
              SizedBox(height: 1.h),
              ButtonWidget(
                text: 'Leave Room',
                height: 5.8,
                radius: 30,
                variant: ButtonVariant.gradient,
                gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                onTap: () async {
                  await _community.leaveRoom(roomId: roomId, uid: uid);
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Color _fortuneGlowColor() {
    final text = ((_fortune?['message'] as String?) ?? '').toLowerCase();
    if (text.contains('academy')) return const Color(0xFFFFC857); // gold
    if (text.contains('match')) return const Color(0xFFFF6F7D); // pink
    return Colors.white; // daily prompt
  }

  Future<void> _openFortuneCookie() async {
    await HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
    if (!mounted) return;

    setState(() => _hasFortuneAlert = false);

    final fortuneName = (_fortune?['targetName'] as String? ?? '').trim();
    final fortuneText = (_fortune?['message'] as String? ?? '').trim();
    final cookieText = (_fortune?['fortuneText'] as String? ?? '').trim();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const TextWidget(
            text: 'Fortune Cookie',
            size: 17,
            weight: FontWeight.w700,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: cookieText.isEmpty
                    ? 'Your personalized fortune is ready.'
                    : cookieText,
                size: 15,
                weight: FontWeight.w700,
              ),
              if (fortuneName.isNotEmpty) ...[
                SizedBox(height: 1.2.h),
                TextWidget(
                  text: 'Suggested: $fortuneName',
                  size: 14.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFFFF6F7D),
                ),
              ],
              SizedBox(height: 0.6.h),
              TextWidget(
                text: fortuneText.isEmpty
                    ? 'No fortune yet. Pull to refresh and check again.'
                    : fortuneText,
                size: 13.5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _fortuneCookieAction() {
    final glow = _fortuneGlowColor();
    final pulse = CurvedAnimation(
      parent: _cookiePulse,
      curve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final spread = 6 + (8 * pulse.value);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.42),
                    blurRadius: spread,
                    spreadRadius: pulse.value * 1.2,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _openFortuneCookie,
                tooltip: 'Open fortune cookie',
                icon: const Icon(Icons.cookie_rounded),
                color: const Color(0xFFFF6F7D),
              ),
            ),
            if (_hasFortuneAlert)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D6D),
                    shape: BoxShape.circle,
                    border: Border.all(color: CupidColors.scaffold(context)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openMysteryBox() async {
    final uid = _uid;
    if (uid == null) return;
    final opened = await _community.openMysteryMatch(uid);
    if (!mounted || opened == null) return;
    setState(() => _mystery = opened);
  }

  Future<void> _sendMysteryIntro() async {
    final uid = _uid;
    if (uid == null) return;
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send your first spark'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Say something curious and kind…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await _community.sendMysteryMessage(
                  uid: uid,
                  text: ctrl.text,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                setState(() => _mystery = {
                      ...?_mystery,
                      'status': 'messaged',
                      'messageSentAt': Timestamp.now(),
                    });
                _showSnack('Spark sent. Your conversation is now in Chat.');
              } catch (error) {
                _showSnack(error.toString().replaceFirst('Bad state: ', ''));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Future<void> _purchaseCoins(int amount) async {
    final uid = _uid;
    if (uid == null) return;
    final price = switch (amount) {
      100 => 1.99,
      500 => 7.99,
      1200 => 14.99,
      2500 => 24.99,
      _ => (amount / 100).toDouble(),
    };
    await _premium.purchaseCoinsPackage(
      uid: uid,
      coins: amount,
      amountUsd: price,
      packageId: 'coins_$amount',
    );
    _showSnack('Purchased $amount Cupid Coins (\$$price).');
  }

  Future<void> _playFunZone(bool hotpotChoice) async {
    final uid = _uid;
    if (uid == null) return;

    final earned = hotpotChoice ? 10 : 6;
    await _premium.addCoins(uid, earned);

    setState(() {
      _gameResult = hotpotChoice
          ? 'Great pick. You earned $earned coins and unlocked a replay token.'
          : 'Interesting answer. You earned $earned coins for participation.';
      _gameIndex = (_gameIndex + 1) % _currentGamePrompts.length;
    });
  }

  Future<void> _useSkipToken() async {
    final uid = _uid;
    if (uid == null) return;
    final ok = await _premium.spendCoins(uid, 20);
    if (!ok) {
      _showSnack('Need 20 coins to skip this question.');
      return;
    }
    setState(() {
      _gameIndex = (_gameIndex + 1) % _currentGamePrompts.length;
      _gameResult = 'You used 20 coins to skip. New question unlocked.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: CupidColors.scaffold(context),
        appBar: AppBar(title: const Text('Community')),
        body: const Center(
          child: TextWidget(
            text: 'Sign in to access Cupid community features.',
            size: 15,
            weight: FontWeight.w600,
          ),
        ),
      );
    }

    return StreamBuilder<PremiumSnapshot>(
      stream: _premium.watch(uid),
      builder: (context, premiumSnap) {
        final premium = premiumSnap.data ??
            const PremiumSnapshot(
              tier: SubscriptionTier.standard,
              coins: 0,
              sosArrowFreeRemaining: 1,
              sosCallFreeRemaining: 1,
            );

        return Scaffold(
          backgroundColor: CupidColors.scaffold(context),
          appBar: AppBar(
            backgroundColor: CupidColors.scaffold(context),
            elevation: 0,
            title: const TextWidget(
              text: 'Cupid Community',
              size: 18,
              weight: FontWeight.w700,
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 2.4.w),
                child: _fortuneCookieAction(),
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              labelColor: const Color(0xFFFF6F7D),
              unselectedLabelColor: CupidColors.textSecondary(context),
              indicatorColor: const Color(0xFFFF6F7D),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Daily'),
                Tab(text: 'Audio'),
                Tab(text: 'Hive'),
                Tab(text: 'Fun/Store'),
              ],
            ),
          ),
          body: Column(
            children: [
              _premiumBanner(premium),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _dailyTab(uid),
                    _audioTab(premium),
                    _hiveTab(uid),
                    _funStoreTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _premiumBanner(PremiumSnapshot premium) {
    return Container(
      margin: EdgeInsets.fromLTRB(5.w, 1.4.h, 5.w, 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1DC), Color(0xFFF6E7FF)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on_rounded, color: Color(0xFFFF6F7D)),
          SizedBox(width: 2.5.w),
          Expanded(
            child: TextWidget(
              text: 'Available Coins: ${premium.coins}',
              size: 13.5,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyTab(String uid) {
    return RefreshIndicator(
      onRefresh: () => _loadDailyCards(uid),
      child: ListView(
        padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 10.h),
        children: [
          _dailyCard(
            title: 'Fortune Cookie Match',
            subtitle:
                'One free daily match suggestion with personalized message.',
            icon: Icons.cookie,
            loading: _loadingDaily,
            name: (_fortune?['targetName'] as String? ?? '').trim(),
            message: (_fortune?['message'] as String? ?? '').trim(),
          ),
          SizedBox(height: 1.4.h),
          _mysteryCard(),
        ],
      ),
    );
  }

  Widget _mysteryCard() {
    final mystery = _mystery;
    final status =
        mystery == null ? 'unavailable' : _community.mysteryStatus(mystery);
    final isOpen = status == 'open';
    final isMessaged = status == 'messaged';
    final isExpired = status == 'expired';
    final name = (mystery?['targetName'] as String? ?? '').trim();
    final expiresAt = mystery?['expiresAt'];
    final remaining = expiresAt is Timestamp
        ? expiresAt.toDate().difference(DateTime.now())
        : null;
    final remainingLabel = remaining == null
        ? ''
        : '${remaining.inHours.clamp(0, 24)}h ${remaining.inMinutes.remainder(60).clamp(0, 59)}m left';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isExpired ? 0.5 : 1,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: CupidColors.surface(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: CupidColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFFF6F7D)),
                SizedBox(width: 8),
                Expanded(
                  child: TextWidget(
                    text: 'Mystery Match Box',
                    size: 15,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.8.h),
            TextWidget(
              text: isExpired
                  ? 'This box faded. A new active match arrives next week.'
                  : isMessaged
                      ? 'You sent the spark—continue the conversation in Chat.'
                      : isOpen
                          ? 'Suggested: $name'
                          : 'One exclusive weekly match. Both of you were active this week.',
              size: isOpen ? 14 : 13,
              weight: isOpen ? FontWeight.w700 : FontWeight.w400,
              color: isOpen
                  ? const Color(0xFFFF6F7D)
                  : CupidColors.textSecondary(context),
            ),
            if (isOpen) ...[
              SizedBox(height: 0.5.h),
              TextWidget(
                text: (mystery?['message'] as String? ?? '').trim(),
                size: 13,
              ),
              SizedBox(height: 0.5.h),
              TextWidget(
                text: '24-hour spark • $remainingLabel',
                size: 12,
                weight: FontWeight.w700,
                color: const Color(0xFFFF6F7D),
              ),
            ],
            if (_loadingDaily)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 4),
              )
            else if (status == 'sealed') ...[
              SizedBox(height: 1.2.h),
              ButtonWidget(
                text: 'Open Mystery Box',
                height: 5.2,
                radius: 26,
                variant: ButtonVariant.gradient,
                gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                onTap: _openMysteryBox,
              ),
            ] else if (isOpen) ...[
              SizedBox(height: 1.2.h),
              ButtonWidget(
                text: 'Send a Spark',
                height: 5.2,
                radius: 26,
                variant: ButtonVariant.gradient,
                gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                onTap: _sendMysteryIntro,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dailyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool loading,
    required String name,
    required String message,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CupidColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFF6F7D)),
              SizedBox(width: 2.w),
              Expanded(
                child: TextWidget(
                  text: title,
                  size: 15,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          TextWidget(
            text: subtitle,
            size: 13,
            color: CupidColors.textSecondary(context),
          ),
          SizedBox(height: 1.2.h),
          if (loading)
            const LinearProgressIndicator(minHeight: 4)
          else if (name.isEmpty)
            const TextWidget(text: 'No suggestion available yet.', size: 13.5)
          else ...[
            TextWidget(
              text: 'Suggested: $name',
              size: 14,
              weight: FontWeight.w700,
              color: const Color(0xFFFF6F7D),
            ),
            SizedBox(height: 0.5.h),
            TextWidget(text: message, size: 13.5),
          ],
        ],
      ),
    );
  }

  String _academyDateLabel(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _academySessionCard(Map<String, dynamic> data) {
    final title = (data['title'] as String? ?? 'Academy Session').trim();
    final description = (data['description'] as String? ?? '').trim();
    final scheduledAt = data['scheduledAt'];
    final dt = scheduledAt is Timestamp ? scheduledAt.toDate() : DateTime.now();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 0.8.h),
      padding: EdgeInsets.all(3.2.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CupidColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: title,
            size: 14.2,
            weight: FontWeight.w700,
          ),
          SizedBox(height: 0.4.h),
          TextWidget(
            text: description.isEmpty ? 'No description' : description,
            size: 12.8,
            color: CupidColors.textSecondary(context),
          ),
          SizedBox(height: 0.4.h),
          TextWidget(
            text: 'Scheduled: ${_academyDateLabel(dt)}',
            size: 12.4,
            color: CupidColors.textSecondary(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showAllAcademySchedules() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: CupidColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 70.h,
            child: Padding(
              padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TextWidget(
                    text: 'All Academy Schedules',
                    size: 17,
                    weight: FontWeight.w700,
                  ),
                  SizedBox(height: 1.h),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _community.watchAcademyContent(),
                      builder: (context, snap) {
                        final docs = snap.data?.docs ?? const [];
                        if (docs.isEmpty) {
                          return ListView(
                            children: [
                              _infoTile(
                                'No scheduled academy sessions yet. Check back soon.',
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (_, i) =>
                              _academySessionCard(docs[i].data()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _academyScheduleSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _community.watchAcademyContent(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: TextWidget(
                    text: 'Cupid Academy Schedule',
                    size: 16.5,
                    weight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: _showAllAcademySchedules,
                  child: const Text('Browse All >'),
                ),
              ],
            ),
            if (docs.isEmpty)
              _infoTile('No scheduled academy sessions yet. Check back soon.')
            else
              ...docs.take(3).map((doc) => _academySessionCard(doc.data())),
          ],
        );
      },
    );
  }

  Widget _audioTab(PremiumSnapshot premium) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _community.watchRooms(includePrivate: true),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? const [])
            .where((doc) => doc.data()['type'] != 'hive')
            .where((doc) => doc.data()['status'] != 'ended')
            .toList();

        return ListView(
          padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 10.h),
          children: [
            ButtonWidget(
              text: '+  Host a room',
              height: 6,
              radius: 30,
              variant: ButtonVariant.gradient,
              gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
              onTap: _showHostRoomSheet,
            ),
            SizedBox(height: 1.4.h),
            TextWidget(
              text: premium.isGoldOrHigher
                  ? 'Premium audio access enabled (Vows included).'
                  : 'Upgrade for Cupid Vows premium room access.',
              size: 13,
              color: CupidColors.textSecondary(context),
            ),
            SizedBox(height: 1.6.h),
            _academyScheduleSection(),
            SizedBox(height: 0.6.h),
            _infoTile(
                'Mandatory onboarding completed users can access this section.'),
            _infoTile('Cupid Academy and Circle unlock post-onboarding.'),
            _infoTile('Cupid Vows room requires premium tier token access.'),
            SizedBox(height: 0.8.h),
            if (docs.isEmpty)
              _infoTile('No rooms live now. Create one and invite listeners.')
            else
              ...docs.map((doc) {
                final room = doc.data();
                final title = (room['title'] as String? ?? 'Audio Room').trim();
                final type = (room['type'] as String? ?? '').trim();
                final premiumOnly = room['premiumOnly'] == true;
                final speakers =
                    (room['speakers'] as List?)?.whereType<String>().length ??
                        0;
                final listeners =
                    (room['listeners'] as List?)?.whereType<String>().length ??
                        0;
                final raised =
                    (room['handRaises'] as List?)?.whereType<String>().length ??
                        0;

                return Container(
                  margin: EdgeInsets.only(bottom: 1.2.h),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: CupidColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CupidColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextWidget(
                              text: title,
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                          if (premiumOnly)
                            const Icon(Icons.lock_outline_rounded, size: 18),
                          IconButton(
                            tooltip: 'Room controls',
                            onPressed: () => _showRoomActions(room),
                            icon: const Icon(Icons.more_horiz_rounded),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.4.h),
                      TextWidget(
                        text:
                            'Type: ${type.toUpperCase()} • Speakers: $speakers • Listeners: $listeners • Raised hands: $raised',
                        size: 12.5,
                        color: CupidColors.textSecondary(context),
                      ),
                      SizedBox(height: 1.h),
                      ButtonWidget(
                        text: 'Join Room',
                        height: 5,
                        radius: 24,
                        variant: ButtonVariant.solid,
                        backgroundColor: CupidColors.surfaceMuted(context),
                        textColor: CupidColors.textPrimary(context),
                        onTap: () => _joinRoom(room),
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> get _hiveCategories => const [
        {
          'name': 'The Social',
          'vibe': 'Social & Casual',
          'focus': 'Making new friends & meeting people.',
          'icon': Icons.people_alt_rounded,
          'colors': [Color(0xFFFF7A8A), Color(0xFF8D3B72)],
          'tags': [
            '🎤 Karaoke',
            '🎭 Theater',
            '🎧 Music',
            '☕ Coffee',
            '🍵 Tea'
          ],
        },
        {
          'name': 'The Connection',
          'vibe': 'Intentional',
          'focus': 'Serious dating & meaningful matches.',
          'icon': Icons.favorite_rounded,
          'colors': [Color(0xFFFF5F7E), Color(0xFF9A2145)],
          'tags': [
            '🏠 Homebody',
            '📖 Reading',
            '☕ Coffee',
            '🍵 Tea',
            '🌿 Plants'
          ],
        },
        {
          'name': 'Taste',
          'vibe': 'Foodie Aesthetic',
          'focus': 'Boba, dining, coffee, & late-night cravings.',
          'icon': Icons.restaurant_menu_rounded,
          'colors': [Color(0xFFFFA24D), Color(0xFF8B3E12)],
          'tags': [
            '🧋 Boba',
            '🍜 Ramen',
            '🥟 Dumplings',
            '🍣 Sushi',
            '🍲 Hot Pot',
            '🥡 Takeout',
            '🍛 Curry',
            '🍰 Desserts',
            '☕ Coffee',
            '🍵 Tea'
          ],
        },
        {
          'name': 'Culture',
          'vibe': 'Fandom & Media',
          'focus': 'K-pop, anime, music, & binge-watching.',
          'icon': Icons.theater_comedy_rounded,
          'colors': [Color(0xFF7A4FD4), Color(0xFF3D235F)],
          'tags': [
            '📺 K-Drama',
            '🎬 Anime',
            '🎵 K-Pop',
            '📚 Manga',
            '🎧 Music'
          ],
        },
        {
          'name': 'Play',
          'vibe': 'Gaming & Fun',
          'focus': 'Gaming, karaoke, & entertainment.',
          'icon': Icons.sports_esports_rounded,
          'colors': [Color(0xFF39A7FF), Color(0xFF174A8B)],
          'tags': [
            '🎮 Gaming',
            '🎤 Karaoke',
            '🀄 Mahjong',
            '🏓 Ping Pong',
            '🎬 Anime'
          ],
        },
        {
          'name': 'Active',
          'vibe': 'Wellness & Glow',
          'focus': 'Gym, sports, yoga, & fitness journeys.',
          'icon': Icons.fitness_center_rounded,
          'colors': [Color(0xFF37C48B), Color(0xFF176B4F)],
          'tags': [
            '🏸 Badminton',
            '🏓 Ping Pong',
            '🧘 Yoga',
            '🏋️ Gym',
            '🏃 Running',
            '🚴 Cycling',
            '🏊 Swimming'
          ],
        },
        {
          'name': 'Escapade',
          'vibe': 'Travel & Thrills',
          'focus': 'Hiking, skiing, travel, & adventures.',
          'icon': Icons.flight_takeoff_rounded,
          'colors': [Color(0xFF2E9BC5), Color(0xFF17405F)],
          'tags': [
            '✈️ Travel',
            '🥾 Hiking',
            '🎿 Skiing',
            '🧗 Climbing',
            '🏃 Running'
          ],
        },
        {
          'name': 'Studio',
          'vibe': 'Aesthetic & Style',
          'focus': 'Art, photography, fashion, & K-beauty.',
          'icon': Icons.palette_rounded,
          'colors': [Color(0xFFDD4FA3), Color(0xFF65235C)],
          'tags': [
            '🎨 Art',
            '📸 Photography',
            '👗 Fashion',
            '✨ K-Beauty',
            '🎭 Theater'
          ],
        },
        {
          'name': 'Verified',
          'vibe': 'The VIP Room',
          'focus': 'A safe space for photo-verified users only.',
          'icon': Icons.verified_rounded,
          'colors': [Color(0xFF111827), Color(0xFF4F46E5)],
          'verifiedOnly': true,
          'tags': [
            '📸 Photography',
            '☕ Coffee',
            '🎧 Music',
            '✈️ Travel',
            '📖 Reading'
          ],
        },
        {
          'name': 'Sanctuary',
          'vibe': 'Life & Comfort',
          'focus': 'Animal parents, plants, comfort, & softer life moments.',
          'icon': Icons.pets_rounded,
          'colors': [Color(0xFF74B66B), Color(0xFF315F3C)],
          'tags': [
            '🐱 Cat Person',
            '🐶 Dog Person',
            '🌿 Plants',
            '🏠 Homebody',
            '📖 Reading'
          ],
        },
      ];

  Widget _hiveTab(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _community.watchRooms(includePrivate: false),
      builder: (context, snap) {
        final rooms = (snap.data?.docs ?? const [])
            .map((doc) => doc.data())
            .where((room) => room['type'] == 'hive')
            .where((room) => room['status'] != 'ended')
            .toList();
        return ListView(
          padding: EdgeInsets.fromLTRB(5.w, 1.2.h, 5.w, 11.h),
          children: [
            const TextWidget(
              text: 'Explore Hives',
              size: 20,
              weight: FontWeight.w800,
            ),
            SizedBox(height: 0.4.h),
            TextWidget(
              text:
                  'Live rooms for shared interests and hobbies, matched by Vibe Check.',
              size: 13.2,
              color: CupidColors.textSecondary(context),
            ),
            SizedBox(height: 1.7.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.83,
              ),
              itemCount: _hiveCategories.length,
              itemBuilder: (_, index) {
                final category = _hiveCategories[index];
                final name = category['name'] as String;
                final vibe = category['vibe'] as String;
                final focus = category['focus'] as String;
                final tags = category['tags'] as List<String>;
                final categoryRooms =
                    rooms.where((room) => room['category'] == name).toList();
                final people = categoryRooms.fold<int>(0, (total, room) {
                  final speakers = (room['speakers'] as List?)?.length ?? 0;
                  final listeners = (room['listeners'] as List?)?.length ?? 0;
                  return total + speakers + listeners;
                });
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _showHiveRooms(category, categoryRooms),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: category['colors'] as List<Color>,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(category['icon'] as IconData,
                                  color: Colors.white, size: 28),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.24),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: TextWidget(
                                  text: '$people',
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          TextWidget(
                            text: name,
                            size: 17,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          TextWidget(
                            text: vibe,
                            size: 12.2,
                            weight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                          const SizedBox(height: 5),
                          TextWidget(
                            text: focus,
                            size: 10.8,
                            maxLines: 2,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                          const SizedBox(height: 7),
                          TextWidget(
                            text: _roomTagsPreview(tags),
                            size: 10.2,
                            maxLines: 1,
                            color: Colors.white.withValues(alpha: 0.74),
                          ),
                          const SizedBox(height: 4),
                          TextWidget(
                            text: categoryRooms.isEmpty
                                ? 'Start the first room'
                                : '${categoryRooms.length} live ${categoryRooms.length == 1 ? 'room' : 'rooms'}',
                            size: 11.5,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _roomTagsPreview(List<String> tags) {
    return tags
        .take(3)
        .map((tag) => tag.split(' ').skip(1).join(' ').trim())
        .where((tag) => tag.isNotEmpty)
        .join(' • ');
  }

  Future<void> _showHiveRooms(
    Map<String, dynamic> category,
    List<Map<String, dynamic>> rooms,
  ) async {
    final uid = _uid;
    final name = category['name'] as String;
    final vibe = category['vibe'] as String;
    final focus = category['focus'] as String;
    final tags = category['tags'] as List<String>;
    final verifiedOnly = category['verifiedOnly'] == true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CupidColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: 60.h,
          child: Padding(
            padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.5.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: name,
                  size: 20,
                  weight: FontWeight.w800,
                ),
                SizedBox(height: 0.4.h),
                TextWidget(
                  text: '$vibe • $focus',
                  size: 13,
                  color: CupidColors.textSecondary(context),
                ),
                SizedBox(height: 1.5.h),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.take(5).map((tag) {
                    return Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(tag),
                      backgroundColor: CupidColors.surfaceMuted(context),
                      side: BorderSide(color: CupidColors.border(context)),
                    );
                  }).toList(),
                ),
                SizedBox(height: 1.5.h),
                _hiveMatchedUsers(uid, tags),
                SizedBox(height: 1.5.h),
                Expanded(
                  child: rooms.isEmpty
                      ? Center(
                          child: TextWidget(
                            text:
                                'No $name rooms live yet—host the first Vibe Check.',
                            size: 14,
                            color: CupidColors.textSecondary(context),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          itemCount: rooms.length,
                          separatorBuilder: (_, __) => SizedBox(height: 0.8.h),
                          itemBuilder: (_, index) {
                            final room = rooms[index];
                            return ListTile(
                              tileColor: CupidColors.surfaceMuted(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              title: TextWidget(
                                text: (room['title'] as String? ?? name).trim(),
                                size: 14,
                                weight: FontWeight.w700,
                              ),
                              subtitle: TextWidget(
                                text:
                                    '${(room['vibe'] as String? ?? vibe).trim()} • Live now',
                                size: 12,
                                color: Color(0xFFFF6F7D),
                              ),
                              trailing: const Icon(Icons.arrow_forward_rounded),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                _joinRoom(room);
                              },
                            );
                          },
                        ),
                ),
                ButtonWidget(
                  text: '+  Host a $name room',
                  height: 5.8,
                  radius: 28,
                  variant: ButtonVariant.gradient,
                  gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _createRoom(
                      type: 'hive',
                      category: name,
                      vibe: vibe,
                      focus: focus,
                      vibeTags: tags,
                      premiumOnly: false,
                      verifiedOnly: verifiedOnly,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hiveMatchedUsers(String? uid, List<String> tags) {
    if (uid == null) return const SizedBox.shrink();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _community.findHiveVibeUsers(
        currentUid: uid,
        vibeTags: tags,
        limit: 8,
      ),
      builder: (context, snap) {
        final users = snap.data ?? const <Map<String, dynamic>>[];
        if (snap.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        if (users.isEmpty) {
          return TextWidget(
            text:
                'Vibe Check will surface people here as matching members join.',
            size: 12.5,
            color: CupidColors.textSecondary(context),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextWidget(
              text: 'Vibe Check matches',
              size: 13.5,
              weight: FontWeight.w800,
            ),
            SizedBox(height: 0.8.h),
            SizedBox(
              height: 7.8.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: users.length,
                separatorBuilder: (_, __) => SizedBox(width: 2.5.w),
                itemBuilder: (_, index) {
                  final user = users[index];
                  final name =
                      (user['displayName'] as String? ?? 'Cupid member').trim();
                  final photoUrl = (user['photoUrl'] as String? ?? '').trim();
                  final overlap = (user['overlap'] as List?)
                          ?.whereType<String>()
                          .toList() ??
                      const <String>[];
                  return SizedBox(
                    width: 20.w,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: CupidColors.surfaceMuted(context),
                          backgroundImage:
                              photoUrl.isEmpty ? null : NetworkImage(photoUrl),
                          child: photoUrl.isEmpty
                              ? const Icon(Icons.person_rounded)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: name,
                          size: 10.5,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                        TextWidget(
                          text: '${overlap.length} shared',
                          size: 9.5,
                          color: CupidColors.textSecondary(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _funStoreTab() {
    return ListView(
      padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 10.h),
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: CupidColors.surface(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: CupidColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextWidget(
                  text: 'Cupid Fun Zone', size: 16, weight: FontWeight.w700),
              SizedBox(height: 0.8.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _gamePrompts.keys.map((mode) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(mode),
                        selected: _gameMode == mode,
                        onSelected: (_) => setState(() {
                          _gameMode = mode;
                          _gameIndex = 0;
                          _gameResult = null;
                        }),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 1.2.h),
              TextWidget(
                text: _currentGamePrompts[_gameIndex],
                size: 14,
                color: CupidColors.textPrimary(context),
              ),
              SizedBox(height: 1.2.h),
              Row(
                children: [
                  Expanded(
                    child: ButtonWidget(
                      text: _currentGameOptions.first,
                      height: 5.2,
                      radius: 26,
                      variant: ButtonVariant.solid,
                      backgroundColor: CupidColors.surfaceMuted(context),
                      textColor: CupidColors.textPrimary(context),
                      onTap: () => _playFunZone(true),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ButtonWidget(
                      text: _currentGameOptions.last,
                      height: 5.2,
                      radius: 26,
                      variant: ButtonVariant.solid,
                      backgroundColor: CupidColors.surfaceMuted(context),
                      textColor: CupidColors.textPrimary(context),
                      onTap: () => _playFunZone(false),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0.8.h),
              TextButton(
                onPressed: _useSkipToken,
                child: const Text('Use 20 coins to skip question'),
              ),
              if ((_gameResult ?? '').isNotEmpty)
                TextWidget(
                  text: _gameResult!,
                  size: 12.8,
                  color: CupidColors.textSecondary(context),
                ),
            ],
          ),
        ),
        SizedBox(height: 1.4.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: CupidColors.surface(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: CupidColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextWidget(
                text: 'Cupid Coins',
                size: 16,
                weight: FontWeight.w700,
              ),
              SizedBox(height: 0.5.h),
              TextWidget(
                text:
                    'Choose one pack. You will review the purchase before payment.',
                size: 12.5,
                color: CupidColors.textSecondary(context),
              ),
              SizedBox(height: 1.2.h),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [100, 500, 1200, 2500].map((coins) {
                  final price = switch (coins) {
                    100 => '\$1.99',
                    500 => '\$7.99',
                    1200 => '\$14.99',
                    _ => '\$24.99',
                  };
                  return ChoiceChip(
                    label: Text('$coins • $price'),
                    selected: _selectedCoinPackage == coins,
                    onSelected: (_) =>
                        setState(() => _selectedCoinPackage = coins),
                  );
                }).toList(),
              ),
              SizedBox(height: 1.3.h),
              ButtonWidget(
                text: 'Continue with $_selectedCoinPackage Coins',
                height: 5.4,
                radius: 26,
                variant: ButtonVariant.gradient,
                gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                onTap: () => _purchaseCoins(_selectedCoinPackage),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTile(String text) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 0.8.h),
      padding: EdgeInsets.all(3.2.w),
      decoration: BoxDecoration(
        color: CupidColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CupidColors.border(context)),
      ),
      child: TextWidget(text: text, size: 12.8),
    );
  }
}
