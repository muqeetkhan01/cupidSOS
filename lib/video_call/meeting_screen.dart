// meeting_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:permission_handler/permission_handler.dart';

class MeetingScreen extends StatefulWidget {
  final String meetingId;
  final String token;
  const MeetingScreen(
      {super.key, required this.meetingId, required this.token});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  late Room _room;
  Map<String, Participant> participants = {};
  bool micEnabled = true;
  bool camEnabled = true;

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  Future<void> _initRoom() async {
    // 🔑 Request camera & mic permissions before joining
    await Permission.camera.request();
    await Permission.microphone.request();

    _room = VideoSDK.createRoom(
      roomId: widget.meetingId,
      token: widget.token,
      displayName: "User",
      micEnabled: micEnabled,
      camEnabled: true,
      defaultCameraIndex: 0, // 👈 always safe
    );

    _setMeetingListeners();
    _room.join();
  }

  void _setMeetingListeners() {
    _room.on(Events.roomJoined, () {
      setState(() {
        participants[_room.localParticipant.id] = _room.localParticipant;
      });
    });

    _room.on(Events.participantJoined, (p) {
      setState(() => participants[p.id] = p);
    });

    _room.on(Events.participantLeft, (id, _) {
      setState(() => participants.remove(id));
    });

    _room.on(Events.roomLeft, () {
      participants.clear();
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _room.leave();
    // _room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Meeting ${widget.meetingId}")),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children:
                  participants.values.map((p) => _ParticipantTile(p)).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  micEnabled ? _room.muteMic() : _room.unmuteMic();
                  setState(() => micEnabled = !micEnabled);
                },
                child: Text(micEnabled ? "Mute" : "Unmute"),
              ),
              ElevatedButton(
                onPressed: () {
                  camEnabled ? _room.disableCam() : _room.enableCam();
                  setState(() => camEnabled = !camEnabled);
                },
                child: Text(camEnabled ? "Camera Off" : "Camera On"),
              ),
              ElevatedButton(
                onPressed: () => _room.leave(),
                child: const Text("Leave"),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatefulWidget {
  final Participant participant;
  const _ParticipantTile(this.participant);

  @override
  State<_ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<_ParticipantTile> {
  Stream? videoStream;

  @override
  void initState() {
    super.initState();

    // Get existing video stream if available
    widget.participant.streams.forEach((_, st) {
      if (st.kind == 'video' && st.renderer != null) {
        videoStream = st;
      }
    });

    // Listen for new streams
    widget.participant.on(Events.streamEnabled, (st) {
      if (st.kind == 'video' && st.renderer != null) {
        setState(() => videoStream = st);
      }
    });

    // Listen for stream removal
    widget.participant.on(Events.streamDisabled, (st) {
      if (st.kind == 'video') {
        setState(() => videoStream = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: videoStream != null && videoStream?.renderer != null
          ? RTCVideoView(
              videoStream?.renderer as RTCVideoRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          : const Center(
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
    );
  }
}
