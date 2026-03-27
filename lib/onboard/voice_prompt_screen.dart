// lib/onboard/voice_prompt_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/show_your_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/text_widget.dart';

class VoicePromptItem {
  final String emoji;
  final String title;
  final String question;

  const VoicePromptItem({
    required this.emoji,
    required this.title,
    required this.question,
  });
}

/// ✅ PARTNER-APPROVED PROMPTS
const List<VoicePromptItem> voicePrompts = [
  VoicePromptItem(
    emoji: '🏮',
    title: 'The Worthy Argument',
    question:
        'What is one thing in a relationship that is actually worth fighting for?',
  ),
  VoicePromptItem(
    emoji: '🛠️',
    title: 'Repairing the House',
    question:
        'When things get tough, are you the type to fix it or start over?',
  ),
  VoicePromptItem(
    emoji: '💼',
    title: 'Stress Support',
    question: 'When my dream job gets stressful, I need a partner who...',
  ),
  VoicePromptItem(
    emoji: '💛',
    title: 'The Extra Mile',
    question:
        'To me, the best way to show someone they are worth the effort is...',
  ),
];

class VoicePromptScreen extends StatefulWidget {
  const VoicePromptScreen({super.key});

  @override
  State<VoicePromptScreen> createState() => _VoicePromptScreenState();
}

class _VoicePromptScreenState extends State<VoicePromptScreen>
    with TickerProviderStateMixin {
  final flow = Get.find<AppFlowController>();

  late final AnimationController _pageController;

  int activeIndex = 0;
  VoicePromptItem get current => voicePrompts[activeIndex];

  // Recording
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _elapsedSec = 0;
  static const int _maxSec = 30;
  Timer? _tick;

  // Playback
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  String? _recordedPath;

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _pageController.forward();
    });

    // restore if user comes back
    _recordedPath = flow.voiceNotePath.value;
    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playerState = s);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pageController.dispose();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Widget _animated({
    required Widget child,
    required double from,
    required double to,
  }) {
    final anim = CurvedAnimation(
      parent: _pageController,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 26),
          child: child,
        ),
      ),
    );
  }

  void _goTo(int index) {
    setState(() => activeIndex = index);

    // prompt text is what you want to save into profile (question chosen)
    flow.voicePromptText.value = voicePrompts[index].question;
  }

  Future<bool> _ensureMicPermission() async {
    final mic = await Permission.microphone.request();
    if (mic.isGranted) return true;

    if (mic.isPermanentlyDenied) {
      Get.snackbar(
        "Microphone permission",
        "Enable microphone permission in Settings to record your voice prompt.",
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(4.w),
        mainButton: TextButton(
          onPressed: openAppSettings,
          child: const Text("Open Settings"),
        ),
      );
      return false;
    }

    Get.snackbar(
      "Microphone permission",
      "Microphone permission is required to record a voice prompt.",
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(4.w),
    );
    return false;
  }

  Future<String> _makeOutputPath() async {
    final dir = Directory.systemTemp;
    final ts = DateTime.now().millisecondsSinceEpoch;
    return "${dir.path}/voice_prompt_$ts.m4a";
  }

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      setState(() => _elapsedSec++);

      if (_elapsedSec >= _maxSec) {
        await _stopRecording();
      }
    });
  }

  Future<void> _startRecording() async {
    final ok = await _ensureMicPermission();
    if (!ok) return;

    final can = await _recorder.hasPermission();
    if (!can) return;

    // stop playback if playing
    if (_playerState == PlayerState.playing) {
      await _player.stop();
    }

    final path = await _makeOutputPath();

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _elapsedSec = 0;
        _recordedPath = null; // discard old until we stop
      });

      _startTick();
    } catch (e) {
      Get.snackbar(
        "Recording failed",
        "$e",
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(4.w),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _tick?.cancel();

    try {
      final path = await _recorder.stop();
      final finalPath = path?.trim();

      if (finalPath == null ||
          finalPath.isEmpty ||
          !File(finalPath).existsSync()) {
        setState(() => _isRecording = false);
        Get.snackbar(
          "Recording failed",
          "Could not save audio file.",
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(4.w),
        );
        return;
      }

      setState(() {
        _isRecording = false;
        _recordedPath = finalPath;
      });

      // persist to flow + firestore
      flow.voicePromptText.value = current.question;
      flow.voiceNotePath.value = finalPath;
      await flow.saveOnboardingProgress();
    } catch (e) {
      setState(() => _isRecording = false);
      Get.snackbar(
        "Stop failed",
        "$e",
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(4.w),
      );
    }
  }

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _togglePlay() async {
    final path = _recordedPath;
    if (path == null || !File(path).existsSync()) return;

    if (_playerState == PlayerState.playing) {
      await _player.pause();
      return;
    }

    await _player.play(DeviceFileSource(path));
  }

  Future<void> _deleteRecording() async {
    final path = _recordedPath;
    if (path == null) return;

    try {
      if (_playerState == PlayerState.playing) {
        await _player.stop();
      }
      final f = File(path);
      if (f.existsSync()) {
        await f.delete();
      }

      setState(() => _recordedPath = null);

      flow.voiceNotePath.value = null;
      await flow.saveOnboardingProgress();
    } catch (e) {
      Get.snackbar(
        "Delete failed",
        "$e",
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(4.w),
      );
    }
  }

  String _format(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    final hasRecording = _recordedPath != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            children: [
              SizedBox(height: 1.5.h),

              /// HEADER
              _animated(
                from: 0,
                to: 0.15,
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
                    const TextWidget(
                      text: '17 of 19',
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.h),

              /// TITLE
              _animated(
                from: 0.15,
                to: 0.3,
                child: const Column(
                  children: [
                    TextWidget(
                      text: 'Your Voice Prompt 🎙️',
                      size: 20,
                      weight: FontWeight.bold,
                    ),
                    SizedBox(height: 6),
                    TextWidget(
                      text: 'Choose one question and record your voice answer.',
                      size: 15,
                      color: Color(0xFF1E1E1E),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              /// PROMPT NAV
              _animated(
                from: 0.3,
                to: 0.4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    voicePrompts.length,
                    (i) => GestureDetector(
                      onTap: () => _goTo(i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == activeIndex
                              ? const Color(0xFFFFECEF)
                              : Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          voicePrompts[i].emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 3.h),

              /// PROMPT CARD
              _animated(
                from: 0.4,
                to: 0.6,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: '${current.emoji} ${current.title}',
                        size: 16,
                        weight: FontWeight.w600,
                      ),
                      SizedBox(height: 1.h),
                      TextWidget(
                        text: current.question,
                        size: 15,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 3.h),

              /// RECORD SECTION
              _animated(
                from: 0.6,
                to: 0.85,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      TextWidget(
                        text: "${_format(_elapsedSec)} / ${_format(_maxSec)}",
                        size: 14,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 1.h),
                      TextWidget(
                        text: _isRecording
                            ? "Recording... tap to stop"
                            : hasRecording
                                ? "Recorded. Tap play to preview"
                                : "Tap to start recording",
                        size: 14,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 2.5.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          /// Record button
                          GestureDetector(
                            onTap: _toggleRecord,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 20.w,
                              height: 20.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _isRecording
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFFF4D6D),
                                          Color(0xFFFF4D6D)
                                        ],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFFFF6F7D),
                                          Color(0xFFD86BCF)
                                        ],
                                      ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6F7D)
                                        .withOpacity(0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop_rounded : Icons.mic,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),

                          if (hasRecording) SizedBox(width: 5.w),

                          /// Play/pause + delete (only if recording exists)
                          if (hasRecording) ...[
                            GestureDetector(
                              onTap: _togglePlay,
                              child: Container(
                                width: 14.w,
                                height: 14.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade100,
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Icon(
                                  _playerState == PlayerState.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: const Color(0xFFD86BCF),
                                  size: 30,
                                ),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            GestureDetector(
                              onTap: _deleteRecording,
                              child: Container(
                                width: 14.w,
                                height: 14.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade100,
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFFF4D6D),
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 4.h),

              /// NEXT
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () async {
                      if (_isRecording) {
                        await _stopRecording();
                      }

                      if (_recordedPath == null) {
                        Get.snackbar(
                          "Record required",
                          "Please record a 30s voice prompt before continuing.",
                          snackPosition: SnackPosition.BOTTOM,
                          margin: EdgeInsets.all(4.w),
                        );
                        return;
                      }

                      flow.voicePromptText.value = current.question;
                      flow.voiceNotePath.value = _recordedPath;
                      await flow.saveOnboardingProgress();

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShowYourStoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }
}
