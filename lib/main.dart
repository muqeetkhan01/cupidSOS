import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/config/theme_controller.dart';
import 'package:cupid_app/services/auth_service.dart';
import 'package:cupid_app/services/notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:cupid_app/onboard/cupid_splash_screen.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  tz.initializeTimeZones();
  Get.put(AuthService(), permanent: true);
  Get.put(AppFlowController(), permanent: true);
  final themeController = Get.put(ThemeController(), permanent: true);
  await themeController.load();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    ),
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await _requestNotificationPermission();

  NotificationsServiceLocal().scheduleWelcomeNotification();
  runApp(const CupidApp());
}

class CupidApp extends StatelessWidget {
  const CupidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return Obx(
          () => GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Cupid SOS',
            theme: AppThemes.light,
            darkTheme: AppThemes.dark,
            themeMode: themeController.mode.value,
            home: const CupidSplashScreen(),
          ),
        );
      },
    );
  }
}

Future<void> _requestNotificationPermission() async {
  // For Android 13+ (SDK 33+)
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  // if (Platform.isAndroid) {
  //   await Permission.scheduleExactAlarm.request();
  // }
  // For iOS
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}
