import 'package:cupid_app/onboard/onboarding_options.dart';

bool shouldHideProfileValue(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return true;
  return trimmed.toLowerCase() == kPreferNotToSay.toLowerCase();
}

String visibleProfileValue(String? value) {
  return shouldHideProfileValue(value) ? '' : value!.trim();
}

List<String> visibleProfileValues(Iterable<String> values) {
  return values
      .map((value) => visibleProfileValue(value))
      .where((value) => value.isNotEmpty)
      .toList();
}

String simplifyLocationLabel(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return '';

  final parts = trimmed
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first;

  final country = parts.last;
  final city = parts.firstWhere(
    (part) => !_looksLikeStreetAddress(part),
    orElse: () => parts.first,
  );

  if (city.toLowerCase() == country.toLowerCase()) {
    return country;
  }

  return '$city, $country';
}

bool _looksLikeStreetAddress(String value) {
  final normalized = value.toLowerCase();
  if (normalized.split('').any((char) => int.tryParse(char) != null)) {
    return true;
  }

  const streetKeywords = <String>[
    'street',
    'road',
    'avenue',
    'boulevard',
    'lane',
    'drive',
    'apartment',
    'suite',
    'unit',
    'floor',
    'block',
  ];

  return streetKeywords.any(
    (keyword) => normalized == keyword || normalized.contains('$keyword '),
  );
}
