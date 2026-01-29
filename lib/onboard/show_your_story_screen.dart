import 'dart:io';
import 'package:cupid_app/onboard/match_loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';

class ShowYourStoryScreen extends StatefulWidget {
  const ShowYourStoryScreen({super.key});

  @override
  State<ShowYourStoryScreen> createState() => _ShowYourStoryScreenState();
}

class _ShowYourStoryScreenState extends State<ShowYourStoryScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  final ImagePicker _picker = ImagePicker();

  /// 6 slots max
  final List<File?> photos = List.generate(6, (_) => null);

  int get uploadedCount => photos.where((e) => e != null).length;
  bool get isValid => uploadedCount >= 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(const Duration(milliseconds: 120), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🔥 Entrance animation (same as other screens)
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

  Future<void> _pickImage(int index) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        photos[index] = File(picked.path);
      });
    }
  }

  Widget _photoTile({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final file = photos[index];

    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            height: index == 0 ? 32.h : 15.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              image: file != null
                  ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                  : null,
              color: file == null ? const Color(0xFFF7F7F7) : null,
              border: file == null
                  ? Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    )
                  : null,
            ),
            child: file == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 30, color: Colors.grey),
                        SizedBox(height: 1.h),
                        TextWidget(text: label, size: 13, color: Colors.grey),
                      ],
                    ),
                  )
                : Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.all(2.w),
                      child: Row(
                        children: [
                          Icon(icon, size: 16, color: Colors.white),
                          SizedBox(width: 1.w),
                          TextWidget(
                            text: label,
                            size: 13,
                            color: Colors.white,
                            weight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          /// ✅ CHECK BADGE
          if (file != null)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 1.5.h),

              /// HEADER
              _animated(
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const TextWidget(
                      text: 'Step 10 of 10',
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
                0,
                0.15,
              ),

              SizedBox(height: 2.h),

              _animated(
                Column(
                  children: [
                    Center(
                      child: TextWidget(
                        text:
                            'Choose or take a photo\nLet yor vibe shine\nAuthentic looks good on you!',
                        size: 18,
                        textAlign: TextAlign.center,
                        weight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 7),
                    TextWidget(
                      text: 'Add photos that tell your cultural journey',
                      size: 15,
                      color: Colors.grey,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                0.15,
                0.3,
              ),

              SizedBox(height: 2.h),

              /// COUNTER CHIP
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF3D8), Color(0xFFFFE8C2)],
                    ),
                  ),
                  child: TextWidget(
                    text: '$uploadedCount/6 photos • At least 1 required',
                    size: 14,
                    color: const Color(0xFF8A5A2B),
                    weight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: 3.h),

              /// PHOTO GRID
              _animated(
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _photoTile(
                            index: 0,
                            label: 'Hero Shot',
                            icon: Icons.camera_alt,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            children: [
                              _photoTile(
                                index: 1,
                                label: 'Your Hobby',
                                icon: Icons.sports_esports,
                              ),
                              SizedBox(height: 2.h),
                              _photoTile(
                                index: 2,
                                label: 'Heritage',
                                icon: Icons.diversity_3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: _photoTile(
                            index: 3,
                            label: 'Lifestyle',
                            icon: Icons.star,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: _photoTile(
                            index: 4,
                            label: 'Lifestyle',
                            icon: Icons.star,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: _photoTile(
                            index: 5,
                            label: 'Lifestyle',
                            icon: Icons.star,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                0.3,
                0.8,
              ),

              SizedBox(height: 3.h),

              /// VERIFIED BADGE
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF2ECFF), Color(0xFFEDE7FF)],
                  ),
                ),
                child: Row(
                  children: const [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFE0D7FF),
                      child: Text('✌️', style: TextStyle(fontSize: 24)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextWidget(
                        text: 'Get one free flirt signal for getting verified',
                        size: 15,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.h),

              /// CTA
              ButtonWidget(
                text: 'Find My Match 💕',
                height: 7,
                radius: 36,
                variant: isValid ? ButtonVariant.gradient : ButtonVariant.solid,
                gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                backgroundColor: Colors.grey.shade300,
                enableShadow: isValid,
                onTap: isValid
                    ? () {
                        Navigator.push(
                          context,
                          _slideRightToLeft(const MatchLoadingScreen()),
                        );
                      }
                    : () {},
              ),

              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }

  Route _slideRightToLeft(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
