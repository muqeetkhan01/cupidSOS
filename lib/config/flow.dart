// lib/controllers/app_flow_controller.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupid_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AppFlowController extends GetxController {
  AppFlowController({AuthService? authService})
      : _authService = authService ?? AuthService.to;

  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -----------------------------
  // AUTH STATE
  // -----------------------------
  final RxBool isBusy = false.obs;
  final RxnString error = RxnString();

  User? get firebaseUser => _authService.currentUser;
  bool get isLoggedIn => _authService.isLoggedIn;

  void clearError() => error.value = null;

  // -----------------------------
  // ONBOARDING STATE (shared across all screens)
  // -----------------------------
  final Rxn<DateTime> birthday = Rxn<DateTime>();
  final RxnString vibeType = RxnString(); // e.g. "taurus", "tiger"

  final RxnString displayName = RxnString();
  final RxnString gender = RxnString(); // "woman" | "man" | "other"

  final RxnString sunSign = RxnString();
  final RxnString moonSign = RxnString();
  final RxnString risingSign = RxnString();

  final RxnString ethnicity = RxnString();
  final RxnString datingGoal = RxnString();
  final RxnString sexuality = RxnString();

  final RxnDouble heightCm = RxnDouble();

  final RxnString meetPreference = RxnString();
  final RxList<String> preferences = <String>[].obs;

  final RxnString quirkText = RxnString();
  final RxnString storyText = RxnString();
  final RxnString voicePromptText = RxnString();

  final RxnString locationLabel = RxnString();
  final RxnDouble latitude = RxnDouble();
  final RxnDouble longitude = RxnDouble();

  // -----------------------------
  // AUTH ACTIONS
  // -----------------------------
  Future<bool> login({
    required String email,
    required String password,
  }) async {
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
  // FIRESTORE SAVE (onboarding)
  // -----------------------------
  Future<void> saveOnboardingProgress() async {
    final user = firebaseUser;
    if (user == null) {
      throw StateError("No logged-in user");
    }

    final payload = <String, dynamic>{
      "uid": user.uid,
      "updatedAt": FieldValue.serverTimestamp(),
      "birthday": birthday.value?.toIso8601String(),
      "vibeType": vibeType.value,
      "displayName": displayName.value,
      "gender": gender.value,
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
      "quirkText": quirkText.value,
      "storyText": storyText.value,
      "voicePromptText": voicePromptText.value,
      "location": {
        "label": locationLabel.value,
        "lat": latitude.value,
        "lng": longitude.value,
      },
    };

    // Remove null keys (clean payload)
    payload.removeWhere((_, v) => v == null);

    await _firestore.collection("users").doc(user.uid).set(
          payload,
          SetOptions(merge: true),
        );
  }

  Future<void> completeOnboarding() async {
    final user = firebaseUser;
    if (user == null) {
      throw StateError("No logged-in user");
    }

    await saveOnboardingProgress();

    await _firestore.collection("users").doc(user.uid).set(
      {
        "onboardingDone": true,
        "updatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}