import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/vibe_check_screen.dart';
import 'package:cupid_app/services/compatibility_service.dart';
import 'package:cupid_app/widgets/button_widget.dart';
import 'package:cupid_app/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class CompatibilityQuizScreen extends StatefulWidget {
  const CompatibilityQuizScreen({super.key});

  @override
  State<CompatibilityQuizScreen> createState() =>
      _CompatibilityQuizScreenState();
}

class _CompatibilityQuizScreenState extends State<CompatibilityQuizScreen> {
  final flow = Get.find<AppFlowController>();
  final compatibility = CompatibilityService.instance;

  int _index = 0;
  late final Map<String, int> _answers;

  @override
  void initState() {
    super.initState();
    _answers = Map<String, int>.from(flow.compatibilityAnswers);
  }

  List<CompatibilityQuestion> get _questions => compatibility.questions;

  double get _progress => (_index + 1) / _questions.length;

  bool get _isLast => _index == _questions.length - 1;

  int? _currentAnswer(String id) => _answers[id];

  String _scaleLabel(int value) {
    switch (value) {
      case 1:
        return 'Strongly Disagree';
      case 2:
        return 'Disagree';
      case 3:
        return 'Neutral';
      case 4:
        return 'Agree';
      case 5:
        return 'Strongly Agree';
      default:
        return '';
    }
  }

  Future<void> _next() async {
    final q = _questions[_index];
    if ((_answers[q.id] ?? 0) == 0) return;

    if (_isLast) {
      final score = compatibility.scoreFromAnswers(_answers);
      flow.compatibilityAnswers
        ..clear()
        ..addAll(_answers);
      flow.compatibilityScore.value = score;
      flow.compatibilityQuizCompleted.value = true;
      await flow.saveOnboardingProgress();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VibeCheckScreen()),
      );
      return;
    }

    setState(() => _index += 1);
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_index];
    final answer = _currentAnswer(question.id) ?? 0;

    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () {
                      if (_index == 0) {
                        Navigator.pop(context);
                      } else {
                        setState(() => _index -= 1);
                      }
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        TextWidget(
                          text: 'Cupid Match Quiz (${_index + 1}/15)',
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                        SizedBox(height: 0.8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: _progress,
                            backgroundColor: CupidColors.border(context),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF6F7D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
              ),
              SizedBox(height: 4.h),
              const TextWidget(
                text: 'Compatibility Deep Dive',
                size: 22,
                weight: FontWeight.w800,
              ),
              SizedBox(height: 0.8.h),
              TextWidget(
                text:
                    'Answer honestly to build your cultural and love-language profile.',
                size: 14,
                color: CupidColors.textSecondary(context),
              ),
              SizedBox(height: 3.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(5.w),
                decoration: BoxDecoration(
                  color: CupidColors.surface(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: CupidColors.border(context)),
                ),
                child: TextWidget(
                  text: question.prompt,
                  size: 18,
                  weight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.5.h),
              Expanded(
                child: ListView.separated(
                  itemCount: 5,
                  separatorBuilder: (_, __) => SizedBox(height: 1.2.h),
                  itemBuilder: (_, i) {
                    final value = i + 1;
                    final selected = value == answer;
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () =>
                          setState(() => _answers[question.id] = value),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 1.8.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: selected
                              ? const Color(0xFFFFEDF1)
                              : CupidColors.surface(context),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFFF6F7D)
                                : CupidColors.border(context),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: selected
                                  ? const Color(0xFFFF6F7D)
                                  : CupidColors.border(context),
                              child: TextWidget(
                                text: '$value',
                                size: 12,
                                color: selected
                                    ? Colors.white
                                    : CupidColors.textSecondary(context),
                                weight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: TextWidget(
                                text: _scaleLabel(value),
                                size: 14.5,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 1.h),
              ButtonWidget(
                text: _isLast ? 'Finish Quiz' : 'Continue',
                height: 6.6,
                radius: 36,
                variant:
                    answer == 0 ? ButtonVariant.solid : ButtonVariant.gradient,
                backgroundColor: answer == 0
                    ? CupidColors.border(context)
                    : const Color(0xFFFF6F7D),
                gradient: answer == 0
                    ? const [Color(0x00000000), Color(0x00000000)]
                    : const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                onTap: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
