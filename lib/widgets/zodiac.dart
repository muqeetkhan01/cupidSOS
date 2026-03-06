// lib/utils/zodiac.dart
// Small, dependency-free helpers.
class ZodiacUtils {
  static const _western = <_WesternSign>[
    _WesternSign("Capricorn", "♑️", 12, 22, 1, 19),
    _WesternSign("Aquarius", "♒️", 1, 20, 2, 18),
    _WesternSign("Pisces", "♓️", 2, 19, 3, 20),
    _WesternSign("Aries", "♈️", 3, 21, 4, 19),
    _WesternSign("Taurus", "♉️", 4, 20, 5, 20),
    _WesternSign("Gemini", "♊️", 5, 21, 6, 20),
    _WesternSign("Cancer", "♋️", 6, 21, 7, 22),
    _WesternSign("Leo", "♌️", 7, 23, 8, 22),
    _WesternSign("Virgo", "♍️", 8, 23, 9, 22),
    _WesternSign("Libra", "♎️", 9, 23, 10, 22),
    _WesternSign("Scorpio", "♏️", 10, 23, 11, 21),
    _WesternSign("Sagittarius", "♐️", 11, 22, 12, 21),
  ];

  /// Western Zodiac based on month/day.
  static WesternZodiac westernZodiac(DateTime dob) {
    final m = dob.month;
    final d = dob.day;

    for (final s in _western) {
      if (_inRange(m, d, s.startMonth, s.startDay, s.endMonth, s.endDay)) {
        return WesternZodiac(
          name: s.name,
          emoji: s.emoji,
          rangeLabel: _rangeLabel(s),
        );
      }
    }

    // Fallback (should never happen)
    final cap = _western.first;
    return WesternZodiac(
      name: cap.name,
      emoji: cap.emoji,
      rangeLabel: _rangeLabel(cap),
    );
  }

  /// Chinese Zodiac based on year.
  /// Uses 2020 = Rat as reference. Works for any year (positive/negative handled).
  static ChineseZodiac chineseZodiac(DateTime dob) {
    const animals = <String>[
      "Rat",
      "Ox",
      "Tiger",
      "Rabbit",
      "Dragon",
      "Snake",
      "Horse",
      "Goat",
      "Monkey",
      "Rooster",
      "Dog",
      "Pig",
    ];

    const emojis = <String>[
      "🐀",
      "🐂",
      "🐯",
      "🐰",
      "🐲",
      "🐍",
      "🐴",
      "🐐",
      "🐵",
      "🐓",
      "🐶",
      "🐷",
    ];

    final year = dob.year;
    final idx = _mod(year - 2020, 12);

    return ChineseZodiac(
      animal: animals[idx],
      emoji: emojis[idx],
      year: year,
    );
  }

  static bool _inRange(
    int m,
    int d,
    int sm,
    int sd,
    int em,
    int ed,
  ) {
    // Normal range (same year)
    if (sm < em || (sm == em && sd <= ed)) {
      final afterStart = (m > sm) || (m == sm && d >= sd);
      final beforeEnd = (m < em) || (m == em && d <= ed);
      return afterStart && beforeEnd;
    }

    // Wrap range (e.g. Capricorn: Dec -> Jan)
    final afterStart = (m > sm) || (m == sm && d >= sd);
    final beforeEnd = (m < em) || (m == em && d <= ed);
    return afterStart || beforeEnd;
  }

  static int _mod(int x, int m) {
    final r = x % m;
    return r < 0 ? r + m : r;
  }

  static String _rangeLabel(_WesternSign s) =>
      "${_mmdd(s.startMonth, s.startDay)} – ${_mmdd(s.endMonth, s.endDay)}";

  static String _mmdd(int m, int d) {
    const months = <String>[
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return "${months[m]} $d";
  }
}

class WesternZodiac {
  const WesternZodiac({
    required this.name,
    required this.emoji,
    required this.rangeLabel,
  });

  final String name;
  final String emoji;
  final String rangeLabel;
}

class ChineseZodiac {
  const ChineseZodiac({
    required this.animal,
    required this.emoji,
    required this.year,
  });

  final String animal;
  final String emoji;
  final int year;
}

class _WesternSign {
  const _WesternSign(
    this.name,
    this.emoji,
    this.startMonth,
    this.startDay,
    this.endMonth,
    this.endDay,
  );

  final String name;
  final String emoji;
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;
}
