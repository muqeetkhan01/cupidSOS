import 'package:flutter/material.dart';

class AppThemes {
  static const Color primary = Color(0xFFFF6F7D);
  static const Color secondary = Color(0xFFD86BCF);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFFDF7F5),
      canvasColor: const Color(0xFFFDF7F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFDF7F5),
        foregroundColor: Color(0xFF18181B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: const Color(0xFFE8E1E6),
      cardColor: Colors.white,
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withOpacity(0.35);
          }
          return const Color(0xFFD9D2D8);
        }),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF18181B)),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0x33FF6F7D),
        selectionHandleColor: primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1D1D21),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6DEE4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6DEE4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: secondary,
      surface: const Color(0xFF181B22),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF101218),
      canvasColor: const Color(0xFF101218),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF101218),
        foregroundColor: Color(0xFFF5F2F6),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: const Color(0xFF2A2F3A),
      cardColor: const Color(0xFF181B22),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF181B22),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return const Color(0xFFCDD2DF);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withOpacity(0.35);
          }
          return const Color(0xFF303543);
        }),
      ),
      iconTheme: const IconThemeData(color: Color(0xFFF5F2F6)),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0x55FF6F7D),
        selectionHandleColor: primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF181B22),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF181B22),
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFFF2EEF3),
        contentTextStyle: const TextStyle(color: Color(0xFF16171C)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF181B22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2D3340)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2D3340)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary),
        ),
      ),
    );
  }
}

class CupidColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffold(BuildContext context) =>
      isDark(context) ? const Color(0xFF101218) : const Color(0xFFFDF7F5);

  static Color scaffoldAlt(BuildContext context) =>
      isDark(context) ? const Color(0xFF141821) : const Color(0xFFF9F1EE);

  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF181B22) : Colors.white;

  static Color surfaceMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF202531) : const Color(0xFFF7F7F7);

  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF2E3340) : const Color(0xFFE8E1E6);

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFF5F2F6) : const Color(0xFF19171C);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFFB7B8C4) : const Color(0xFF6E6B74);

  static Color navBar(BuildContext context) =>
      isDark(context) ? const Color(0xFF171A22) : Colors.white;

  static Color shadow(BuildContext context) => isDark(context)
      ? Colors.black.withOpacity(0.35)
      : Colors.black.withOpacity(0.08);

  static List<Color> pageGradient(BuildContext context) => isDark(context)
      ? const [Color(0xFF101218), Color(0xFF151822), Color(0xFF181726)]
      : const [Color(0xFFFDF7F5), Color(0xFFFBEFF3)];
}
