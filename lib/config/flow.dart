// lib/config/flow.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupid_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../auth/BirthdayScreen.dart';
import '../onboard/basics_screen.dart';
import '../onboard/religion_question_screen.dart';
import '../onboard/ethnicity_question_screen.dart';
import '../onboard/height.dart';
import '../onboard/map.dart';
import '../onboard/work_education_hometown_screen.dart';
import '../onboard/photo_verification_screen.dart';
import '../onboard/match_loading_screen.dart';
import '../onboard/preferences_screen.dart';
import '../onboard/quirk_prompt_screen.dart';
import '../onboard/show_your_story_screen.dart';
import '../onboard/vibe_selection_screen.dart';
import '../onboard/voice_prompt_screen.dart';
import '../widgets/bottomNav.dart';

class AppFlowController extends GetxController {
  AppFlowController({AuthService? authService})
      : _authService = authService ?? AuthService.to;

  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isBusy = false.obs;
  final RxnString error = RxnString();
  final RxnString voiceNotePath = RxnString(); // local path (or later URL)
  User? get firebaseUser => _authService.currentUser;
  bool get isLoggedIn => _authService.isLoggedIn;

  void clearError() => error.value = null;

  // -----------------------------
  // ONBOARDING STATE
  // -----------------------------
  final RxBool onboardingDone = false.obs;

  final Rxn<DateTime> birthday = Rxn<DateTime>();
  final RxnString vibeType = RxnString();

  final RxnString displayName = RxnString();
  final RxnString gender = RxnString();
  final RxnString religion = RxnString();

  // Height: store numeric value in cm, but remember the user's chosen unit for UI.
  final RxString heightUnit = "cm".obs;

  final RxnString sunSign = RxnString();
  final RxnString moonSign = RxnString();
  final RxnString risingSign = RxnString();

  final RxnString ethnicity = RxnString();
  final RxnString datingGoal = RxnString();
  final RxnString sexuality = RxnString();

  final RxnDouble heightCm = RxnDouble();

  final RxnString meetPreference = RxnString();
  final RxList<String> preferences = <String>[].obs;

  final RxBool prefHeightAny = false.obs;
  final RxnDouble prefHeightMinCm = RxnDouble();
  final RxnDouble prefHeightMaxCm = RxnDouble();

  final RxBool prefDistanceAny = false.obs;
  final RxDouble prefDistanceMinMi = 0.0.obs;
  final RxDouble prefDistanceMaxMi = 100.0.obs;

  final RxList<String> preferredEthnicities = <String>[].obs;
  final RxList<String> preferredLanguages = <String>[].obs;

  final RxnString quirkText = RxnString();
  final RxnString storyText = RxnString();
  final RxnString voicePromptText = RxnString();

  final RxnString locationLabel = RxnString();
  final RxnDouble latitude = RxnDouble();
  final RxnDouble longitude = RxnDouble();

  final RxnString workPlace = RxnString();
  final RxnString workRole = RxnString();
  final RxnString educationSchool = RxnString();
  final RxnString educationLevel = RxnString();
  final RxnString hometown = RxnString();

  final RxBool photoVerified = false.obs;
  final RxnString verificationPhotoUrl = RxnString();

  // ✅ NEW: story photos saved as Cloudinary URLs
  final RxList<String> storyPhotoUrls = <String>[].obs;

  // -----------------------------
  // AUTH ACTIONS
  // -----------------------------
  Future<bool> login({required String email, required String password}) async {
    isBusy.value = true;
    error.value = null;
    try {
      final err = await _authService.login(email, password);
      if (err != null) {
        error.value = err;
        return false;
      }
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    File? image,
  }) async {
    isBusy.value = true;
    error.value = null;
    try {
      final err = await _authService.signup(name, email, password, image);
      if (err != null) {
        error.value = err;
        return false;
      }
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> logout() => _authService.logout();

  // -----------------------------
  // FIRESTORE LOAD / HYDRATE
  // -----------------------------
  DateTime? _tryParseDate(dynamic v) {
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> hydrateFromFirestore() async {
    final user = firebaseUser;
    if (user == null) return;
    print(user.email);
    final doc = await _firestore.collection("users_cupid").doc(user.uid).get();
    final data = doc.data();
    if (data == null) return;

    onboardingDone.value = data["onboardingDone"] == true;

    birthday.value = _tryParseDate(data["birthday"]);
    vibeType.value = data["vibeType"] as String?;
    voicePromptText.value = data["voicePromptText"] as String?;
    voiceNotePath.value = data["voiceNotePath"] as String?;
    displayName.value =
        (data["displayName"] as String?) ?? (data["name"] as String?);
    gender.value = data["gender"] as String?;
// AFTER: gender.value = data["gender"] as String?;
    religion.value = data["religion"] as String?;

// heightUnit saved from Height screen
    final hu = data["heightUnit"];
    if (hu is String && (hu == "cm" || hu == "ft")) {
      heightUnit.value = hu;
    }

// Work / Education / Hometown
    workPlace.value = data["workPlace"] as String?;
    workRole.value = data["workRole"] as String?;
    educationSchool.value = data["educationSchool"] as String?;
    educationLevel.value = data["educationLevel"] as String?;
    hometown.value = data["hometown"] as String?;

// Photo verification
    photoVerified.value = data["photoVerified"] == true;
    verificationPhotoUrl.value = data["verificationPhotoUrl"] as String?;
    final bigThree = data["bigThree"];
    if (bigThree is Map) {
      sunSign.value = bigThree["sun"] as String?;
      moonSign.value = bigThree["moon"] as String?;
      risingSign.value = bigThree["rising"] as String?;
    }

    ethnicity.value = data["ethnicity"] as String?;
    datingGoal.value = data["datingGoal"] as String?;
    sexuality.value = data["sexuality"] as String?;

    final h = data["heightCm"];
    if (h is num) heightCm.value = h.toDouble();

    meetPreference.value = data["meetPreference"] as String?;

    final prefs = data["preferences"];
    if (prefs is List) preferences.assignAll(prefs.whereType<String>());

    prefHeightAny.value = data["prefHeightAny"] == true;
    final phMin = data["prefHeightMinCm"] ?? data["prefHeightMinFt"];
    final phMax = data["prefHeightMaxCm"] ?? data["prefHeightMaxFt"];
    if (phMin is num) prefHeightMinCm.value = phMin.toDouble();
    if (phMax is num) prefHeightMaxCm.value = phMax.toDouble();

    prefDistanceAny.value = data["prefDistanceAny"] == true;
    final pdMin = data["prefDistanceMinMi"];
    final pdMax = data["prefDistanceMaxMi"];
    if (pdMin is num) prefDistanceMinMi.value = pdMin.toDouble();
    if (pdMax is num) prefDistanceMaxMi.value = pdMax.toDouble();

    final pe = data["preferredEthnicities"];
    if (pe is List) preferredEthnicities.assignAll(pe.whereType<String>());

    final pl = data["preferredLanguages"];
    if (pl is List) preferredLanguages.assignAll(pl.whereType<String>());

    quirkText.value = data["quirkText"] as String?;
    storyText.value = data["storyText"] as String?;
    voicePromptText.value = data["voicePromptText"] as String?;

    final loc = data["location"];
    if (loc is Map) {
      locationLabel.value = loc["label"] as String?;
      final lat = loc["lat"];
      final lng = loc["lng"];
      if (lat is num) latitude.value = lat.toDouble();
      if (lng is num) longitude.value = lng.toDouble();
    }

    final photos = data["storyPhotoUrls"];
    if (photos is List) storyPhotoUrls.assignAll(photos.whereType<String>());
  }

  // -----------------------------
  // RESUME ROUTE (now includes prefs + quirk + voice + photos)
  // -----------------------------
  Future<dynamic /* Widget */ > getPostAuthRoute() async {
    final user = firebaseUser;
    if (user == null) return const BirthdayScreen();

    await hydrateFromFirestore();
    print(user.email);
    if (onboardingDone.value == true) {
      return const CustomCupidBottomNav(currentIndex: 0);
    }

    if (birthday.value == null) return const BirthdayScreen();
    if (vibeType.value == null || vibeType.value!.isEmpty) {
      return const VibeSelectionScreen();
    }
    if (displayName.value == null ||
        displayName.value!.isEmpty ||
        gender.value == null ||
        gender.value!.isEmpty) {
      return const BasicsScreen();
    }
    if (religion.value == null || religion.value!.isEmpty) {
      return const ReligionQuestionScreen();
    }
    if (heightCm.value == null) return const HeightQuestionScreen();
    if (ethnicity.value == null ||
        datingGoal.value == null ||
        sexuality.value == null) {
      return const EthnicityQuestionScreen();
    }
    if (locationLabel.value == null ||
        latitude.value == null ||
        longitude.value == null) {
      return const LocationQuestionScreen();
    }

    if (workPlace.value == null ||
        workPlace.value!.isEmpty ||
        workRole.value == null ||
        workRole.value!.isEmpty ||
        educationLevel.value == null ||
        educationLevel.value!.isEmpty ||
        hometown.value == null ||
        hometown.value!.isEmpty) {
      return const WorkEducationHometownScreen();
    }

    // ✅ Resume later steps
    final prefsMissing =
        preferredEthnicities.isEmpty || preferredLanguages.isEmpty;
    if (prefsMissing) return const PreferencesScreen();

    if (quirkText.value == null || quirkText.value!.trim().isEmpty) {
      return const CulturalVibeScreen();
    }

    if (voicePromptText.value == null ||
        voicePromptText.value!.trim().isEmpty) {
      return const VoicePromptScreen();
    }

    if (storyPhotoUrls.length < 3) {
      return const ShowYourStoryScreen();
    }

    if (photoVerified.value != true) {
      return const PhotoVerificationScreen();
    }

    return const MatchLoadingScreen();
  }

  // -----------------------------
  // FIRESTORE SAVE
  // -----------------------------
  Future<void> saveOnboardingProgress() async {
    final user = firebaseUser;
    if (user == null) throw StateError("No logged-in user");

    final payload = <String, dynamic>{
      "uid": user.uid,
      "updatedAt": FieldValue.serverTimestamp(),
      "birthday": birthday.value?.toIso8601String(),
      "vibeType": vibeType.value,
      "voicePromptText": voicePromptText.value,
      "voiceNotePath": voiceNotePath.value,
      "displayName": displayName.value,
      "gender": gender.value,
      "religion": religion.value,
      "heightUnit": heightUnit.value,
      "bigThree": {
        "sun": sunSign.value,
        "moon": moonSign.value,
        "rising": risingSign.value,
      },
      "ethnicity": ethnicity.value,
      "datingGoal": datingGoal.value,
      "sexuality": sexuality.value,
      "heightCm": heightCm.value,
      "meetPreference": meetPreference.value,
      "preferences": preferences.toList(),
      "prefHeightAny": prefHeightAny.value,
      "prefHeightMinCm": prefHeightMinCm.value,
      "prefHeightMaxCm": prefHeightMaxCm.value,
      "prefDistanceAny": prefDistanceAny.value,
      "prefDistanceMinMi": prefDistanceMinMi.value,
      "prefDistanceMaxMi": prefDistanceMaxMi.value,
      "preferredEthnicities": preferredEthnicities.toList(),
      "preferredLanguages": preferredLanguages.toList(),
      "quirkText": quirkText.value,
      "storyText": storyText.value,
      "voicePromptText": voicePromptText.value,
      "storyPhotoUrls": storyPhotoUrls.toList(),
      "location": {
        "label": locationLabel.value,
        "lat": latitude.value,
        "lng": longitude.value,
      },
      // Work / Education / Hometown
      "workPlace": workPlace.value,
      "workRole": workRole.value,
      "educationSchool": educationSchool.value,
      "educationLevel": educationLevel.value,
      "hometown": hometown.value,

// Photo verification
      "photoVerified": photoVerified.value,
      "verificationPhotoUrl": verificationPhotoUrl.value,
    };

    payload.removeWhere((_, v) => v == null);

    await _firestore.collection("users_cupid").doc(user.uid).set(
          payload,
          SetOptions(merge: true),
        );
  }

  Future<void> completeOnboarding() async {
    final user = firebaseUser;
    if (user == null) throw StateError("No logged-in user");

    await saveOnboardingProgress();

    await _firestore.collection("users_cupid").doc(user.uid).set(
      {
        "onboardingDone": true,
        "updatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    onboardingDone.value = true;
  }
}
