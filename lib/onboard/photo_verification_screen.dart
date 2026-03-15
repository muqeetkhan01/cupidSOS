import 'dart:io';

import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/match_loading_screen.dart';
import 'package:cupid_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

class PhotoVerificationScreen extends StatefulWidget {
  const PhotoVerificationScreen({super.key});

  @override
  State<PhotoVerificationScreen> createState() =>
      _PhotoVerificationScreenState();
}

class _PhotoVerificationScreenState extends State<PhotoVerificationScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();
  late final AnimationController _controller;

  final ImagePicker _picker = ImagePicker();

  File? selfie;
  String? uploadedUrl;

  bool _uploading = false;

  bool get isValid =>
      selfie != null || (uploadedUrl != null && uploadedUrl!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    uploadedUrl = flow.verificationPhotoUrl.value;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, double from, double to) {
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 28),
          child: child,
        ),
      ),
    );
  }

  Future<void> _takeSelfie() async {
    final picked =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      selfie = File(picked.path);
      uploadedUrl = null;
    });
  }

  Future<void> _uploadAndFinish() async {
    if (!isValid || _uploading) return;

    setState(() => _uploading = true);

    var url = uploadedUrl;
    final f = selfie;
    if (f != null) {
      url = await AuthService.to.uploadProfileImage(f);
      if (url == null || url.isEmpty) {
        setState(() => _uploading = false);
        Get.snackbar(
            "Upload failed", "Could not upload your verification photo.");
        return;
      }
    }

    flow.verificationPhotoUrl.value = url;
    flow.photoVerified.value = true;

    await flow.saveOnboardingProgress();

    if (!mounted) return;
    setState(() => _uploading = false);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MatchLoadingScreen()),
    );
  }

  Widget _previewCard() {
    final imageWidget = selfie != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.file(
              selfie!,
              width: double.infinity,
              height: 32.h,
              fit: BoxFit.cover,
            ),
          )
        : (uploadedUrl != null && uploadedUrl!.isNotEmpty)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  uploadedUrl!,
                  width: double.infinity,
                  height: 32.h,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: double.infinity,
                height: 32.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.camera_alt_outlined,
                        size: 42, color: Colors.grey),
                    SizedBox(height: 10),
                    TextWidget(
                        text: "Take a selfie to verify",
                        size: 15,
                        color: Colors.grey),
                  ],
                ),
              );

    return imageWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 1.h),
              _animated(
                SizedBox(
                  height: 7.h,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 62.w,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: 10 / 11,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFFFD6DE),
                                valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFFF3B7A)),
                              ),
                            ),
                          ),
                          SizedBox(height: 0.8.h),
                          const TextWidget(
                              text: '11 of 11', size: 12, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
                0,
                0.15,
              ),
              SizedBox(height: 3.h),
              _animated(
                TextWidget(
                  text: 'Photo Verification',
                  size: 18.sp,
                  weight: FontWeight.w600,
                ),
                0.15,
                0.3,
              ),
              SizedBox(height: 0.8.h),
              _animated(
                const TextWidget(
                  text:
                      "This is the final step. You must complete it to finish onboarding.",
                  size: 15,
                  color: Colors.grey,
                ),
                0.2,
                0.35,
              ),
              SizedBox(height: 3.h),
              _animated(_previewCard(), 0.3, 0.65),
              SizedBox(height: 2.h),
              _animated(
                Row(
                  children: [
                    Expanded(
                      child: ButtonWidget(
                        text: 'Take Selfie',
                        height: 6.6,
                        radius: 36,
                        variant: ButtonVariant.solid,
                        backgroundColor: Colors.white,
                        borderColor: Colors.grey.shade300,
                        textColor: Colors.black,
                        onTap: _takeSelfie,
                      ),
                    ),
                  ],
                ),
                0.45,
                0.75,
              ),
              const Spacer(),
              _animated(
                ButtonWidget(
                  text: _uploading ? 'Uploading…' : 'Finish',
                  height: 7,
                  radius: 36,
                  variant:
                      isValid ? ButtonVariant.gradient : ButtonVariant.solid,
                  gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                  backgroundColor: Colors.grey.shade300,
                  enableShadow: isValid,
                  onTap: isValid ? _uploadAndFinish : () {},
                ),
                0.75,
                1,
              ),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }
}
