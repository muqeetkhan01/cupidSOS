import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  CloudinaryService._internal();
  static CloudinaryService get to => _instance;

  // Compress before upload
  Future<File> _compressImage(File file) async {
    // OPTIONAL: Add flutter_image_compress if needed
    return file;
  }

  // Upload image to Cloudinary (with full debugging)
  Future<String?> uploadImage(File file, {bool retry = true}) async {
    try {
      final compressed = await _compressImage(file);

      final url = Uri.parse(
          "https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/upload");

      final req = http.MultipartRequest("POST", url)
        ..fields["upload_preset"] = CloudinaryConfig.uploadPreset
        ..fields["resource_type"] = "image"
        ..files.add(await http.MultipartFile.fromPath("file", compressed.path));

      final res = await req.send();
      final body = await res.stream.bytesToString();
      final data = jsonDecode(body);

      print("📤 CLOUDINARY RESPONSE → $data");

      // If Cloudinary rejected the upload
      if (data["error"] != null) {
        print("❌ CLOUDINARY ERROR → ${data['error']['message']}");

        // Auto retry once
        if (retry) {
          print("🔁 Retrying upload once...");
          return uploadImage(file, retry: false);
        }

        return null;
      }

      return data["secure_url"];
    } catch (e) {
      print("🔥 CLOUDINARY EXCEPTION → $e");
      return null;
    }
  }
}
