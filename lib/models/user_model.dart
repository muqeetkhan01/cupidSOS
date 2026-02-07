import 'package:cloud_firestore/cloud_firestore.dart';


class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return UserModel(
      uid: (map['uid'] ?? "").toString(),
      name: (map['name'] ?? "").toString(),
      email: (map['email'] ?? "").toString(),
      photoUrl: (map['photoUrl'] ?? "").toString(),
      createdAt: toDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: toDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "photoUrl": photoUrl,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }
}