import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupid_app/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationsServiceLocal {
  Future<void> saveNotificationToFirestore(
      String uid, String title, String message) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'uid': uid,
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> scheduleWelcomeNotification() async {
    try {
      int notificationId = 1;
      String title = "Welcome to Cupid 💕";
      String message =
          "Start discovering new people, make meaningful matches, and say hi with a quick message.";

      DateTime scheduledTime = DateTime.now().add(const Duration(seconds: 10));

      print("🔔 Scheduling notification for: $scheduledTime");

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        message,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test channel for Cupid',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: Platform.isAndroid
            ? AndroidScheduleMode.inexactAllowWhileIdle
            : AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );

      print("✅ Notification scheduled successfully!");
    } catch (e, stackTrace) {
      print("❌ Error scheduling notification: $e");
      print("📍 StackTrace:\n$stackTrace");
    }
  }
}
