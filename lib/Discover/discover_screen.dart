// lib/Discover/discover_screen.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupid_app/Discover/filter.dart';
import 'package:cupid_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/text_widget.dart';

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

  final List<_DiscoverUser> _profiles = [];
  int _currentIndex = 0;

  bool _loading = true;
  bool _fetchingMore = false;

  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  static const int _pageSize = 20;

  String? get _myUid => AuthService.to.currentUser?.uid;

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
    _entryController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  // -------------------------
  // Firestore fetch
  // -------------------------
  Query<Map<String, dynamic>> _baseQuery() {
    // You can add filters here (age range, distance, etc).
    // For now: only users who finished onboarding.
    return _db
        .collection("users_cupid")
        .where("onboardingDone", isEqualTo: true)
        .orderBy("updatedAt", descending: true);
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _profiles.clear();
      _currentIndex = 0;
      _lastDoc = null;
    });

    await _fetchNextPage();

    if (mounted) {
      setState(() => _loading = false);
    }
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
      final batch = snap.docs
          .map((d) => _DiscoverUser.fromDoc(d))
          .where((u) => myUid == null || u.uid != myUid) // exclude self
          .where((u) =>
              u.photoUrl.isNotEmpty ||
              u.storyPhotoUrls.isNotEmpty) // avoid empty cards
          .toList();

      setState(() {
        _profiles.addAll(batch);
      });
    } finally {
      _fetchingMore = false;
    }
  }

  // -------------------------
  // Swipe & actions
  // -------------------------
  void _swipe(bool right) {
    _swipeTarget = Offset(right ? 500 : -500, 0);
    _swipeController.forward(from: 0);
  }

  Future<void> _persistAction(_DiscoverUser target,
      {required bool liked}) async {
    final myUid = _myUid;
    if (myUid == null) return;

    // Minimal structure; adjust to your schema.
    // /users/{uid}/swipes/{targetUid} = {liked, createdAt}
    await _db
        .collection("users_cupid")
        .doc(myUid)
        .collection("swipes")
        .doc(target.uid)
        .set({
      "targetUid": target.uid,
      "liked": liked,
      "createdAt": FieldValue.serverTimestamp(),
      "snapshot": target.toPublicSnapshot(),
    }, SetOptions(merge: true));
  }

  Future<void> _nextCard() async {
    if (_profiles.isEmpty) return;

    setState(() {
      _dragOffset = Offset.zero;
      _rotation = 0;
      _currentIndex = min(_currentIndex + 1, _profiles.length - 1);
    });

    // Prefetch if we're near the end.
    if (_profiles.length - _currentIndex <= 5) {
      await _fetchNextPage();
    }

    // If still at end and no more fetched -> reset index if list has more than 1
    if (_currentIndex >= _profiles.length - 1 && _profiles.length > 1) {
      // keep at last card; UI will show "No more" if only one.
    }
  }

  // -------------------------
  // Matching score (client-side)
  // -------------------------
  int _matchPercent(_DiscoverUser other) {
    // Simple score, deterministic, no heavy logic.
    // You can replace with server computed score later.
    final me = AuthService.to.currentUser;
    final myName = (me?.displayName ?? "").trim();

    // Use some fields from "other" only (we don't have my full profile doc here).
    // Add mild randomization based on uid hash for variety but stable per pair.
    final seed = other.uid.hashCode ^ myName.hashCode;
    final rnd = Random(seed);

    int base = 70 + rnd.nextInt(20); // 70..89

    // Small boosts if they have vibeType / location set
    if (other.vibeType.isNotEmpty) base += 3;
    if (other.locationLabel.isNotEmpty) base += 3;
    if (other.quirkText.isNotEmpty) base += 2;

    return base.clamp(75, 99);
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final hasProfiles = _profiles.isNotEmpty;
    final current = hasProfiles ? _profiles[_currentIndex] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TextWidget(
                    text: 'Discover',
                    size: 24,
                    weight: FontWeight.bold,
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
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.auto_awesome, size: 18),
                          SizedBox(width: 6),
                          TextWidget(text: 'Filters'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// CARD
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (!hasProfiles
                      ? _emptyState()
                      : AnimatedBuilder(
                          animation: _entryController,
                          builder: (_, __) {
                            final slide = Tween(
                              begin: const Offset(0, 80),
                              end: Offset.zero,
                            ).transform(_entryController.value);

                            return Transform.translate(
                              offset: slide,
                              child: GestureDetector(
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
                                    await _persistAction(target, liked: right);
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
                                    child: _profileCard(
                                      current!,
                                      match: "${_matchPercent(current)}%",
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )),
            ),

            /// ACTION BUTTONS
            Padding(
              padding: EdgeInsets.only(
                bottom: 4.h,
                top: 2.h,
                left: 12.w,
                right: 12.w,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _actionButton(
                    type: ActionType.refresh,
                    icon: Icons.refresh,
                    onTap: () async {
                      await _loadFirstPage();
                      _entryController.forward(from: 0);
                    },
                  ),
                  _actionButton(
                    type: ActionType.reject,
                    icon: Icons.close,
                    onTap: hasProfiles
                        ? () async {
                            final target = _profiles[_currentIndex];
                            await _persistAction(target, liked: false);
                            _swipe(false);
                          }
                        : () {},
                  ),
                  _actionButton(
                    type: ActionType.boost,
                    icon: Icons.flash_on,
                    onTap: hasProfiles
                        ? () async {
                            // You can implement "boost" as a like for now
                            final target = _profiles[_currentIndex];
                            await _persistAction(target, liked: true);
                            _swipe(true);
                          }
                        : () {},
                  ),
                  _actionButton(
                    type: ActionType.like,
                    icon: Icons.favorite,
                    onTap: hasProfiles
                        ? () async {
                            final target = _profiles[_currentIndex];
                            await _persistAction(target, liked: true);
                            _swipe(true);
                          }
                        : () {},
                  ),
                ],
              ),
            ),
          ],
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
              color: Colors.grey.shade700,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.all(const Color(0xFFFF6F7D))),
              onPressed: _loadFirstPage,
              child: const Text(
                "Refresh",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(_DiscoverUser u, {required String match}) {
    final imageUrl = u.heroImageUrl;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w),
      height: 68.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          onError: (_, __) {},
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.72),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                TextWidget(
                  text: u.displayTitle,
                  size: 18,
                  weight: FontWeight.bold,
                  color: Colors.white,
                ),
                const Spacer(),
                _matchBadge(match),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                SizedBox(
                  width: 70.w,
                  child: TextWidget(
                    text: u.locationLabel.isEmpty ? "Unknown" : u.locationLabel,
                    size: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextWidget(
              text: u.bioText.isEmpty ? " " : u.bioText,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: u.tags.take(6).map((t) {
                return Chip(
                  label: TextWidget(text: t, size: 12, color: Colors.white),
                  backgroundColor: Colors.white24,
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchBadge(String percent) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextWidget(
        text: '$percent match',
        weight: FontWeight.bold,
        color: const Color(0xFFFF6F7D),
      ),
    );
  }

  Widget _actionButton({
    required ActionType type,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool isBoost = type == ActionType.boost;

    Color? bgColor;
    Gradient? gradient;
    Color iconColor = Colors.grey;

    switch (type) {
      case ActionType.refresh:
        bgColor = Colors.white;
        iconColor = const Color(0xFFFFA000);
        break;
      case ActionType.reject:
        bgColor = Colors.white;
        iconColor = Colors.redAccent;
        break;
      case ActionType.boost:
        bgColor = const Color(0xFFFFC107);
        iconColor = Colors.white;
        break;
      case ActionType.like:
        gradient = const LinearGradient(
          colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconColor = Colors.white;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 14.w,
        height: 14.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gradient == null ? bgColor : null,
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 26),
      ),
    );
  }
}

// ------------------------------------------------------------
// Model
// ------------------------------------------------------------
class _DiscoverUser {
  final String uid;
  final String name;
  final String photoUrl;

  final String locationLabel;
  final DateTime? birthday;
  final String vibeType;

  final String quirkText;
  final String storyText;
  final String voicePromptText;

  final List<String> storyPhotoUrls;

  final String gender;
  final double? heightCm;
  final String ethnicity;
  final String sexuality;
  final String datingGoal;

  _DiscoverUser({
    required this.uid,
    required this.name,
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
    required this.ethnicity,
    required this.sexuality,
    required this.datingGoal,
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

  static _DiscoverUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
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

    return _DiscoverUser(
      uid: (d["uid"] as String?) ?? doc.id,
      name: name.isEmpty ? "User" : name,
      photoUrl: ((d["photoUrl"] as String?) ?? "").trim(),
      locationLabel: label.trim(),
      birthday: _parseDate(d["birthday"]),
      vibeType: ((d["vibeType"] as String?) ?? "").trim(),
      quirkText: ((d["quirkText"] as String?) ?? "").trim(),
      storyText: ((d["storyText"] as String?) ?? "").trim(),
      voicePromptText: ((d["voicePromptText"] as String?) ?? "").trim(),
      storyPhotoUrls: photos,
      gender: ((d["gender"] as String?) ?? "").trim(),
      heightCm: heightCm,
      ethnicity: ((d["ethnicity"] as String?) ?? "").trim(),
      sexuality: ((d["sexuality"] as String?) ?? "").trim(),
      datingGoal: ((d["datingGoal"] as String?) ?? "").trim(),
    );
  }

  String get heroImageUrl {
    if (storyPhotoUrls.isNotEmpty) return storyPhotoUrls.first;
    if (photoUrl.isNotEmpty) return photoUrl;
    // fallback placeholder (keep stable)
    return "https://images.unsplash.com/photo-1502685104226-ee32379fefbe";
  }

  String get displayTitle {
    final age = _ageFromBirthday(birthday);
    if (age == null) return name;
    return "$name, $age";
  }

  String get bioText {
    // Prefer story text, then quirk text, else empty
    if (storyText.isNotEmpty) return storyText;
    if (quirkText.isNotEmpty) return quirkText;
    return "";
  }

  List<String> get tags {
    final items = <String>[];
    if (vibeType.isNotEmpty) items.add("Vibe: $vibeType");
    if (datingGoal.isNotEmpty) items.add(datingGoal);
    if (ethnicity.isNotEmpty) items.add(ethnicity);
    if (gender.isNotEmpty) items.add(gender);
    if (sexuality.isNotEmpty) items.add(sexuality);
    if (heightCm != null) items.add("${heightCm!.round()} cm");
    return items;
  }

  Map<String, dynamic> toPublicSnapshot() {
    // Keep only non-sensitive fields
    return {
      "uid": uid,
      "name": name,
      "photoUrl": photoUrl,
      "locationLabel": locationLabel,
      "vibeType": vibeType,
      "storyPhotoUrls": storyPhotoUrls,
      "datingGoal": datingGoal,
      "ethnicity": ethnicity,
    };
  }

  static int? _ageFromBirthday(DateTime? birthday) {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday.year;
    final hadBirthdayThisYear = (now.month > birthday.month) ||
        (now.month == birthday.month && now.day >= birthday.day);
    if (!hadBirthdayThisYear) age -= 1;
    if (age < 18 || age > 120) return null; // avoid showing invalid / underage
    return age;
  }
}
