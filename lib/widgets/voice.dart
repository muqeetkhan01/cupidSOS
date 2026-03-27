// lib/widgets/voice_note_player.dart
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:flutter/material.dart';

class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({
    super.key,
    required this.source, // local path or https url
    this.compact = false,
  });

  final String source;
  final bool compact;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final AudioPlayer _player = AudioPlayer();

  PlayerState _state = PlayerState.stopped;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;

  bool get _isPlaying => _state == PlayerState.playing;

  @override
  void initState() {
    super.initState();

    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _state = s);
    });

    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _pos = p);
    });

    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _dur = d);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  bool get _isUrl {
    final s = widget.source.trim();
    return s.startsWith('http://') || s.startsWith('https://');
  }

  bool _exists() {
    final s = widget.source.trim();
    if (s.isEmpty) return false;
    if (_isUrl) return true;
    return File(s).existsSync();
  }

  Future<void> _toggle() async {
    if (!_exists()) return;

    if (_isPlaying) {
      await _player.pause();
      return;
    }

    if (_dur != Duration.zero && _pos >= _dur) {
      await _player.seek(Duration.zero);
    }

    final src = widget.source.trim();
    if (_isUrl) {
      await _player.play(UrlSource(src));
    } else {
      await _player.play(DeviceFileSource(src));
    }
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, "0");
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, "0");
    return "$mm:$ss";
  }

  @override
  Widget build(BuildContext context) {
    final ok = _exists();

    final max = _dur.inMilliseconds == 0 ? 1.0 : _dur.inMilliseconds.toDouble();
    final val = _pos.inMilliseconds.clamp(0, _dur.inMilliseconds).toDouble();

    final button = InkWell(
      onTap: ok ? _toggle : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: widget.compact ? 44 : 52,
        height: widget.compact ? 44 : 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: ok
              ? const LinearGradient(
                  colors: [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                )
              : LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade200],
                ),
        ),
        child: Icon(
          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: widget.compact ? 26 : 30,
        ),
      ),
    );

    if (widget.compact) return button;

    return Row(
      children: [
        button,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFFF6F7D), // primary
                    inactiveTrackColor:
                        const Color(0xFFD86BCF).withOpacity(0.25),
                    thumbColor: const Color(0xFFD86BCF), // secondary
                    overlayColor: const Color(0xFFD86BCF).withOpacity(0.18),
                    trackHeight: 3.5,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: val,
                    min: 0,
                    max: max,
                    onChanged: ok
                        ? (v) => _player.seek(Duration(milliseconds: v.toInt()))
                        : null,
                  )),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(_pos),
                    style: TextStyle(
                      fontSize: 12,
                      color: CupidColors.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _fmt(_dur),
                    style: TextStyle(
                      fontSize: 12,
                      color: CupidColors.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
