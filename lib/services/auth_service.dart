// lib/services/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

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

      print("📤 Cloudinary Response: $resBody");

      final data = jsonDecode(resBody);

      if (data["secure_url"] == null) {
        print("❌ Cloudinary upload FAILED");
        return null;
      }

      print("✅ Uploaded URL: ${data["secure_url"]}");
      return data["secure_url"];
    } catch (e) {
      print("❌ Cloudinary Exception: $e");
      return null;
    }
  }

  // ----------------------------------------------------------
  // CREATE USER IN FIRESTORE
  // ----------------------------------------------------------
  Future<void> createUserRecord({
    required String uid,
    required String name,
    required String email,
    required String? photoUrl,
  }) async {
    await _firestore.collection("users").doc(uid).set({
      "uid": uid,
      "name": name,
      "email": email,
      "photoUrl": photoUrl ?? "",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  // ----------------------------------------------------------
  // SIGNUP
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
    }
  }

  // ----------------------------------------------------------
  // LOGIN
  // ----------------------------------------------------------
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
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
    }
  }

  // ----------------------------------------------------------
  // UPDATE NAME
  // ----------------------------------------------------------
  Future<String?> updateName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) return "No logged-in user";

    try {
      // Update Firebase Authentication profile
      await user.updateDisplayName(newName);

      // Update Firestore user profile
      await _firestore.collection("users").doc(user.uid).update({
        "name": newName,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      // Reload cached user
      await user.reload();
      firebaseUser.value = _auth.currentUser;

      return null;
    } catch (e) {
      print("❌ updateName error: $e");
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

      await _firestore.collection("users").doc(user.uid).update({
        "photoUrl": url,
      });

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
