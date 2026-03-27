import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  final Rx<ThemeMode> mode = ThemeMode.system.obs;

  bool get isDarkMode {
    if (mode.value == ThemeMode.dark) return true;
    if (mode.value == ThemeMode.light) return false;
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  Future<void> load() async {}

  Future<void> setMode(ThemeMode next) async {
    mode.value = next;
    Get.changeThemeMode(next);
  }

  Future<void> toggleDark(bool enabled) async {
    await setMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}
