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
