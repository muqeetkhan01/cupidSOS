import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/video_call/join.dart' show token;
import 'package:cupid_app/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:videosdk/videosdk.dart';

class AudioRoomScreen extends StatefulWidget {
  const AudioRoomScreen({
    super.key,
    required this.meetingId,
    required this.title,
    required this.displayName,
    required this.startAsSpeaker,
    this.onRaiseHand,
  });

  final String meetingId;
  final String title;
  final String displayName;
  final bool startAsSpeaker;
  final Future<void> Function()? onRaiseHand;

  @override
  State<AudioRoomScreen> createState() => _AudioRoomScreenState();
}

class _AudioRoomScreenState extends State<AudioRoomScreen> {
  Room? _room;
  final Map<String, Participant> _participants = {};
  bool _joining = true;
  bool _micEnabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      if (mounted) {
        setState(() {
          _joining = false;
          _error = 'Microphone permission is required for live audio rooms.';
        });
      }
      return;
    }

    try {
      final room = VideoSDK.createRoom(
        roomId: widget.meetingId,
        token: token,
        displayName: widget.displayName,
        micEnabled: widget.startAsSpeaker,
        camEnabled: false,
        defaultCameraIndex: 0,
      );
      _room = room;
      _micEnabled = widget.startAsSpeaker;
      room.on(Events.roomJoined, () {
        if (!mounted) return;
        setState(() {
          _participants[room.localParticipant.id] = room.localParticipant;
          _joining = false;
        });
      });
      room.on(Events.participantJoined, (Participant participant) {
        if (mounted) {
          setState(() => _participants[participant.id] = participant);
        }
      });
      room.on(Events.participantLeft, (String id, _) {
        if (mounted) setState(() => _participants.remove(id));
      });
      room.on(Events.roomLeft, () {
        if (mounted) Navigator.of(context).maybePop();
      });
      room.join();
    } catch (error) {
      if (mounted) {
        setState(() {
          _joining = false;
          _error = 'Could not join this room. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _room?.leave();
    super.dispose();
  }

  void _toggleMic() {
    final room = _room;
    if (room == null) return;
    if (_micEnabled) {
      room.muteMic();
    } else {
      room.unmuteMic();
    }
    setState(() => _micEnabled = !_micEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      appBar: AppBar(
        title: TextWidget(
          text: widget.title,
          size: 17,
          weight: FontWeight.w700,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.5.h),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7C8A), Color(0xFFD86BCF)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.graphic_eq_rounded,
                        color: Colors.white, size: 34),
                    const SizedBox(height: 8),
                    TextWidget(
                      text:
                          _joining ? 'Connecting live audio…' : 'Room is live',
                      size: 16,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    TextWidget(
                      text:
                          '${_participants.length} ${_participants.length == 1 ? 'person' : 'people'} in the room',
                      size: 12.5,
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.5.h),
              if (_error != null)
                Expanded(
                  child: Center(
                    child: TextWidget(
                      text: _error!,
                      size: 14,
                      color: CupidColors.textSecondary(context),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (_joining)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _participants.length,
                    itemBuilder: (_, index) {
                      final participant = _participants.values.elementAt(index);
                      final name = participant.displayName.trim().isEmpty
                          ? 'Cupid member'
                          : participant.displayName.trim();
                      return Column(
                        children: [
                          Container(
                            width: 18.w,
                            height: 18.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: CupidColors.surfaceMuted(context),
                              border: Border.all(
                                color: const Color(0xFFFF6F7D),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: TextWidget(
                                text: name.characters.first.toUpperCase(),
                                size: 20,
                                weight: FontWeight.w800,
                                color: const Color(0xFFFF6F7D),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          TextWidget(
                            text: name,
                            size: 11.5,
                            weight: FontWeight.w600,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: CupidColors.surfaceMuted(context),
                        foregroundColor: CupidColors.textPrimary(context),
                      ),
                      onPressed: _room == null
                          ? null
                          : widget.startAsSpeaker
                              ? _toggleMic
                              : () async {
                                  await widget.onRaiseHand?.call();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Hand raised. A moderator can invite you to speak.',
                                      ),
                                    ),
                                  );
                                },
                      icon: Icon(
                        widget.startAsSpeaker
                            ? (_micEnabled ? Icons.mic : Icons.mic_off)
                            : Icons.back_hand_rounded,
                      ),
                      label: Text(
                        widget.startAsSpeaker
                            ? (_micEnabled ? 'Mute' : 'Unmute')
                            : 'Raise hand',
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: const Color(0xFFFF5C70),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Leave quietly'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
