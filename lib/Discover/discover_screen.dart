import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupid_app/Discover/filter.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/config/colors.dart';
import 'package:cupid_app/profile/user_profile.dart';
import 'package:cupid_app/services/auth_service.dart';
import 'package:cupid_app/services/profile_display.dart';
import 'package:cupid_app/services/premium_service.dart';
import 'package:cupid_app/services/safety_service.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/text_widget.dart';
import '../services/match_service.dart';
import 'got_match_screen.dart';

enum ActionType { refresh, reject, boost, like }

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _swipeController;

  Offset _dragOffset = Offset.zero;
  double _rotation = 0;

  Offset _swipeTarget = Offset.zero;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final MatchService _matchService = MatchService(_db);
  final PremiumService _premiumService = PremiumService.instance;

  final List<DiscoverUser> _profiles = [];
  int _currentIndex = 0;

  bool _fetchingMore = false;

  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  static const int _pageSize = 20;

  String? get _myUid => AuthService.to.currentUser?.uid;

  late AnimationController _buttonPulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _buttonPulseController,
        curve: Curves.easeInOut,
      ),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )
      ..addListener(() {
        setState(() {
          _dragOffset =
              Offset.lerp(_dragOffset, _swipeTarget, _swipeController.value)!;
          _rotation = _dragOffset.dx / 300;
        });
      })
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          await _nextCard();
        }
      });

    _loadFirstPage();
    final uid = _myUid;
    if (uid != null) {
      _premiumService.ensureDefaults(uid);
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _swipeController.dispose();
    _buttonPulseController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _baseQuery() {
    return _db
        .collection("users_cupid")
        .where("onboardingDone", isEqualTo: true)
        .orderBy("updatedAt", descending: true);
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _profiles.clear();
      _currentIndex = 0;
      _lastDoc = null;
    });

    await _fetchNextPage();
  }

  Future<void> _fetchNextPage() async {
    if (_fetchingMore) return;
    _fetchingMore = true;

    try {
      Query<Map<String, dynamic>> q = _baseQuery().limit(_pageSize);
      if (_lastDoc != null) {
        q = q.startAfterDocument(_lastDoc!);
      }

      final snap = await q.get();
      if (snap.docs.isEmpty) return;

      _lastDoc = snap.docs.last;

      final myUid = _myUid;
      final blockedIds = myUid == null
          ? <String>{}
          : await SafetyService.instance.blockedUserIds(myUid);
      final batch = snap.docs
          .map((d) => DiscoverUser.fromDoc(d))
          .where((u) => myUid == null || u.uid != myUid)
          .where((u) => !blockedIds.contains(u.uid))
          .where((u) => u.photoUrl.isNotEmpty || u.storyPhotoUrls.isNotEmpty)
          .toList();

      setState(() {
        _profiles.addAll(batch);
      });
    } finally {
      _fetchingMore = false;
    }
  }

  void _swipe(bool right) {
    _swipeTarget = Offset(right ? 500 : -500, 0);
    _swipeController.forward(from: 0);
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _handleSwipe({
    required DiscoverUser target,
    required bool liked,
  }) async {
    final myUid = _myUid;
    if (myUid == null) return;

    final res = await _matchService.swipe(
      myUid: myUid,
      targetUid: target.uid,
      liked: liked,
      targetSnapshot: target.toPublicSnapshot(),
    );

    if (liked && res.isMatch) {
      Get.to(
        () => GotMatchScreen(
          myUid: myUid,
          targetUid: target.uid,
          targetName: target.name,
          targetPhotoUrl: target.heroImageUrl,
          matchPercentLabel: "${_matchPercent(target)}%",
        ),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  Future<void> _nextCard() async {
    if (_profiles.isEmpty) return;

    setState(() {
      _dragOffset = Offset.zero;
      _rotation = 0;
      _currentIndex = min(_currentIndex + 1, _profiles.length - 1);
    });

    if (_profiles.length - _currentIndex <= 5) {
      await _fetchNextPage();
    }
  }

  int _matchPercent(DiscoverUser other) {
    final me = AuthService.to.currentUser;
    final myName = (me?.displayName ?? "").trim();

    final seed = other.uid.hashCode ^ myName.hashCode;
    final rnd = Random(seed);

    int base = 70 + rnd.nextInt(20);

    if (other.vibeType.isNotEmpty) base += 3;
    if (other.locationLabel.isNotEmpty) base += 3;
    if (other.quirkText.isNotEmpty) base += 2;

    return base.clamp(75, 99);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: CupidColors.pageGradient(context),
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildPremiumHeader(),
              Expanded(child: _buildCardStack()),
              _buildFloatingActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Discover",
            style: GoogleFonts.poppins(
              fontSize: 28,
              color: const Color(0xFFFF6F7D),
              fontWeight: FontWeight.w600,
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (_, __, ___) => const FilterScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: .8.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.18)
                        : Colors.white,
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.tune, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      "Filters",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    if (_profiles.isEmpty) {
      return SizedBox(height: 10.h);
    }

    return Padding(
      padding:
          EdgeInsets.only(left: 4.5.w, right: 4.5.w, bottom: 1.1.h, top: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _animatedAction(
            icon: Icons.close,
            color: Colors.redAccent,
            onTap: () async {
              final target = _profiles[_currentIndex];
              await _handleSwipe(target: target, liked: false);
              _swipe(false);
            },
          ),
          _animatedAction(
            icon: Icons.flash_on,
            color: Colors.amber,
            big: true,
            pulse: true,
            onTap: () async {
              await _sendSosArrow();
            },
          ),
          _animatedAction(
            icon: Icons.videocam_rounded,
            color: Colors.deepPurpleAccent,
            onTap: () async {
              await _requestSosCall();
            },
          ),
          _animatedAction(
            icon: Icons.favorite,
            color: Colors.pinkAccent,
            pulse: true,
            onTap: () async {
              final target = _profiles[_currentIndex];
              await _handleSwipe(target: target, liked: true);
              _swipe(true);
            },
          ),
          _animatedAction(
            icon: Icons.mark_chat_unread_rounded,
            color: Colors.blueAccent,
            onTap: () async {
              await _sendEliteIntroMessage();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendSosArrow() async {
    final myUid = _myUid;
    if (myUid == null || _profiles.isEmpty) return;
    final target = _profiles[_currentIndex];

    bool allowed = await _premiumService.consumeDailyFreeUsage(
      uid: myUid,
      featureKey: 'sosArrow',
      freePerDay: 1,
    );

    if (!allowed) {
      final spent = await _premiumService.spendCoins(myUid, 30);
      if (!spent) {
        _showSnack('No free SOS Arrow left. Need 30 coins.');
        return;
      }
      allowed = true;
    }

    if (!allowed) return;

    await _handleSwipe(target: target, liked: true);
    _swipe(true);
    _showSnack('SOS Arrow sent to ${target.name}.');
  }

  Future<void> _requestSosCall() async {
    final myUid = _myUid;
    if (myUid == null || _profiles.isEmpty) return;
    final target = _profiles[_currentIndex];

    bool allowed = await _premiumService.consumeDailyFreeUsage(
      uid: myUid,
      featureKey: 'sosCall',
      freePerDay: 1,
    );
    if (!allowed) {
      final spent = await _premiumService.spendCoins(myUid, 80);
      if (!spent) {
        _showSnack('No free SOS Call left. Need 80 coins.');
        return;
      }
      allowed = true;
    }

    if (!allowed) return;
    await _handleSwipe(target: target, liked: true);
    _showSnack('SOS Call request sent to ${target.name}.');
  }

  Future<void> _sendEliteIntroMessage() async {
    final myUid = _myUid;
    if (myUid == null || _profiles.isEmpty) return;
    final target = _profiles[_currentIndex];

    final can = await _premiumService.canMessageBeforeMatch(myUid);
    if (!can) {
      _showSnack('Elite only feature. Upgrade to message before matching.');
      return;
    }
    if (!mounted) return;

    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Message ${target.name}'),
          content: TextField(
            controller: ctrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Send your opening move...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await _matchService.sendEliteDirectMessage(
                  myUid: myUid,
                  targetUid: target.uid,
                  text: ctrl.text,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _showSnack('Elite intro sent. You can continue in chat.');
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Widget _animatedAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool big = false,
    bool pulse = false,
  }) {
    final size = big ? 16.8.w : 15.4.w;

    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.88), color],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.34),
            blurRadius: pulse ? 18 : 12,
            spreadRadius: pulse ? 1.2 : 0.4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: big ? 27 : 21),
    );

    if (pulse) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: GestureDetector(onTap: onTap, child: button),
      );
    }

    return GestureDetector(onTap: onTap, child: button);
  }

  Widget _buildCardStack() {
    if (_profiles.isEmpty) return _emptyState();

    return Stack(
      alignment: Alignment.center,
      children: [
        if (_currentIndex + 2 < _profiles.length)
          _stackedCard(_profiles[_currentIndex + 2], scale: 0.92, offset: 40),
        if (_currentIndex + 1 < _profiles.length)
          _stackedCard(_profiles[_currentIndex + 1], scale: 0.96, offset: 20),
        GestureDetector(
          onPanUpdate: (d) {
            setState(() {
              _dragOffset += d.delta;
              _rotation = _dragOffset.dx / 300;
            });
          },
          onPanEnd: (_) async {
            if (_dragOffset.dx.abs() > 120) {
              final right = _dragOffset.dx > 0;
              final target = _profiles[_currentIndex];

              await _handleSwipe(target: target, liked: right);
              _swipe(right);
            } else {
              setState(() {
                _dragOffset = Offset.zero;
                _rotation = 0;
              });
            }
          },
          child: Transform.translate(
            offset: _dragOffset,
            child: Transform.rotate(
              angle: _rotation,
              child: InkWell(
                onTap: () {
                  // FirebaseFirestore.instance
                  //     .collection('users_cupid')
                  //     .doc(_profiles[_currentIndex].uid)
                  //     .delete();
                  // setState(() {});
                  Get.to(() => UserProfileScreen(
                        user: _profiles[_currentIndex],
                        match: "${_matchPercent(_profiles[_currentIndex])}%",
                      ));
                },
                child: _profileCard(
                  _profiles[_currentIndex],
                  match: "${_matchPercent(_profiles[_currentIndex])}%",
                  height: 82.h,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stackedCard(DiscoverUser user,
      {required double scale, required double offset}) {
    return Transform.translate(
      offset: Offset(0, offset),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: 0.7,
          child: _profileCard(
            user,
            match: "${_matchPercent(user)}%",
            height: 82.h,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 46, color: Colors.grey),
            SizedBox(height: 2.h),
            const TextWidget(
              text: "No profiles right now",
              size: 18,
              weight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            TextWidget(
              text:
                  "Try again later or adjust your filters.\nPull to refresh from the top.",
              size: 14,
              color: CupidColors.textSecondary(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor:
                    WidgetStateProperty.all(const Color(0xFFFF6F7D)),
              ),
              onPressed: _loadFirstPage,
              child: Text(
                "Refresh",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

// lib/.../your_discover_screen.dart (where _profileCard lives)

  // Put these INSIDE class _DiscoverScreenState extends State<DiscoverScreen> { ... }

// ✅ Education section (works with your current DiscoverUser where fields are NON-nullable Strings)
  Widget _educationSection(DiscoverUser u) {
    final level = u.educationLevel.trim();
    final school = u.educationSchool.trim();

    if (level.isEmpty && school.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text("🎓", style: TextStyle(fontSize: 14)),
            SizedBox(width: 6),
            TextWidget(
              text: "Education",
              size: 13,
              weight: FontWeight.w700,
              color: Colors.white70,
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (level.isNotEmpty)
          TextWidget(
            text: level,
            size: 14,
            weight: FontWeight.w600,
            color: Colors.white.withOpacity(0.95),
          ),
        if (school.isNotEmpty)
          TextWidget(
            text: school,
            size: 14,
            weight: FontWeight.w600,
            color: Colors.white.withOpacity(0.95),
          ),
      ],
    );
  }

// ✅ Updated _profileCard: shows Education block if present
  Widget _profileCard(DiscoverUser u,
      {required String match, required double height}) {
    final imageUrl = u.heroImageUrl;

    final hasEducation = u.educationLevel.trim().isNotEmpty ||
        u.educationSchool.trim().isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          children: [
            Positioned.fill(
              child: FancyShimmerImage(
                imageUrl: imageUrl,
                boxFit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 0.85],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextWidget(
                            text: u.displayTitle,
                            size: 22,
                            weight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _glassMatchBadge(match),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextWidget(
                            text: u.locationLabel.isEmpty
                                ? "Unknown location"
                                : u.locationLabel,
                            size: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.5.h),
                    if (u.bioText.isNotEmpty)
                      TextWidget(
                        text: u.bioText,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    if (hasEducation) ...[
                      SizedBox(height: 1.6.h),
                      _educationSection(u),
                    ],
                    SizedBox(height: 2.h),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          u.tags.take(9).map((t) => _glassTag(t)).toList(),
                    ),
                    SizedBox(height: 1.5.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _glassMatchBadge(String match) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: TextWidget(
            text: "$match Match",
            size: 12,
            weight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Model
// ------------------------------------------------------------
class DiscoverUser {
  final String uid;
  final String name;
  final String photoUrl;
  final String voiceNoteUrl;
  final String locationLabel;
  final DateTime? birthday;
  final String vibeType;

  final String quirkText;
  final String storyText;
  final String voicePromptText;

  final List<String> storyPhotoUrls;

  final String gender;
  final double? heightCm;

  /// NEW: user's chosen display unit for height ("cm" or "ft")
  final String heightUnit;

  final String ethnicity;
  final String sexuality;
  final String datingGoal;

  /// NEW: Work / Education / Hometown
  final String workPlace;
  final String workRole;
  final String educationLevel;
  final String educationSchool;
  final String hometown;

  DiscoverUser({
    required this.uid,
    required this.name,
    required this.voiceNoteUrl,
    required this.photoUrl,
    required this.locationLabel,
    required this.birthday,
    required this.vibeType,
    required this.quirkText,
    required this.storyText,
    required this.voicePromptText,
    required this.storyPhotoUrls,
    required this.gender,
    required this.heightCm,
    required this.heightUnit,
    required this.ethnicity,
    required this.sexuality,
    required this.datingGoal,
    required this.workPlace,
    required this.workRole,
    required this.educationLevel,
    required this.educationSchool,
    required this.hometown,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _asTrimmedString(dynamic v) => (v is String ? v : "").trim();

  static DiscoverUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final loc = d["location"];
    String label = "";
    if (loc is Map) label = (loc["label"] as String?) ?? "";

    final photos = (d["storyPhotoUrls"] is List)
        ? (d["storyPhotoUrls"] as List).whereType<String>().toList()
        : <String>[];

    final height = d["heightCm"];
    final heightCm = height is num ? height.toDouble() : null;

    final name =
        ((d["displayName"] as String?) ?? (d["name"] as String?) ?? "").trim();

    final heightUnit = _asTrimmedString(d["heightUnit"]);
    final normalizedUnit =
        (heightUnit == "ft" || heightUnit == "cm") ? heightUnit : "cm";

    return DiscoverUser(
      uid: (d["uid"] as String?) ?? doc.id,
      voiceNoteUrl: _asTrimmedString(d["voiceNoteUrl"]).isNotEmpty
          ? _asTrimmedString(d["voiceNoteUrl"])
          : _asTrimmedString(d["voiceNotePath"]),
      name: name.isEmpty ? "User" : name,
      photoUrl: _asTrimmedString(d["photoUrl"]),
      locationLabel: simplifyLocationLabel(label),
      birthday: _parseDate(d["birthday"]),
      vibeType: _asTrimmedString(d["vibeType"]),
      quirkText: _asTrimmedString(d["quirkText"]),
      storyText: _asTrimmedString(d["storyText"]),
      voicePromptText: _asTrimmedString(d["voicePromptText"]),
      storyPhotoUrls: photos,
      gender: visibleProfileValue(_asTrimmedString(d["gender"])),
      heightCm: heightCm,
      heightUnit: normalizedUnit,
      ethnicity: visibleProfileValue(_asTrimmedString(d["ethnicity"])),
      sexuality: visibleProfileValue(_asTrimmedString(d["sexuality"])),
      datingGoal: visibleProfileValue(_asTrimmedString(d["datingGoal"])),

      // NEW fields
      workPlace: _asTrimmedString(d["workPlace"]),
      workRole: _asTrimmedString(d["workRole"]),
      educationLevel: _asTrimmedString(d["educationLevel"]),
      educationSchool: _asTrimmedString(d["educationSchool"]),
      hometown: _asTrimmedString(d["hometown"]),
    );
  }

  String get heroImageUrl {
    if (storyPhotoUrls.isNotEmpty) return storyPhotoUrls.first;
    if (photoUrl.isNotEmpty) return photoUrl;
    return "https://images.unsplash.com/photo-1502685104226-ee32379fefbe";
  }

  String get displayTitle {
    final age = _ageFromBirthday(birthday);
    if (age == null) return name;
    return "$name, $age";
  }

  String get bioText {
    if (storyText.isNotEmpty) return storyText;
    if (quirkText.isNotEmpty) return quirkText;
    return "";
  }

  String _formatHeight() {
    final cm = heightCm;
    if (cm == null) return "";

    if (heightUnit == "ft") {
      final totalInches = (cm / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return "$feet'$inches\"";
    }
    return "${cm.round()} cm";
  }

  List<String> get tags {
    final items = <String>[];
    if (vibeType.isNotEmpty) items.add("Vibe: $vibeType");
    if (datingGoal.isNotEmpty) items.add(datingGoal);
    if (ethnicity.isNotEmpty) items.add(ethnicity);
    if (gender.isNotEmpty) items.add(gender);
    if (sexuality.isNotEmpty) items.add(sexuality);

    final h = _formatHeight();
    if (h.isNotEmpty) items.add(h);

    // Optional extra tags (keep/remove as you like)
    if (educationLevel.isNotEmpty) items.add("🎓 $educationLevel");
    if (hometown.isNotEmpty) items.add("📍 $hometown");

    return items;
  }

  Map<String, dynamic> toPublicSnapshot() {
    return {
      "uid": uid,
      "name": name,
      "photoUrl": photoUrl,
      "locationLabel": locationLabel,
      "vibeType": vibeType,
      "storyPhotoUrls": storyPhotoUrls,
      "datingGoal": datingGoal,
      "ethnicity": ethnicity,
      "voicePromptText": voicePromptText,
      "voiceNoteUrl": voiceNoteUrl,

      // Include if your match system needs them
      "heightCm": heightCm,
      "heightUnit": heightUnit,
      "educationLevel": educationLevel,
      "educationSchool": educationSchool,
      "workPlace": workPlace,
      "workRole": workRole,
      "hometown": hometown,
    };
  }

  static int? _ageFromBirthday(DateTime? birthday) {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday.year;
    final hadBirthdayThisYear = (now.month > birthday.month) ||
        (now.month == birthday.month && now.day >= birthday.day);
    if (!hadBirthdayThisYear) age -= 1;
    if (age < 18 || age > 120) return null;
    return age;
  }
}
