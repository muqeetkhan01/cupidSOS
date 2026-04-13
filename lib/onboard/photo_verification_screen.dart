import 'dart:io';

import 'package:cupid_app/config/app_theme.dart';
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
    flow.finalRulesSeen.value = true;

    await flow.saveOnboardingProgress();

    if (!mounted) return;
    setState(() => _uploading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MatchLoadingScreen(),
      ),
    );
  }

  Widget _previewCard() {
    final imageWidget = selfie != null
        ? _verificationFrame(
            Image.file(
              selfie!,
              width: double.infinity,
              height: 32.h,
              fit: BoxFit.cover,
            ),
          )
        : (uploadedUrl != null && uploadedUrl!.isNotEmpty)
            ? _verificationFrame(
                Image.network(
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF3F6), Color(0xFFF6ECFF)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: CupidColors.border(context)),
                ),
                alignment: Alignment.center,
                child: _placeholderPoseCard(),
              );

    return imageWidget;
  }

  Widget _verificationFrame(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
                width: 3,
              ),
            ),
          ),
          Positioned(
            right: 4.w,
            top: 2.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const TextWidget(
                text: 'Center your face',
                size: 12,
                color: Colors.white,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderPoseCard() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 2.5.h,
          right: 5.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6F7D),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33FF6F7D),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const TextWidget(
              text: '✌️ Example pose',
              size: 12,
              color: Colors.white,
              weight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFFFFF), width: 3),
          ),
        ),
        Container(
          width: 44.w,
          height: 44.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFD6DE), Color(0xFFE8D8FF)],
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.person_rounded,
              size: 74,
              color: Color(0xFF53304B),
            ),
            SizedBox(height: 6),
            Text(
              '✌️',
              style: TextStyle(fontSize: 26),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: SingleChildScrollView(
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
                                  value: 1,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFFFD6DE),
                                  valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFFFF3B7A)),
                                ),
                              ),
                            ),
                            SizedBox(height: 0.8.h),
                            const TextWidget(
                                text: '19 of 19', size: 12, color: null),
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
                        "It won't be shown on your profile. It's just for our team to verify it's really you.",
                    size: 15,
                    color: null,
                  ),
                  0.2,
                  0.35,
                ),
                SizedBox(height: 1.6.h),
                _animated(
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F7),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFFE0E7)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 11.w,
                          height: 11.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE7EE),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '✌️',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: TextWidget(
                            text:
                                'Match the example pose and place your face inside the circle so our team can verify it is really you.',
                            size: 14,
                            color: CupidColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  0.25,
                  0.5,
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
                          backgroundColor: CupidColors.surface(context),
                          borderColor: CupidColors.border(context),
                          textColor: CupidColors.textPrimary(context),
                          onTap: _takeSelfie,
                        ),
                      ),
                    ],
                  ),
                  0.45,
                  0.75,
                ),
                SizedBox(height: 2.h),
                // const Spacer(),
                _animated(
                  ButtonWidget(
                    text: _uploading ? 'Uploading…' : 'Finish',
                    height: 7,
                    radius: 36,
                    variant:
                        isValid ? ButtonVariant.gradient : ButtonVariant.solid,
                    gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                    backgroundColor: CupidColors.border(context),
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
      ),
    );
  }
}
