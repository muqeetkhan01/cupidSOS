class CompatibilityQuestion {
  const CompatibilityQuestion({
    required this.id,
    required this.prompt,
    required this.weight,
  });

  final String id;
  final String prompt;
  final int weight;
}

class CompatibilityService {
  CompatibilityService._();

  static final CompatibilityService instance = CompatibilityService._();

  List<CompatibilityQuestion> get questions => const <CompatibilityQuestion>[
        CompatibilityQuestion(
          id: 'love_language_words',
          prompt: 'Words of affirmation are important to me in a relationship.',
          weight: 7,
        ),
        CompatibilityQuestion(
          id: 'love_language_time',
          prompt: 'Quality time matters more to me than expensive gifts.',
          weight: 7,
        ),
        CompatibilityQuestion(
          id: 'family_involved',
          prompt:
              'I want my family to stay involved in my relationship journey.',
          weight: 8,
        ),
        CompatibilityQuestion(
          id: 'marriage_goal',
          prompt: 'I am dating with long-term commitment or marriage in mind.',
          weight: 9,
        ),
        CompatibilityQuestion(
          id: 'same_culture',
          prompt: 'Sharing cultural traditions is very important to me.',
          weight: 8,
        ),
        CompatibilityQuestion(
          id: 'faith_values',
          prompt:
              'Shared faith or spiritual values matter in my partner choice.',
          weight: 8,
        ),
        CompatibilityQuestion(
          id: 'communication_direct',
          prompt: 'I prefer direct and clear communication over hints.',
          weight: 6,
        ),
        CompatibilityQuestion(
          id: 'conflict_calm',
          prompt: 'I value calm conflict resolution over emotional arguments.',
          weight: 6,
        ),
        CompatibilityQuestion(
          id: 'career_balance',
          prompt:
              'Career ambition and personal relationship should stay balanced.',
          weight: 6,
        ),
        CompatibilityQuestion(
          id: 'children_preference',
          prompt: 'I want alignment on future plans about children.',
          weight: 7,
        ),
        CompatibilityQuestion(
          id: 'financial_transparency',
          prompt: 'Financial transparency is important for trust.',
          weight: 5,
        ),
        CompatibilityQuestion(
          id: 'social_boundaries',
          prompt:
              'Healthy boundaries with exes and friends are important to me.',
          weight: 5,
        ),
        CompatibilityQuestion(
          id: 'lifestyle_health',
          prompt: 'I prefer a healthy lifestyle and similar daily habits.',
          weight: 4,
        ),
        CompatibilityQuestion(
          id: 'romance_effort',
          prompt: 'I appreciate intentional romance and emotional effort.',
          weight: 5,
        ),
        CompatibilityQuestion(
          id: 'growth_mindset',
          prompt: 'I want a partner who is committed to personal growth.',
          weight: 9,
        ),
      ];

  int scoreFromAnswers(Map<String, int> answers) {
    final q = questions;
    final totalWeight = q.fold<int>(0, (sum, e) => sum + e.weight);
    if (totalWeight == 0) return 0;

    int weightedScore = 0;
    for (final item in q) {
      final answerValue = answers[item.id] ?? 0;
      final clamped = answerValue.clamp(1, 5);
      weightedScore += clamped * item.weight;
    }

    final maxScore = 5 * totalWeight;
    return ((weightedScore / maxScore) * 100).round().clamp(0, 100);
  }

  String labelForScore(int score) {
    if (score >= 85) return 'Exceptional Match Potential';
    if (score >= 70) return 'Strong Compatibility';
    if (score >= 55) return 'Good Potential';
    if (score >= 40) return 'Mixed Compatibility';
    return 'Needs Deeper Alignment';
  }
}
