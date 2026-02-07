import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
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
      // Always keep timestamps fresh
      await _firestore.collection("users_cupid").doc(user.uid).set(
        {"updatedAt": FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return;
    }

    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (nameFallback?.trim().isNotEmpty == true ? nameFallback!.trim() : "");

    await _firestore.collection("users_cupid").doc(user.uid).set({
      "uid": user.uid,
      "name": displayName,
      "email": user.email ?? "",
      "photoUrl": user.photoURL ?? "",
      "onboardingDone": false,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isOnboardingDone(String uid) async {
    final doc = await getUserDoc(uid);
    final data = doc?.data();
    return data?["onboardingDone"] == true;
  }

  // ----------------------------------------------------------
  // CREATE USER IN FIRESTORE (legacy)
  // ----------------------------------------------------------
  Future<void> createUserRecord({
    required String uid,
    required String name,
    required String email,
    required String? photoUrl,
  }) async {
    await _firestore.collection("users_cupid").doc(uid).set({
      "uid": uid,
      "name": name,
      "email": email,
      "photoUrl": photoUrl ?? "",
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

      await createUserRecord(
        uid: cred.user!.uid,
        name: name,
        email: email,
        photoUrl: photoUrl ?? "",
      );

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
  // GOOGLE SIGN-IN
  // ----------------------------------------------------------
  // Future<String?> signInWithGoogle() async {
  //   try {
  //     final googleUser = await GoogleSignIn().signIn();
  //     if (googleUser == null) return "Google sign-in cancelled";

  //     final googleAuth = await googleUser.authentication;

  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     final result = await _auth.signInWithCredential(credential);
  //     final user = result.user;
  //     if (user == null) return "Google sign-in failed";

  //     await ensureUserRecord(user: user);
  //     return null;
  //   } on FirebaseAuthException catch (e) {
  //     return e.message;
  //   } catch (e) {
  //     return e.toString();
  //   }
  // }

  // ----------------------------------------------------------
  // APPLE SIGN-IN
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
          AppleIDAuthorizationScopes.fullName
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

      // Apple may only provide name/email once; use fullName as fallback if present.
      final fullName = [
        appleCredential.givenName?.trim(),
        appleCredential.familyName?.trim(),
      ].where((s) => s != null && s.isNotEmpty).map((s) => s!).join(" ");

      await ensureUserRecord(
        user: user,
        nameFallback: fullName.isNotEmpty ? fullName : null,
      );

      if (fullName.isNotEmpty && (user.displayName?.isEmpty ?? true)) {
        await user.updateDisplayName(fullName);
      }

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
