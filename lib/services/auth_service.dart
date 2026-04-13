import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart' as gs;
// ✅ NEW
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/cloudinary_config.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<User?> firebaseUser = Rx<User?>(null);

  User? get currentUser => firebaseUser.value;

  @override
  void onInit() {
    firebaseUser.bindStream(_auth.authStateChanges());

    super.onInit();
  }

  // ----------------------------------------------------------
  // CLOUDINARY UPLOAD
  // ----------------------------------------------------------
  Future<String?> uploadProfileImage(File file) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/upload",
      );

      final request = http.MultipartRequest("POST", uri)
        ..fields["upload_preset"] = CloudinaryConfig.uploadPreset
        ..files.add(await http.MultipartFile.fromPath("file", file.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      final data = jsonDecode(resBody);
      return data["secure_url"] as String?;
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------------
  // USER RECORD HELPERS
  // ----------------------------------------------------------
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserDoc(String uid) async {
    try {
      return await _firestore.collection("users_cupid").doc(uid).get();
    } catch (_) {
      return null;
    }
  }

  Future<void> ensureUserRecord({
    required User user,
    String? nameFallback,
  }) async {
    final doc = await getUserDoc(user.uid);
    final exists = doc?.exists ?? false;

    if (exists) {
      await _firestore.collection("users_cupid").doc(user.uid).set(
        {"updatedAt": FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return;
    }

    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (nameFallback?.trim().isNotEmpty == true ? nameFallback!.trim() : "");

    // IMPORTANT: do NOT force onboardingDone true here.
    // New OAuth users must complete onboarding via AppFlowController.
    await _firestore.collection("users_cupid").doc(user.uid).set({
      "uid": user.uid,
      "name": displayName, // can be empty, flow will route to Basics later
      "displayName": displayName,
      "email": user.email ?? "",
      "photoUrl": user.photoURL ?? "",
      "onboardingDone": false,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  // ----------------------------------------------------------
  // SIGNUP (EMAIL/PASSWORD)
  // ----------------------------------------------------------
  Future<String?> signup(
    String name,
    String email,
    String password,
    File? image,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String? photoUrl;
      if (image != null) {
        photoUrl = await uploadProfileImage(image);
      }

      await cred.user!.updateDisplayName(name);
      if (photoUrl != null) await cred.user!.updatePhotoURL(photoUrl);

      await _firestore.collection("users_cupid").doc(cred.user!.uid).set({
        "uid": cred.user!.uid,
        "name": name,
        "displayName": name,
        "email": email,
        "photoUrl": photoUrl ?? "",
        "onboardingDone": false,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      await cred.user!.reload();
      firebaseUser.value = _auth.currentUser;

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ----------------------------------------------------------
  // LOGIN (EMAIL/PASSWORD)
  // ----------------------------------------------------------
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = _auth.currentUser;
      if (user != null) {
        await ensureUserRecord(user: user);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ----------------------------------------------------------
  // PHONE AUTH
  // ----------------------------------------------------------
  Future<String?> sendPhoneCode({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
  }) async {
    final completer = Completer<String?>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            final result = await _auth.signInWithCredential(credential);
            final user = result.user;
            if (user != null) {
              await ensureUserRecord(
                  user: user, nameFallback: user.displayName);
              await user.reload();
              firebaseUser.value = _auth.currentUser;
            }
            if (!completer.isCompleted) completer.complete(null);
          } catch (e) {
            if (!completer.isCompleted) completer.complete(e.toString());
          }
        },
        verificationFailed: (e) {
          if (!completer.isCompleted) {
            completer.complete(_phoneAuthErrorMessage(e));
          }
        },
        codeSent: (verificationId, _) {
          onCodeSent(verificationId);
          if (!completer.isCompleted) completer.complete(null);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          onCodeSent(verificationId);
          if (!completer.isCompleted) completer.complete(null);
        },
      );
    } catch (e) {
      if (!completer.isCompleted) completer.complete(e.toString());
    }

    return completer.future;
  }

  Future<String?> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId.trim(),
        smsCode: smsCode.trim(),
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) return 'Phone sign-in failed';

      await ensureUserRecord(user: user, nameFallback: user.displayName);
      await user.reload();
      firebaseUser.value = _auth.currentUser;
      return null;
    } on FirebaseAuthException catch (e) {
      return _phoneAuthErrorMessage(e);
    } catch (e) {
      return e.toString();
    }
  }

  String _phoneAuthErrorMessage(FirebaseAuthException e) {
    final code = e.code.trim().toLowerCase();
    final message = (e.message ?? '').trim();

    if (code == 'invalid-phone-number') {
      return 'Enter a valid phone number with country code.';
    }
    if (code == 'too-many-requests') {
      return 'Too many attempts right now. Please wait a bit and try again.';
    }
    if (code == 'invalid-verification-code') {
      return 'That code does not look right. Please try again.';
    }
    if (code == 'session-expired') {
      return 'That code expired. Request a new one and try again.';
    }
    if (code == 'internal-error') {
      return 'Phone verification is not fully configured for this iOS build yet. Rebuild the app after syncing the Firebase bundle ID.';
    }

    return message.isNotEmpty ? message : 'Phone verification failed.';
  }

  // ----------------------------------------------------------
  // GOOGLE SIGN-IN (NEW)
  // Returns null on success, error message on failure.
  // ----------------------------------------------------------

// ...

  Future<String?> signInWithGoogle() async {
    try {
      // 1) init GoogleSignIn singleton (safe to call multiple times)
      await gs.GoogleSignIn.instance.initialize(
          // Optional:
          // clientId: kIsWeb ? "<WEB_CLIENT_ID>" : null,
          // serverClientId: "<SERVER_CLIENT_ID>",
          );

      // 2) interactive auth (this is the "sign in" equivalent now)
      if (!gs.GoogleSignIn.instance.supportsAuthenticate()) {
        return "Google sign-in is not supported on this platform";
      }

      final gs.GoogleSignInAccount user =
          await gs.GoogleSignIn.instance.authenticate();

      // 3) get OAuth tokens
      final gs.GoogleSignInAuthentication auth = user.authentication;
      if (auth.idToken == null) return "Missing Google ID token";

      // 4) firebase credential
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final fbUser = result.user;
      if (fbUser == null) return "Firebase sign-in failed";

      // 5) ensure firestore doc exists (so onboarding flow works)
      await ensureUserRecord(user: fbUser, nameFallback: user.displayName);

      // 6) optionally sync name if google provided it
      final fallbackName = (fbUser.displayName?.trim().isNotEmpty == true)
          ? fbUser.displayName!.trim()
          : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : "");

      if (fallbackName.isNotEmpty) {
        await _firestore.collection("users_cupid").doc(fbUser.uid).set(
          {
            "name": fallbackName,
            "displayName": fallbackName,
            "updatedAt": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await fbUser.reload();
      firebaseUser.value = _auth.currentUser;

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } on gs.GoogleSignInException catch (e) {
      return e.description ?? "Google sign-in error: ${e.code}";
    } catch (e) {
      return e.toString();
    }
  }

  // ----------------------------------------------------------
  // APPLE SIGN-IN (NEW)
  // Returns null on success, error message on failure.
  // ----------------------------------------------------------
  String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rand = Random.secure();
    return List.generate(length, (_) => charset[rand.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String?> signInWithApple() async {
    try {
      if (!Platform.isIOS && !Platform.isMacOS) {
        return "Apple Sign-In is only available on Apple platforms";
      }

      final rawNonce = _randomNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final result = await _auth.signInWithCredential(oauthCredential);
      final user = result.user;
      if (user == null) return "Apple sign-in failed";

      // Apple may only provide name once
      final fullName = [
        appleCredential.givenName?.trim(),
        appleCredential.familyName?.trim(),
      ].where((s) => s != null && s.isNotEmpty).map((s) => s!).join(" ");

      await ensureUserRecord(
        user: user,
        nameFallback: fullName.isNotEmpty ? fullName : null,
      );

      // Sync name if available and not already set
      final resolvedName = (user.displayName?.trim().isNotEmpty == true)
          ? user.displayName!.trim()
          : fullName;

      if (resolvedName.isNotEmpty) {
        if ((user.displayName?.trim().isEmpty ?? true)) {
          await user.updateDisplayName(resolvedName);
        }
        await _firestore.collection("users_cupid").doc(user.uid).set(
          {
            "name": resolvedName,
            "displayName": resolvedName,
            "updatedAt": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await user.reload();
      firebaseUser.value = _auth.currentUser;

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } on SignInWithAppleAuthorizationException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ----------------------------------------------------------
  // RESET PASSWORD
  // ----------------------------------------------------------
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ----------------------------------------------------------
  // UPDATE NAME
  // ----------------------------------------------------------
  Future<String?> updateName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) return "No logged-in user";

    try {
      await user.updateDisplayName(newName);

      await _firestore.collection("users_cupid").doc(user.uid).update({
        "name": newName,
        "displayName": newName,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      await user.reload();
      firebaseUser.value = _auth.currentUser;

      return null;
    } catch (_) {
      return "Failed to update name";
    }
  }

  // ----------------------------------------------------------
  // UPDATE PHOTO
  // ----------------------------------------------------------
  Future<String?> updateProfilePhoto(File file) async {
    final user = _auth.currentUser;
    if (user == null) return "No logged-in user";

    try {
      final url = await uploadProfileImage(file);
      if (url == null) return "Upload failed";

      await user.updatePhotoURL(url);

      await _firestore.collection("users_cupid").doc(user.uid).set(
        {
          "photoUrl": url,
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await user.reload();
      firebaseUser.value = _auth.currentUser;

      return null;
    } catch (_) {
      return "Failed to update profile photo";
    }
  }

  // ----------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------
  Future<void> logout() async {
    await _auth.signOut();
  }

  bool get isLoggedIn => firebaseUser.value != null;
}
