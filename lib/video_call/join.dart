import 'dart:convert';

import 'package:http/http.dart' as http;

const String token =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiIwMzU5MjI0ZC0xZTIwLTQyZDMtOWExZC1kYWQ2NzVjMTQwNmIiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIl0sImlhdCI6MTc1OTA5NDk5OSwiZXhwIjoxNzkwNjMwOTk5fQ.6T1MxCWOSAHAK2l8fs3Z6Uun76VqENwj8bmIJ24C9Qk";
Future<String> createMeeting() async {
  final res = await http.post(
    Uri.parse("https://api.videosdk.live/v2/rooms"),
    headers: {
      "Authorization": token,
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode == 200 || res.statusCode == 201) {
    final data = json.decode(res.body);
    return data["roomId"]; // return meetingId
  } else {
    throw Exception("Failed to create meeting: ${res.body}");
  }
}
