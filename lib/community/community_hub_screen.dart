import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/services/auth_service.dart';
import 'package:cupid_app/services/community_service.dart';
import 'package:cupid_app/services/premium_service.dart';
import 'package:cupid_app/widgets/button_widget.dart';
import 'package:cupid_app/widgets/text_widget.dart';
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

  final _postCtrl = TextEditingController();

  Map<String, dynamic>? _fortune;
  Map<String, dynamic>? _mystery;
  bool _loadingDaily = true;
  bool _hasFortuneAlert = false;

  late final AnimationController _cookiePulse;

  final List<String> _gamePrompts = const [
    'Hotpot or Not: Surprise your match with a late-night dumpling run?',
    'Hotpot or Not: First date should include family-style sharing?',
    'Hotpot or Not: Voice-note confession beats texting?',
    'Hotpot or Not: Karaoke on date two?',
    'Hotpot or Not: Astrology compatibility as a tie-breaker?',
  ];
  int _gameIndex = 0;
  String? _gameResult;

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
    _postCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRoom(
      {required String type, required bool premiumOnly}) async {
    final uid = _uid;
    if (uid == null) return;

    final titleCtrl = TextEditingController(
      text: type == 'academy'
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
                    _showSnack('Cupid Vows requires Gold or Elite access.');
                    return;
                  }
                }

                await _community.createRoom(
                  ownerUid: uid,
                  title: title,
                  type: type,
                  isPrivate: type != 'academy',
                  premiumOnly: premiumOnly,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _showSnack('Room created. Invite listeners and speakers.');
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinRoom(Map<String, dynamic> room) async {
    final uid = _uid;
    if (uid == null) return;

    final premiumOnly = room['premiumOnly'] == true;
    if (premiumOnly) {
      final snap = await _premium.fetch(uid);
      if (!snap.isGoldOrHigher) {
        _showSnack('Premium room. Upgrade to Gold/Elite to join Cupid Vows.');
        return;
      }
    }

    await _community.joinAsListener(
        roomId: room['id'] as String? ?? '', uid: uid);
    if (!mounted) return;
    _showRoomActions(room);
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
                text: fortuneName.isEmpty
                    ? 'Your personalized fortune is ready.'
                    : 'Suggested: $fortuneName',
                size: 14.5,
                weight: FontWeight.w700,
                color: const Color(0xFFFF6F7D),
              ),
              SizedBox(height: 1.h),
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

  Future<void> _sendPost() async {
    final uid = _uid;
    if (uid == null) return;
    final text = _postCtrl.text.trim();
    if (text.isEmpty) return;

    await _community.createFeedPost(uid: uid, text: text);
    _postCtrl.clear();
    if (!mounted) return;
    _showSnack('Posted to Cupid Hive.');
  }

  Future<void> _commentOnPost(String postId) async {
    final uid = _uid;
    if (uid == null) return;

    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add comment'),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Write your comment'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await _community.addComment(
                    postId: postId, uid: uid, comment: ctrl.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
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
      _gameIndex = (_gameIndex + 1) % _gamePrompts.length;
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
      _gameIndex = (_gameIndex + 1) % _gamePrompts.length;
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
                    _feedTab(uid),
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
          _dailyCard(
            title: 'Mystery Match Box',
            subtitle: 'One weekly suggestion based on behavioral AI.',
            icon: Icons.auto_awesome,
            loading: _loadingDaily,
            name: (_mystery?['targetName'] as String? ?? '').trim(),
            message: (_mystery?['message'] as String? ?? '').trim(),
          ),
        ],
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
        final docs = snap.data?.docs ?? const [];

        return ListView(
          padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 10.h),
          children: [
            Row(
              children: [
                Expanded(
                  child: ButtonWidget(
                    text: 'Create Academy',
                    height: 5.4,
                    radius: 28,
                    variant: ButtonVariant.solid,
                    backgroundColor: CupidColors.surfaceMuted(context),
                    textColor: CupidColors.textPrimary(context),
                    onTap: () =>
                        _createRoom(type: 'academy', premiumOnly: false),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ButtonWidget(
                    text: 'Create Circle',
                    height: 5.4,
                    radius: 28,
                    variant: ButtonVariant.solid,
                    backgroundColor: CupidColors.surfaceMuted(context),
                    textColor: CupidColors.textPrimary(context),
                    onTap: () =>
                        _createRoom(type: 'circle', premiumOnly: false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ButtonWidget(
              text: 'Create Vows (Premium)',
              height: 5.4,
              radius: 28,
              variant: ButtonVariant.gradient,
              gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
              onTap: () => _createRoom(type: 'vows', premiumOnly: true),
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

  Widget _feedTab(String uid) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 1.2.h),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postCtrl,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share something in Cupid Hive...',
                    filled: true,
                    fillColor: CupidColors.surface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: CupidColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: CupidColors.border(context)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: _sendPost,
                icon: const Icon(Icons.send_rounded, color: Color(0xFFFF6F7D)),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _community.watchFeedPosts(),
            builder: (context, snap) {
              final posts = snap.data?.docs ?? const [];
              if (posts.isEmpty) {
                return ListView(
                  padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 10.h),
                  children: [
                    _infoTile(
                        'Cupid Hive is empty. Post the first story, thought, or date tip.'),
                  ],
                );
              }

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(5.w, 0.5.h, 5.w, 10.h),
                itemCount: posts.length,
                itemBuilder: (_, i) {
                  final data = posts[i].data();
                  final postId = (data['id'] as String? ?? posts[i].id).trim();
                  final text = (data['text'] as String? ?? '').trim();
                  final likes = (data['likesCount'] as num?)?.toInt() ?? 0;
                  final comments =
                      (data['commentsCount'] as num?)?.toInt() ?? 0;
                  final createdAt = data['createdAt'];
                  final time = createdAt is Timestamp
                      ? _timeAgo(createdAt.toDate())
                      : 'now';

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
                        TextWidget(
                            text: text, size: 14.5, weight: FontWeight.w600),
                        SizedBox(height: 0.9.h),
                        Row(
                          children: [
                            TextWidget(
                              text: 'Posted $time',
                              size: 12,
                              color: CupidColors.textSecondary(context),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _community.toggleLike(
                                  postId: postId, uid: uid),
                              icon: const Icon(Icons.favorite_border_rounded,
                                  size: 18),
                              label: Text('$likes'),
                            ),
                            TextButton.icon(
                              onPressed: () => _commentOnPost(postId),
                              icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 17),
                              label: Text('$comments'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
                  text: 'Cupid Fun Zone: Hotpot or Not',
                  size: 16,
                  weight: FontWeight.w700),
              SizedBox(height: 0.8.h),
              TextWidget(
                text: _gamePrompts[_gameIndex],
                size: 14,
                color: CupidColors.textPrimary(context),
              ),
              SizedBox(height: 1.2.h),
              Row(
                children: [
                  Expanded(
                    child: ButtonWidget(
                      text: 'Hotpot',
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
                      text: 'Not',
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
                text: 'Cupid Coins Store',
                size: 16,
                weight: FontWeight.w700,
              ),
              SizedBox(height: 1.h),
              _coinsPriceRow(
                title: '100 Coins',
                price: '\$1.99',
                bestFor: 'Try flirty animations',
              ),
              _coinsPriceRow(
                title: '500 Coins',
                price: '\$7.99',
                bestFor: 'Boost + 3 gifts',
              ),
              _coinsPriceRow(
                title: '1,200 Coins',
                price: '\$14.99',
                bestFor: 'VIP chats & mystery match',
              ),
              _coinsPriceRow(
                title: '2,500 Coins',
                price: '\$24.99',
                bestFor: 'Heavy users (Cupid Elite)',
              ),
              SizedBox(height: 1.h),
              _storeButton('Buy 100 Coins', () => _purchaseCoins(100)),
              _storeButton('Buy 500 Coins', () => _purchaseCoins(500)),
              _storeButton('Buy 1,200 Coins', () => _purchaseCoins(1200)),
              _storeButton('Buy 2,500 Coins', () => _purchaseCoins(2500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _coinsPriceRow({
    required String title,
    required String price,
    required String bestFor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 0.8.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: CupidColors.surfaceMuted(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextWidget(text: title, size: 13.8, weight: FontWeight.w700),
          ),
          SizedBox(width: 2.w),
          TextWidget(
            text: price,
            size: 13.8,
            weight: FontWeight.w700,
            color: const Color(0xFFFF6F7D),
          ),
          SizedBox(width: 2.5.w),
          Expanded(
            child: TextWidget(
              text: bestFor,
              size: 12.4,
              color: CupidColors.textSecondary(context),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeButton(String label, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: ButtonWidget(
        text: label,
        height: 5,
        radius: 24,
        variant: ButtonVariant.solid,
        backgroundColor: CupidColors.surfaceMuted(context),
        textColor: CupidColors.textPrimary(context),
        onTap: onTap,
      ),
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
