// lib/screens/profile/edit_profile_screen.dart
import 'dart:io';

import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/text_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final flow = Get.find<AppFlowController>();
  final picker = ImagePicker();

  final nameCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final ethnicityCtrl = TextEditingController();
  final datingGoalCtrl = TextEditingController();
  final sexualityCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  final quirkCtrl = TextEditingController();
  final storyCtrl = TextEditingController();
  final voiceCtrl = TextEditingController();

  double? heightCm;

  bool saving = false;

  /// Story photos editor
  late List<String> storyPhotoUrls; // existing URLs
  final List<File?> pickedStoryFiles = List.generate(6, (_) => null);

  File? pickedProfilePhoto;

  @override
  void initState() {
    super.initState();
    _loadFromController();
  }

  void _loadFromController() {
    final user = AuthService.to.currentUser;

    nameCtrl.text = (flow.displayName.value ?? user?.displayName ?? "").trim();
    genderCtrl.text = (flow.gender.value ?? "").trim();

    ethnicityCtrl.text = (flow.ethnicity.value ?? "").trim();
    datingGoalCtrl.text = (flow.datingGoal.value ?? "").trim();
    sexualityCtrl.text = (flow.sexuality.value ?? "").trim();

    locationCtrl.text = (flow.locationLabel.value ?? "").trim();

    quirkCtrl.text = (flow.quirkText.value ?? "").trim();
    storyCtrl.text = (flow.storyText.value ?? "").trim();
    voiceCtrl.text = (flow.voicePromptText.value ?? "").trim();

    heightCm = flow.heightCm.value;

    storyPhotoUrls = flow.storyPhotoUrls.toList();
    if (storyPhotoUrls.length > 6) {
      storyPhotoUrls = storyPhotoUrls.take(6).toList();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    genderCtrl.dispose();
    ethnicityCtrl.dispose();
    datingGoalCtrl.dispose();
    sexualityCtrl.dispose();
    locationCtrl.dispose();
    quirkCtrl.dispose();
    storyCtrl.dispose();
    voiceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() => pickedProfilePhoto = File(x.path));
  }

  Future<void> _pickStoryPhoto(int index) async {
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() => pickedStoryFiles[index] = File(x.path));
  }

  ImageProvider? _storyImageProvider(int index) {
    final f = pickedStoryFiles[index];
    if (f != null) return FileImage(f);
    if (index < storyPhotoUrls.length) {
      final u = storyPhotoUrls[index];
      if (u.trim().isNotEmpty) return NetworkImage(u);
    }
    return null;
  }

  Future<void> _save() async {
    if (saving) return;

    setState(() => saving = true);

    try {
      // 1) Upload profile photo (Cloudinary via AuthService.uploadProfileImage() inside updateProfilePhoto)
      if (pickedProfilePhoto != null) {
        final err =
            await AuthService.to.updateProfilePhoto(pickedProfilePhoto!);
        if (err != null) {
          throw Exception(err);
        }
      }

      // 2) Upload picked story photos using AuthService.uploadProfileImage()
      // Replace in-place slots, and persist compact list.
      final mergedSlots = List<String?>.generate(6, (i) {
        if (i < storyPhotoUrls.length) return storyPhotoUrls[i];
        return null;
      });

      for (int i = 0; i < pickedStoryFiles.length; i++) {
        final f = pickedStoryFiles[i];
        if (f == null) continue;

        final url = await AuthService.to.uploadProfileImage(f);
        if (url == null || url.isEmpty) {
          throw Exception("Failed to upload a story photo");
        }
        mergedSlots[i] = url;
        pickedStoryFiles[i] = null;
      }

      final compactStoryUrls = mergedSlots
          .where((u) => u != null && u.trim().isNotEmpty)
          .map((u) => u!.trim())
          .toList();

      // 3) Write values into controller
      final newName = nameCtrl.text.trim();
      final newGender = genderCtrl.text.trim();

      flow.displayName.value = newName;
      flow.gender.value = newGender;

      flow.ethnicity.value = ethnicityCtrl.text.trim();
      flow.datingGoal.value = datingGoalCtrl.text.trim();
      flow.sexuality.value = sexualityCtrl.text.trim();

      flow.locationLabel.value = locationCtrl.text.trim();

      flow.quirkText.value = quirkCtrl.text.trim();
      flow.storyText.value = storyCtrl.text.trim();
      flow.voicePromptText.value = voiceCtrl.text.trim();

      if (heightCm != null) {
        flow.heightCm.value = heightCm;
      }

      flow.storyPhotoUrls.assignAll(compactStoryUrls);

      // 4) Persist to Firestore
      await flow.saveOnboardingProgress();

      // 5) Ensure Firebase displayName stays in sync
      if (newName.isNotEmpty) {
        await AuthService.to.updateName(newName);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Get.snackbar("Save failed", e.toString());
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.to.currentUser;
    final currentPhoto = (user?.photoURL ?? "").trim();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F5),
        elevation: 0,
        title: const TextWidget(
            text: "Edit Profile", size: 18, weight: FontWeight.w700),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: saving ? null : () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: TextWidget(
              text: saving ? "Saving..." : "Save",
              size: 15,
              color: const Color(0xFFFF6F7D),
              weight: FontWeight.w700,
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Profile photo"),
              SizedBox(height: 1.2.h),
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: pickedProfilePhoto != null
                            ? FileImage(pickedProfilePhoto!)
                            : (currentPhoto.isNotEmpty
                                ? NetworkImage(currentPhoto)
                                : null) as ImageProvider?,
                        child:
                            (pickedProfilePhoto == null && currentPhoto.isEmpty)
                                ? const Icon(Icons.person,
                                    size: 34, color: Colors.white)
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: saving ? null : _pickProfilePhoto,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF6F7D),
                            ),
                            child: const Icon(Icons.edit,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: TextWidget(
                      text:
                          "Tap the edit icon to change your profile photo.\nUploads to Cloudinary.",
                      size: 13,
                      color: Colors.grey.shade700,
                    ),
                  )
                ],
              ),
              SizedBox(height: 2.5.h),
              _sectionTitle("Basic info"),
              SizedBox(height: 1.2.h),
              TextField(controller: nameCtrl, decoration: _dec("Name")),
              SizedBox(height: 1.2.h),
              TextField(controller: genderCtrl, decoration: _dec("Gender")),
              SizedBox(height: 1.2.h),
              _sliderCard(
                label: "Height (cm)",
                value: heightCm ?? (flow.heightCm.value ?? 173.0),
                min: 140,
                max: 220,
                onChanged: (v) => setState(() => heightCm = v),
              ),
              SizedBox(height: 2.5.h),
              _sectionTitle("Identity"),
              SizedBox(height: 1.2.h),
              TextField(
                  controller: ethnicityCtrl, decoration: _dec("Ethnicity")),
              SizedBox(height: 1.2.h),
              TextField(
                  controller: sexualityCtrl, decoration: _dec("Sexuality")),
              SizedBox(height: 1.2.h),
              TextField(
                  controller: datingGoalCtrl, decoration: _dec("Dating goal")),
              SizedBox(height: 2.5.h),
              _sectionTitle("Location"),
              SizedBox(height: 1.2.h),
              TextField(
                controller: locationCtrl,
                decoration: _dec("Location label (e.g., Karachi, PK)"),
              ),
              SizedBox(height: 0.8.h),
              TextWidget(
                text:
                    "Note: this edits the saved label only. If you want, I can add a 'Pick on map' button here too.",
                size: 12,
                color: Colors.grey.shade600,
              ),
              SizedBox(height: 2.5.h),
              _sectionTitle("Prompts"),
              SizedBox(height: 1.2.h),
              TextField(
                controller: quirkCtrl,
                maxLines: 3,
                decoration: _dec("Cultural quirk"),
              ),
              SizedBox(height: 1.2.h),
              TextField(
                controller: voiceCtrl,
                maxLines: 2,
                decoration: _dec("Voice prompt"),
              ),
              SizedBox(height: 1.2.h),
              TextField(
                controller: storyCtrl,
                maxLines: 4,
                decoration: _dec("Your story"),
              ),
              SizedBox(height: 2.5.h),
              _sectionTitle("Story photos"),
              SizedBox(height: 1.2.h),
              _storyPhotosEditor(),
              SizedBox(height: 3.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F7D),
                    padding: EdgeInsets.symmetric(vertical: 1.7.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: TextWidget(
                    text: saving ? "Saving..." : "Save changes",
                    size: 16,
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return TextWidget(text: text, size: 15, weight: FontWeight.w700);
  }

  Widget _sliderCard({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final v = value.clamp(min, max);
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
              text: "$label: ${v.round()}", size: 14, weight: FontWeight.w700),
          Slider(
            min: min,
            max: max,
            value: v,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _storyPhotosEditor() {
    // 6 slots visual editor, uses existing urls + picked files.
    return Wrap(
      spacing: 3.w,
      runSpacing: 2.h,
      children: List.generate(6, (i) {
        final provider = _storyImageProvider(i);
        final has = provider != null;

        return GestureDetector(
          onTap: saving ? null : () => _pickStoryPhoto(i),
          onLongPress: saving
              ? null
              : () {
                  // remove existing slot url (if any)
                  setState(() {
                    if (i < storyPhotoUrls.length) {
                      storyPhotoUrls.removeAt(i);
                    }
                    pickedStoryFiles[i] = null;
                  });
                },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: (100.w - (5.w * 2) - 3.w) / 2,
              height: 20.h,
              color: Colors.grey.shade200,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: has
                        ? Image(
                            image: provider,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.white,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined),
                                SizedBox(height: 0.8.h),
                                TextWidget(
                                  text: "Add photo",
                                  size: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ],
                            ),
                          ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: TextWidget(
                        text: "Slot ${i + 1}",
                        size: 12,
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  ),
                  if (has)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const TextWidget(
                          text: "Hold to remove",
                          size: 11,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
