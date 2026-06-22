import 'package:flutter/services.dart';

enum FortuneCookieType { matchLine, dailyFortune }

class FortuneCookie {
  const FortuneCookie({
    required this.id,
    required this.text,
    required this.type,
  });

  final int id;
  final String text;
  final FortuneCookieType type;

  bool get isDailyFortune => type == FortuneCookieType.dailyFortune;
  bool get isMatchLine => type == FortuneCookieType.matchLine;
}

class FortuneCookieRepository {
  FortuneCookieRepository._();

  static final FortuneCookieRepository instance = FortuneCookieRepository._();

  static const _csvPath = 'assets/data/fortune_cookies.csv';

  List<FortuneCookie>? _cache;

  Future<List<FortuneCookie>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final csv = await rootBundle.loadString(_csvPath);
    final rows = _parseCsv(csv);
    final fortunes = <FortuneCookie>[];

    for (final row in rows.skip(1)) {
      if (row.length < 3) continue;
      final id = int.tryParse(row[0]);
      if (id == null) continue;

      fortunes.add(
        FortuneCookie(
          id: id,
          text: row[1],
          type: row[2] == 'Match_Line'
              ? FortuneCookieType.matchLine
              : FortuneCookieType.dailyFortune,
        ),
      );
    }

    _cache = fortunes;
    return fortunes;
  }

  Future<List<FortuneCookie>> dailyFortunes() async {
    final all = await loadAll();
    return all.where((fortune) => fortune.isDailyFortune).toList();
  }

  Future<List<FortuneCookie>> matchLines() async {
    final all = await loadAll();
    return all.where((fortune) => fortune.isMatchLine).toList();
  }

  Future<FortuneCookie> todayDailyFortune([DateTime? now]) async {
    final fortunes = await dailyFortunes();
    final date = now ?? DateTime.now();
    final dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays.clamp(0, 364).toInt();
    return fortunes[dayOfYear % fortunes.length];
  }

  Future<FortuneCookie> matchLineForSeed(String seed) async {
    final lines = await matchLines();
    final index = _stableIndex(seed, lines.length);
    return lines[index];
  }

  int _stableIndex(String seed, int length) {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash % length;
  }

  List<List<String>> _parseCsv(String csv) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < csv.length; i++) {
      final char = csv[i];
      final next = i + 1 < csv.length ? csv[i + 1] : '';

      if (char == '"') {
        if (inQuotes && next == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        row.add(field.toString());
        field.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && next == '\n') i++;
        row.add(field.toString());
        field.clear();
        if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
        row = <String>[];
      } else {
        field.write(char);
      }
    }

    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
    }

    return rows;
  }
}
